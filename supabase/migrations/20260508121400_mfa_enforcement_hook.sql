-- ============================================================================
-- Custom Access Token Hook — MFA enforcement para Admin Master.
--
-- A função fica pronta no banco mas SÓ entra em efeito quando você ativar
-- o hook no Studio (Auth → Hooks → "Custom Access Token" → apontar para
-- public.custom_access_token_hook).
--
-- Comportamento:
--   - Admin Master logando com aal1 (sem MFA) → JWT rejeitado, mensagem
--     orientando enrolamento.
--   - Admin/Vendedor: JWT emitido normalmente (MFA recomendado mas não obrigatório).
--   - Cliente/Piloto/Oficina: JWT emitido normalmente.
--
-- Segurança: a função é STABLE + SECURITY DEFINER + search_path fixo.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_aal text;
  v_profile text;
  v_claims jsonb;
BEGIN
  v_claims := COALESCE(event->'claims', '{}'::jsonb);
  v_user_id := (event->>'user_id')::uuid;
  v_aal := COALESCE(v_claims->>'aal', 'aal1');

  -- Pega o profile do user
  SELECT profile_type::text INTO v_profile
  FROM public.users
  WHERE id = v_user_id;

  -- Admin Master sem MFA → rejeita JWT
  IF v_profile = 'Admin Master' AND v_aal <> 'aal2' THEN
    RETURN jsonb_build_object(
      'error', jsonb_build_object(
        'http_code', 403,
        'message', 'Admin Master requer MFA. Habilite um segundo fator antes de continuar.'
      )
    );
  END IF;

  -- Adiciona profile_type ao claim para o front consumir sem fazer query extra
  IF v_profile IS NOT NULL THEN
    v_claims := jsonb_set(v_claims, '{profile_type}', to_jsonb(v_profile));
  END IF;

  RETURN jsonb_build_object('claims', v_claims);
END;
$$;

-- A function precisa ser executável pelo serviço supabase_auth_admin que roda
-- o hook. Ver docs.
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb) TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb) FROM authenticated, anon, public;

COMMENT ON FUNCTION public.custom_access_token_hook(jsonb) IS
  'Auth hook (Custom Access Token). Rejeita JWT issue para Admin Master sem aal2 (MFA). Ativar via Studio → Auth → Hooks.';
