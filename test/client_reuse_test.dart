import 'package:a_g_sur_back_office/backend/client_reuse.dart';
import 'package:flutter_test/flutter_test.dart';

// Guarda as regras de reuso de cliente na conversão proposta→contrato
// (caso Maria Silva, 2026-07-29): reusar em silêncio um cliente de outro
// lead pendura o contrato na pessoa errada e deixa o lead preso no funil.
void main() {
  const leadDaProposta = '11111111-1111-1111-1111-111111111111';
  const outroLead = '22222222-2222-2222-2222-222222222222';

  test('sem cadastro ativo → criarNovo', () {
    expect(
      decideClientReuse(
        proposalLeadId: leadDaProposta,
        userExists: false,
      ),
      ClientReuseDecision.criarNovo,
    );
  });

  test('cliente do mesmo lead (recompra) → reusarMesmoLead', () {
    expect(
      decideClientReuse(
        proposalLeadId: leadDaProposta,
        userExists: true,
        existingIsCliente: true,
        existingLeadId: leadDaProposta,
      ),
      ClientReuseDecision.reusarMesmoLead,
    );
  });

  test('cliente sem lead vinculado → reusarEVincular', () {
    for (final semVinculo in [null, '', '   ']) {
      expect(
        decideClientReuse(
          proposalLeadId: leadDaProposta,
          userExists: true,
          existingIsCliente: true,
          existingLeadId: semVinculo,
        ),
        ClientReuseDecision.reusarEVincular,
        reason: 'lead_id "$semVinculo" deveria contar como sem vínculo',
      );
    }
  });

  test('cliente de OUTRO lead → bloquearOutroLead (caso Maria Silva)', () {
    expect(
      decideClientReuse(
        proposalLeadId: leadDaProposta,
        userExists: true,
        existingIsCliente: true,
        existingLeadId: outroLead,
      ),
      ClientReuseDecision.bloquearOutroLead,
    );
  });

  test('e-mail de quem não é Cliente → bloquearNaoCliente', () {
    // Vale mesmo que o lead_id "bata": perfil de painel/piloto/oficina
    // nunca é alvo válido de conversão.
    expect(
      decideClientReuse(
        proposalLeadId: leadDaProposta,
        userExists: true,
        existingIsCliente: false,
        existingLeadId: leadDaProposta,
      ),
      ClientReuseDecision.bloquearNaoCliente,
    );
  });
}
