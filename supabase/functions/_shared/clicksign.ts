// Clicksign Envelope API v3: JSON:API and raw Authorization token (no Bearer).
// https://developers.clicksign.com/docs/ambientes-autenticacao-e-formato
export type ClicksignConfig = { environment: 'sandbox' | 'production'; token: string };
export const MAX_PDF = 15 * 1024 * 1024;
export class ProviderError extends Error {
  uncertain: boolean;
  constructor(code: string, uncertain = false) { super(code); this.uncertain = uncertain; }
}
export async function limitedBytes(response: Response, limit: number): Promise<Uint8Array> {
  if (Number(response.headers.get('content-length')) > limit) throw new Error('body_too_large');
  const reader = response.body?.getReader();
  if (!reader) throw new Error('body_missing');
  const chunks: Uint8Array[] = []; let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read(); if (done) break;
      size += value.length;
      if (size > limit) throw new Error('body_too_large');
      chunks.push(value);
    }
  } catch (error) { await reader.cancel(); throw error; }
  const bytes = new Uint8Array(size); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  return bytes;
}
export async function sha256(bytes: Uint8Array): Promise<string> {
  return [...new Uint8Array(await crypto.subtle.digest('SHA-256', new Uint8Array(bytes)))].map(x => x.toString(16).padStart(2, '0')).join('');
}
export function validatePdf(bytes: Uint8Array): void {
  if (bytes.length < 5 || bytes.length > MAX_PDF || new TextDecoder().decode(bytes.slice(0, 5)) !== '%PDF-') throw new Error('invalid_pdf');
}
export function resourceId(value: unknown): string {
  if (typeof value !== 'string' || !/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(value)) throw new ProviderError('invalid_provider_id', true);
  return value;
}
export class Clicksign {
  config: ClicksignConfig;
  constructor(config: ClicksignConfig) { this.config = config; }
  get host(): string { return this.config.environment === 'sandbox' ? 'https://sandbox.clicksign.com' : 'https://app.clicksign.com'; }
  async request(path: string, method = 'GET', data?: unknown): Promise<any> {
    let response: Response;
    try {
      response = await fetch(`${this.host}/api/v3${path}`, {
        method, headers: { Authorization: this.config.token, Accept: 'application/vnd.api+json', 'Content-Type': 'application/vnd.api+json' },
        ...(data === undefined ? {} : { body: JSON.stringify({ data }) }),
        redirect: 'error', signal: AbortSignal.timeout(20000),
      });
    } catch { throw new ProviderError('clicksign_outcome_unknown', method !== 'GET'); }
    if (!response.ok) {
      await response.body?.cancel();
      throw new ProviderError(`clicksign_http_${response.status}`, method !== 'GET' && response.status >= 500);
    }
    if (response.status === 204) return {};
    try { return JSON.parse(new TextDecoder().decode(await limitedBytes(response, 2 * 1024 * 1024))); }
    catch { throw new ProviderError('clicksign_invalid_response', method !== 'GET'); }
  }
  async create(name: string): Promise<string> {
    const result = await this.request('/envelopes', 'POST', { type: 'envelopes', attributes: {
      name, locale: 'pt-BR', auto_close: true, block_after_refusal: true,
      default_subject: 'Agsur - assinatura de contrato',
    } });
    return resourceId(result.data?.id);
  }
  async document(envelope: string, bytes: Uint8Array): Promise<string> {
    validatePdf(bytes); let binary = '';
    for (let i = 0; i < bytes.length; i += 8192) binary += String.fromCharCode(...bytes.subarray(i, i + 8192));
    const result = await this.request(`/envelopes/${resourceId(envelope)}/documents`, 'POST', {
      type: 'documents', attributes: { filename: 'Contrato-Agsur.pdf', content_base64: `data:application/pdf;base64,${btoa(binary)}` },
    });
    return resourceId(result.data?.id);
  }
  async signer(envelope: string, name: string, email: string): Promise<string> {
    const result = await this.request(`/envelopes/${resourceId(envelope)}/signers`, 'POST', {
      type: 'signers', attributes: { name, email, has_documentation: false, refusable: true,
        communicate_events: { signature_request: 'email', signature_reminder: 'email', document_signed: 'email' } },
    });
    return resourceId(result.data?.id);
  }
  async requirements(envelope: string, document: string, signer: string): Promise<void> {
    const relationships = { document: { data: { type: 'documents', id: resourceId(document) } }, signer: { data: { type: 'signers', id: resourceId(signer) } } };
    for (const attributes of [{ action: 'agree', role: 'sign' }, { action: 'provide_evidence', auth: 'email' }]) {
      await this.request(`/envelopes/${resourceId(envelope)}/requirements`, 'POST', { type: 'requirements', attributes, relationships });
    }
  }
  async activate(envelope: string): Promise<void> {
    const id = resourceId(envelope);
    await this.request(`/envelopes/${id}`, 'PATCH', { id, type: 'envelopes', attributes: { status: 'running' } });
  }
  async notify(envelope: string): Promise<void> {
    await this.request(`/envelopes/${resourceId(envelope)}/notifications`, 'POST', {
      type: 'notifications', attributes: { message: 'Confira e assine o contrato da Agsur.' },
    });
  }
  async signedPdf(envelope: string, document: string): Promise<Uint8Array> {
    const id = resourceId(envelope); const doc = resourceId(document);
    // A final webhook triggers this lookup. Never poll the provider on a timer.
    const state = await this.request(`/envelopes/${id}`);
    if (state.data?.id !== id || state.data?.attributes?.status !== 'closed') throw new Error('envelope_not_closed');
    const result = await this.request(`/envelopes/${id}/documents/${doc}`);
    if (result.data?.id !== doc) throw new Error('document_mismatch');
    const signed = result.data?.links?.files?.signed ?? result.data?.attributes?.downloads?.signed_file_url;
    if (typeof signed !== 'string' || !signed) throw new Error('signed_pdf_not_ready');
    const url = new URL(signed, this.host);
    const bucket = this.config.environment === 'sandbox' ? 'clicksign-content-sandbox' : 'clicksign-content';
    const hosts = [new URL(this.host).hostname, `${bucket}.s3.amazonaws.com`, `${bucket}.s3.us-east-1.amazonaws.com`];
    if (url.protocol !== 'https:' || url.username || url.password || (url.port && url.port !== '443') || !hosts.includes(url.hostname)) throw new Error('pdf_host_not_allowed');
    // Presigned file URLs get NO API token, and redirects cannot escape the allowlist.
    const response = await fetch(url, { redirect: 'error', signal: AbortSignal.timeout(20000) });
    if (!response.ok) { await response.body?.cancel(); throw new Error('signed_pdf_download_failed'); }
    const bytes = await limitedBytes(response, MAX_PDF); validatePdf(bytes); return bytes;
  }
}

export function parseClicksignEvent(body: any): { document: string; name: string; at: string; email: string | null } | null {
  const event = body?.event;
  const names = ['sign', 'signature_started', 'refusal', 'auto_close', 'close', 'document_closed', 'cancel', 'deadline'];
  if (!names.includes(event?.name)) return null;
  const document = resourceId(body.document?.key ?? body.document?.id);
  const at = event.occurred_at ?? event.data?.occurred_at ?? body.document?.updated_at;
  if (typeof at !== 'string' || !Number.isFinite(Date.parse(at))) throw new Error('invalid_event_time');
  const email = event.data?.signer?.email;
  if (['sign', 'signature_started', 'refusal'].includes(event.name) && (typeof email !== 'string' || email.length > 254)) throw new Error('invalid_signer');
  return { document, name: event.name, at: new Date(at).toISOString(), email: typeof email === 'string' ? email.toLowerCase() : null };
}
