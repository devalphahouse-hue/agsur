-- ============================================================================
-- Correção pontual: usuário com profile_type=Cliente E is_admin=true.
--
-- Era escalation acontecida via all_access antes da trigger users_block_*.
-- A trigger atual já impede que isso aconteça novamente.
-- ============================================================================

UPDATE public.users
SET is_admin = false
WHERE id = '1bc8194a-11e8-484e-bf1b-62d5635b7271'
  AND profile_type = 'Cliente'::profile_types
  AND is_admin = true;
