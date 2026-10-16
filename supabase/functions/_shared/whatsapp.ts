export function templatePayload(to: string, message: string, reminderId: string, name: string, language: string) {
  return {
    messaging_product: "whatsapp", recipient_type: "individual", to, type: "template",
    biz_opaque_callback_data: reminderId,
    template: { name, language: { code: language }, components: [{ type: "body", parameters: [{ type: "text", text: message.replace(/\s+/g, " ").trim() }] }] },
  };
}

export async function validSignature(body: string, signature: string | null, secret: string): Promise<boolean> {
  if (!signature || !/^sha256=[a-f0-9]{64}$/.test(signature)) return false;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["verify"]);
  const bytes = new Uint8Array(signature.slice(7).match(/../g)!.map((x) => parseInt(x, 16)));
  return crypto.subtle.verify("HMAC", key, bytes, new TextEncoder().encode(body));
}

export async function constantTimeEqual(left: string, right: string): Promise<boolean> {
  const enc = new TextEncoder();
  const a = new Uint8Array(await crypto.subtle.digest("SHA-256", enc.encode(left)));
  const b = new Uint8Array(await crypto.subtle.digest("SHA-256", enc.encode(right)));
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

export function classifyMetaFailure(httpStatus: number, errorCode: unknown): { code: string; retriable: boolean } {
  const code = String(errorCode ?? `http_${httpStatus}`).slice(0, 100);
  const permanent = ["190", "131009", "131026", "131042", "132000", "132001", "132005", "132007"];
  return { code, retriable: !permanent.includes(code) && (httpStatus === 429 || httpStatus >= 500 || code === "130429") };
}
