// send-credentials-email — dispara, via Resend, o e-mail de boas-vindas com as
// credenciais (e-mail + senha) de um usuário recém-criado pelo painel.
//
// Segurança:
//  - A plataforma já exige JWT válido (verify_jwt, default do deploy).
//  - Além disso, só perfis do PAINEL (Admin Master / Admin / Vendedor / Admin2)
//    podem invocar — qualquer sessão de Cliente/Piloto/Oficina recebe 403.
//    Sem esse gate a função seria um relay aberto de e-mail para qualquer
//    conta autenticada do app cliente.
//  - RESEND_API_KEY vem de `supabase secrets set` — nunca do código/git.
//
// Payload: { email, password, name?, profileType }
//  - profileType decide a instrução de acesso: perfis do painel recebem o link
//    do painel; Cliente/Piloto/Oficina recebem instrução de baixar o app.

import { createClient } from "npm:@supabase/supabase-js@2";

const PANEL_PROFILES = ["Admin Master", "Admin", "Vendedor", "Admin2"];
const PANEL_URL = "https://painel-agsur.vercel.app";
const APP_STORE_URL =
  "https://apps.apple.com/us/app/aerotg-avia%C3%A7%C3%A3o/id6769067230";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.agsur.clientapp";
const FROM = "Agsur <acesso@painel.agsurbrasil.app>";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function buildEmailHtml(opts: {
  name: string;
  email: string;
  password: string;
  profileType: string;
}): string {
  const isPanelProfile = PANEL_PROFILES.includes(opts.profileType) ||
    opts.profileType === "Colaborador";
  const accessBlock = isPanelProfile
    ? `<p style="margin:0 0 8px">Acesse o painel administrativo em:</p>
       <p style="margin:0 0 24px"><a href="${PANEL_URL}" style="color:#5a6b02;font-weight:bold">${PANEL_URL}</a></p>`
    : `<p style="margin:0 0 16px">Baixe o aplicativo <strong>Agsur</strong> e entre com os dados acima:</p>
       <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 24px">
         <tr>
           <td style="padding:0 12px 0 0">
             <a href="${APP_STORE_URL}"
                style="display:inline-block;background:#111111;color:#ffffff;text-decoration:none;border-radius:10px;padding:12px 22px;font-family:Arial,Helvetica,sans-serif;text-align:left">
               <span style="display:block;font-size:11px;color:#cccccc;line-height:1.2">Baixar para iPhone na</span>
               <span style="display:block;font-size:17px;font-weight:bold;line-height:1.3">App&nbsp;Store</span>
             </a>
           </td>
           <td>
             <a href="${PLAY_STORE_URL}"
                style="display:inline-block;background:#111111;color:#ffffff;text-decoration:none;border-radius:10px;padding:12px 22px;font-family:Arial,Helvetica,sans-serif;text-align:left">
               <span style="display:block;font-size:11px;color:#cccccc;line-height:1.2">Baixar para Android no</span>
               <span style="display:block;font-size:17px;font-weight:bold;line-height:1.3">Google&nbsp;Play</span>
             </a>
           </td>
         </tr>
       </table>`;

  return `
  <div style="background:#f4f4f2;padding:32px 16px;font-family:Arial,Helvetica,sans-serif;color:#313131">
    <div style="max-width:560px;margin:0 auto;background:#ffffff;border-radius:12px;padding:32px">
      <h1 style="font-size:20px;margin:0 0 16px">Bem-vindo(a) à Agsur!</h1>
      <p style="margin:0 0 16px">Olá${opts.name ? `, <strong>${escapeHtml(opts.name)}</strong>` : ""}!</p>
      <p style="margin:0 0 16px">Sua conta de <strong>${escapeHtml(opts.profileType)}</strong> foi criada. Estes são os seus dados de acesso:</p>
      <div style="background:#f7f8ef;border:1px solid #c2d51c;border-radius:8px;padding:16px 20px;margin:0 0 24px">
        <p style="margin:0 0 8px"><strong>E-mail:</strong> ${escapeHtml(opts.email)}</p>
        <p style="margin:0"><strong>Senha:</strong> <code style="font-size:15px">${escapeHtml(opts.password)}</code></p>
      </div>
      ${accessBlock}
      <p style="margin:0 0 8px;font-size:13px;color:#6b6b6b">Por segurança, recomendamos trocar a senha no primeiro acesso.</p>
      <p style="margin:0;font-size:13px;color:#6b6b6b">Se você não esperava este e-mail, ignore-o ou avise a equipe Agsur.</p>
    </div>
  </div>`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }

  const resendKey = Deno.env.get("RESEND_API_KEY");
  if (!resendKey) {
    return json(500, { error: "missing_resend_api_key" });
  }

  // Autorização: identifica o chamador pelo JWT e exige perfil do painel.
  const jwt = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: userData, error: authError } = await admin.auth.getUser(jwt);
  if (authError || !userData?.user) {
    return json(401, { error: "invalid_jwt" });
  }
  const { data: caller } = await admin
    .from("users")
    .select("profile_type, is_deleted")
    .eq("id", userData.user.id)
    .maybeSingle();
  if (
    !caller || caller.is_deleted === true ||
    !PANEL_PROFILES.includes(caller.profile_type ?? "")
  ) {
    return json(403, { error: "forbidden" });
  }

  let payload: {
    email?: string;
    password?: string;
    name?: string;
    profileType?: string;
  };
  try {
    payload = await req.json();
  } catch {
    return json(400, { error: "invalid_json" });
  }
  const { email, password, name = "", profileType = "Usuário" } = payload;
  if (!email || !password || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return json(400, { error: "invalid_payload" });
  }

  const resendResponse = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: FROM,
      to: [email],
      subject: "Seu acesso à plataforma Agsur",
      html: buildEmailHtml({ name, email, password, profileType }),
    }),
  });

  if (!resendResponse.ok) {
    const detail = await resendResponse.text();
    console.error("resend_error", resendResponse.status, detail);
    return json(502, { error: "resend_failed", status: resendResponse.status });
  }

  const sent = await resendResponse.json();
  return json(200, { ok: true, id: sent.id });
});
