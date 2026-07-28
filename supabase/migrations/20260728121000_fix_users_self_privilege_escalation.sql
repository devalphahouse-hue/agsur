-- ============================================================================
-- F1 — ESCALADA DE PRIVILÉGIO em public.users (achado grave de 2026-07-28).
-- ============================================================================
-- ⚠️ ESTA MIGRATION MUDA AUTORIZAÇÃO. Aplicar só depois de validar com LOGIN
--    REAL de cada perfil (ver "Validação obrigatória" no fim). Personificação
--    via Management API/psql NÃO testa trigger: session_user vira postgres e o
--    bypass legítimo dispara.
--
-- O QUE ESTÁ ABERTO HOJE
-- ---------------------
-- A policy `user_security_update` (20260508120600) permite UPDATE com
--   USING/WITH CHECK (id = auth.uid() OR auth_is_admin_master())
-- SEM nenhuma restrição de coluna. O comentário dela diz "a trigger já bloqueia
-- campos sensíveis" — e a trigger users_block_privilege_escalation É escrita
-- corretamente para isso, mas está NEUTRALIZADA desde 2026-05-08: ela abre com
--   IF public.auth_is_service_role() THEN RETURN COALESCE(NEW, OLD);
-- e dentro de SECURITY DEFINER `current_user` é o dono (postgres), então esse
-- teste é SEMPRE verdadeiro. 20260715120000 corrigiu 5 funções de guarda
-- trocando por auth_is_service_request() (usa session_user, imune a definer) e
-- deixou esta de fora, registrando que armar exigia reconciliar as regras.
--
-- Resultado: nada guarda as colunas de privilégio. Um Cliente/Piloto/Oficina
-- logado no app (anon key + JWT próprio) faz
--   PATCH /rest/v1/users?id=eq.<seu_uuid>  {"profile_type":"Admin Master"}
-- a policy aprova (é a própria linha) e, como auth_is_admin_master() lê
-- users.profile_type, ele é Admin Master na requisição seguinte — com acesso a
-- todo o cadastro, financeiro, e às RPCs admin_reset_client_password /
-- admin_delete_app_user. Precedente real: 20260508120700_fix_escalated_user.
--
-- POR QUE NÃO BASTA TROCAR A CHECAGEM DE BYPASS
-- ---------------------------------------------
-- As regras da trigger foram escritas em 2026-05-08 assumindo "só Admin Master
-- mexe em usuário", o que NÃO corresponde ao painel de hoje
-- (lib/security/access_control.dart):
--   • recepção   → gerencia pilotos e oficinas (liga/desliga is_active)
--   • documentação/vendedor → funil, mexem em cliente
--   • master     → tudo
-- Armar a trigger como está quebraria o botão ativar/desativar em 6 listagens
-- e a criação de cliente pelo vendedor na conversão (a ramificação de INSERT
-- só aceita auto-cadastro).
--
-- A CORREÇÃO
-- ----------
-- Separa POR QUEM É O ALVO, que é onde mora a diferença real de risco:
--   • editando A SI MESMO  → NENHUMA coluna de privilégio pode mudar. É este o
--     caminho da escalada, e não existe fluxo legítimo em que alguém altere o
--     próprio perfil/nível/status pelo painel ou pelo app (as telas de perfil
--     gravam só name/phone/profile_photo_url).
--   • editando OUTRA PESSOA → exige papel de painel (auth_is_seller_or_admin).
--     Master segue podendo tudo. Não-master pode status e cadastro (is_active,
--     is_deleted, email, cpf, lead_id...), que é o uso real, mas NÃO pode
--     mexer em profile_type / is_admin / access_level: promover alguém
--     continua sendo exclusividade do master.
--   • INSERT/DELETE → ramificações INTOCADAS (mantêm o bypass antigo). Elas
--     dependem dos fluxos de criação (signup, conversão, cadastro de
--     piloto/oficina) que ainda não foram reconciliados; endurecê-las é outro
--     trabalho. Esta migration fecha SÓ o UPDATE, que é o vetor da escalada.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.tg_users_block_privilege_escalation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_id uuid := auth.uid();
  is_master boolean := false;
  is_panel  boolean := false;
  is_self   boolean := false;
BEGIN
  -- INSERT/DELETE: bypass ANTIGO de propósito (ver header). Só o UPDATE usa a
  -- checagem imune a definer.
  IF TG_OP <> 'UPDATE' THEN
    IF public.auth_is_service_role() THEN
      RETURN COALESCE(NEW, OLD);
    END IF;
  ELSE
    IF public.auth_is_service_request() THEN
      RETURN NEW;
    END IF;
  END IF;

  IF caller_id IS NULL THEN
    RAISE EXCEPTION 'users: anonymous writes not allowed' USING ERRCODE = '42501';
  END IF;

  is_master := public.auth_is_admin_master();

  -- =========================== INSERT ===========================
  IF TG_OP = 'INSERT' THEN
    IF is_master THEN
      RETURN NEW;
    END IF;

    IF NEW.id IS NULL OR NEW.id <> caller_id THEN
      RAISE EXCEPTION 'users.insert: can only self-register' USING ERRCODE = '42501';
    END IF;

    IF COALESCE(NEW.is_admin, false) THEN
      RAISE EXCEPTION 'users.insert: cannot self-assign is_admin' USING ERRCODE = '42501';
    END IF;

    RETURN NEW;
  END IF;

  -- =========================== UPDATE ===========================
  IF TG_OP = 'UPDATE' THEN
    IF is_master THEN
      RETURN NEW;
    END IF;

    is_self   := (caller_id = OLD.id);
    is_panel  := public.auth_is_seller_or_admin();

    IF NEW.id IS DISTINCT FROM OLD.id THEN
      RAISE EXCEPTION 'users.update: id is immutable' USING ERRCODE = '42501';
    END IF;

    -- ---- editando a SI MESMO: nenhuma coluna de privilégio muda ----
    -- Fecha a escalada. Vale inclusive para admin não-master: ninguém se
    -- promove sozinho, nem reativa a própria conta desativada.
    IF is_self THEN
      IF NEW.profile_type IS DISTINCT FROM OLD.profile_type
         OR COALESCE(NEW.is_admin, false)   IS DISTINCT FROM COALESCE(OLD.is_admin, false)
         OR NEW.access_level IS DISTINCT FROM OLD.access_level
         OR COALESCE(NEW.is_active, true)   IS DISTINCT FROM COALESCE(OLD.is_active, true)
         OR COALESCE(NEW.is_deleted, false) IS DISTINCT FROM COALESCE(OLD.is_deleted, false)
         OR NEW.email  IS DISTINCT FROM OLD.email
         OR NEW.cpf    IS DISTINCT FROM OLD.cpf
         OR NEW.lead_id IS DISTINCT FROM OLD.lead_id
         OR NEW.job_title_admin IS DISTINCT FROM OLD.job_title_admin
      THEN
        RAISE EXCEPTION 'users.update: cannot change own privileged fields'
          USING ERRCODE = '42501';
      END IF;

      RETURN NEW;   -- name / phone / profile_photo_url etc. seguem livres
    END IF;

    -- ---- editando OUTRA PESSOA: exige papel de painel ----
    IF NOT is_panel THEN
      RAISE EXCEPTION 'users.update: requires panel role to edit other users'
        USING ERRCODE = '42501';
    END IF;

    -- Promover/rebaixar continua sendo só do master.
    IF NEW.profile_type IS DISTINCT FROM OLD.profile_type
       OR COALESCE(NEW.is_admin, false) IS DISTINCT FROM COALESCE(OLD.is_admin, false)
       OR NEW.access_level IS DISTINCT FROM OLD.access_level
    THEN
      RAISE EXCEPTION 'users.update: role/level change requires Admin Master'
        USING ERRCODE = '42501';
    END IF;

    -- is_active / is_deleted / email / cpf / lead_id ficam liberados para o
    -- papel de painel: é o uso real (toggle das 6 listagens, troca de e-mail
    -- pela RPC de documentação, tombstone do delete).
    RETURN NEW;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.tg_users_block_privilege_escalation() IS
  'Guarda de public.users. UPDATE é armado (auth_is_service_request, imune a definer): auto-edição não muda NENHUM campo de privilégio; editar terceiro exige papel de painel e só master muda profile_type/is_admin/access_level. INSERT/DELETE mantêm o bypass antigo de propósito (fluxos de criação ainda não reconciliados).';

-- A trigger já existe desde 20260508120100 (BEFORE INSERT OR UPDATE OR DELETE);
-- o CREATE OR REPLACE acima basta. Recriada aqui só por idempotência.
DROP TRIGGER IF EXISTS users_block_privilege_escalation ON public.users;
CREATE TRIGGER users_block_privilege_escalation
  BEFORE INSERT OR UPDATE OR DELETE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.tg_users_block_privilege_escalation();

-- ============================================================================
-- Validação obrigatória — com JWT REAL via PostgREST, nunca por psql/Management
-- ============================================================================
--  DEVE FALHAR (42501):
--   1. Cliente/Piloto/Oficina no app:
--      PATCH /rest/v1/users?id=eq.<próprio> {"profile_type":"Admin Master"}
--   2. idem com {"is_admin":true} e com {"is_active":true} numa conta desativada
--   3. Vendedor: PATCH em users de terceiro com {"profile_type":"Admin"}
--
--  DEVE PASSAR:
--   4. Cliente edita o próprio nome/telefone/foto (app: Editar perfil)
--   5. Recepção liga/desliga is_active de piloto e de oficina (toggle)
--   6. Documentação/vendedor salvam dados cadastrais de cliente no funil
--   7. RPC admin_update_client_email como Admin documentação
--   8. RPC admin_delete_app_user como Admin Master
--   9. Conversão proposta→contrato criando cliente novo (ramificação INSERT,
--      intocada — confirmar que segue passando)
--
-- Rollback (volta ao estado neutralizado): recriar a função com o bypass
-- `IF public.auth_is_service_role() THEN RETURN COALESCE(NEW, OLD); END IF;`
-- no topo, para todos os TG_OP — ou seja, o corpo de 20260508120100.
-- ============================================================================
