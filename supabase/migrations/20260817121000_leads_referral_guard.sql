-- Guarda das colunas de indicação em `leads` (2026-08-17)
--
-- Complementa `20260817120000_leads_referral`. Aquela migration criou as
-- colunas; esta impede que quem não deve mexa nelas.
--
-- POR QUE. `leads.is_referral` decide dinheiro: na conversão ela define se
-- `sales.seller_commission` sai US$ 7.500,00 ou US$ 4.500,00
-- (`lib/backend/commission.dart`). E a policy de escrita da tabela é
-- `leads_seller_or_admin_only` → `auth_is_seller_or_admin()`, que **inclui
-- Vendedor**. Ou seja: sem esta trigger, um vendedor consegue
--
--   PATCH /rest/v1/leads?id=eq.<lead> {"is_referral": false}
--
-- direto no PostgREST e subir a própria comissão em US$ 3.000,00 antes da
-- proposta virar contrato. O painel já esconde a seção de quem não é
-- master/documentação, mas o gate client-side nunca foi o guarda real —
-- é a mesma lição de `20260728121000` (escalonamento em `users`).
--
-- REGRA: mexer nas 5 colunas exige `auth_is_admin_documentacao()`
-- (Admin Master OU Admin com access_level='documentacao') — a mesma régua do
-- `AccessControl.canEditFunil` usado na UI.
--
-- EXCEÇÃO deliberada no INSERT: criar lead SEM indicação segue livre para
-- Vendedor, senão a trigger quebraria o cadastro de lead do funil inteiro
-- (todo lead nasce com is_referral=false por default). Só o INSERT que já
-- vem COM indicação marcada é barrado. Consequência prática, aceita com o
-- dono: quem registra uma indicação é master/documentação — o vendedor
-- avisa, não cadastra. A UI reflete isso (a caixa nem aparece para ele).
--
-- Usa `auth_is_service_request()` (session_user), não `auth_is_service_role()`:
-- dentro de função SECURITY DEFINER a segunda devolve true para qualquer
-- chamador e a guarda vira no-op — foi o bug corrigido em `20260715120000`.
--
-- ⚠️ Personificação via Management API / psql NÃO testa esta trigger
-- (session_user = postgres → bypass). Validar com JWT real via PostgREST.
--
-- ROLLBACK:
--   drop trigger if exists hardening_leads_referral_guard on public.leads;
--   drop function if exists public.tg_leads_protect_referral();
--
-- VALIDAR (JWT real, via PostgREST):
--   1. Vendedor: criar lead sem indicação            -> 201 OK.
--   2. Vendedor: criar lead com is_referral=true     -> 42501.
--   3. Vendedor: PATCH is_referral em lead existente -> 42501.
--   4. Vendedor: PATCH name/email do lead (colunas normais) -> 200 OK.
--   5. Documentação e Master: 2 e 3 -> OK.

CREATE OR REPLACE FUNCTION public.tg_leads_protect_referral()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_touches_referral boolean;
BEGIN
  IF public.auth_is_service_request() THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  IF TG_OP = 'INSERT' THEN
    -- Lead nascendo sem indicação: caminho normal do funil, segue livre.
    v_touches_referral :=
         COALESCE(NEW.is_referral, false) IS TRUE
      OR NEW.referral_name         IS NOT NULL
      OR NEW.referral_phone        IS NOT NULL
      OR NEW.referral_email        IS NOT NULL
      OR NEW.referral_agreed_value IS NOT NULL;
  ELSE
    v_touches_referral :=
         NEW.is_referral          IS DISTINCT FROM OLD.is_referral
      OR NEW.referral_name         IS DISTINCT FROM OLD.referral_name
      OR NEW.referral_phone        IS DISTINCT FROM OLD.referral_phone
      OR NEW.referral_email        IS DISTINCT FROM OLD.referral_email
      OR NEW.referral_agreed_value IS DISTINCT FROM OLD.referral_agreed_value;
  END IF;

  IF NOT v_touches_referral THEN
    RETURN NEW;
  END IF;

  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'leads: anonymous writes blocked'
      USING ERRCODE = '42501';
  END IF;

  IF NOT public.auth_is_admin_documentacao() THEN
    RAISE EXCEPTION 'leads.indicacao: requires Admin Master or Admin/documentacao profile'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION public.tg_leads_protect_referral() IS
  'Restringe as colunas de indicação de leads (is_referral, referral_*) a '
  'Admin Master/documentação. Elas definem a comissão do vendedor na '
  'conversão — ver lib/backend/commission.dart. INSERT sem indicação segue '
  'livre para o funil.';

DROP TRIGGER IF EXISTS hardening_leads_referral_guard ON public.leads;

CREATE TRIGGER hardening_leads_referral_guard
  BEFORE INSERT OR UPDATE ON public.leads
  FOR EACH ROW EXECUTE FUNCTION public.tg_leads_protect_referral();

REVOKE ALL ON FUNCTION public.tg_leads_protect_referral() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.tg_leads_protect_referral()
  TO authenticated, service_role;
