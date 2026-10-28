import { Clicksign, ProviderError, sha256, validatePdf } from './clicksign.ts';

// Dependencies are injectable so the real workflow is tested without external sends.
export async function processSignature(db: any, provider: Clicksign, job: any): Promise<void> {
  let remote: string | null = null;
  let externalAttempted = false;
  const save = async (name: string, params: any) => {
    const { data, error } = await db.rpc(name, params); if (error) throw new Error('signature_persistence_failed'); return data;
  };
  try {
    const { data: contract, error: contractError } = await db.from('contract').select('cancelled_at').eq('id', job.contract_id).single();
    if (contractError || !contract || contract.cancelled_at) throw new Error('contract_unavailable');
    const { data, error } = await db.storage.from('contract-signatures').download(job.source_path);
    if (error || !data || data.size > 15 * 1024 * 1024) throw new Error('source_pdf_unavailable');
    const bytes = new Uint8Array(await data.arrayBuffer()); validatePdf(bytes);
    if (await sha256(bytes) !== job.source_sha256) throw new Error('source_hash_mismatch');
    if (!Array.isArray(job.signers) || job.signers.length < 1 || job.signers.length > 10) throw new Error('invalid_signers');
    externalAttempted = true;
    remote = await provider.create(`Agsur ${job.id}`);
    await save('signature_checkpoint_clicksign', { p_id: job.id, p_claim: job.worker_claim, p_remote: remote });
    const document = await provider.document(remote, bytes);
    await save('signature_checkpoint_clicksign', { p_id: job.id, p_claim: job.worker_claim, p_remote: remote, p_document: document });
    for (const signer of job.signers) {
      const id = await provider.signer(remote, signer.name, signer.email);
      await provider.requirements(remote, document, id);
    }
    const { data: current, error: currentError } = await db.from('contract').select('cancelled_at').eq('id', job.contract_id).single();
    if (currentError || !current || current.cancelled_at) throw new Error('contract_unavailable');
    await provider.activate(remote);
    await provider.notify(remote);
    await save('signature_finish_clicksign', { p_id: job.id, p_claim: job.worker_claim });
  } catch (error) {
    // Once an envelope exists, partial operations require reconciliation, never a new envelope.
    const uncertain = Boolean(remote) || (externalAttempted && (!(error instanceof ProviderError) || error.uncertain));
    const code = error instanceof ProviderError ? error.message : externalAttempted ? 'signature_outcome_unknown' : error instanceof Error ? error.message : 'signature_failed';
    await save('signature_finish_clicksign', { p_id: job.id, p_claim: job.worker_claim, p_error: code, p_uncertain: uncertain });
  }
}

export async function processSignatureEvent(db: any, provider: Clicksign, event: any): Promise<void> {
  let errorCode: string | null = null;
  try {
    const { data: envelope, error: lookupError } = await db.from('contract_signature_envelopes').select('*').eq('id', event.envelope_id).single();
    if (lookupError || !envelope || envelope.provider_environment !== provider.config.environment) throw new Error('envelope_unavailable');
    const apply = async (path?: string) => {
      const { data, error } = await db.rpc('signature_apply_clicksign', { p_event: event.id, p_claim: event.claim_token, ...(path ? { p_signed_path: path } : {}) });
      if (error) throw new Error('event_persistence_failed'); return data;
    };
    const result = await apply();
    if (result.archive_required) {
      const bytes = await provider.signedPdf(envelope.provider_id, envelope.provider_document_id);
      const path = `${envelope.id}/signed.pdf`;
      const bucket = db.storage.from('contract-signatures');
      const { error } = await bucket.upload(path, bytes, { contentType: 'application/pdf', upsert: false });
      if (error) {
        // Concurrent final callbacks can only reuse an archive with identical bytes.
        const { data: existing, error: downloadError } = await bucket.download(path);
        if (downloadError || !existing || existing.size > 15 * 1024 * 1024 || await sha256(new Uint8Array(await existing.arrayBuffer())) !== await sha256(bytes)) throw new Error('archive_failed');
      }
      await apply(path);
    }
  } catch { errorCode = 'signature_event_retry'; }
  const { error } = await db.rpc('signature_complete_event', { p_id: event.id, p_claim: event.claim_token, p_error: errorCode });
  if (error) throw new Error('event_completion_failed');
}
