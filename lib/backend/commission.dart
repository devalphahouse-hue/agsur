/// Régua de comissão da venda (definida pelo dono em 17/08/2026).
///
/// Antes desta data a conversão gravava percentuais chumbados no meio do
/// `view_edit_proposal_widget.dart`: 25% para a AGSur e 5% para o vendedor.
/// A régua nova é outra e vive AQUI, num só lugar, para que mudá-la de novo
/// não signifique caçar literais dentro de um widget de 6 mil linhas:
///
/// - **AGSur**: 2% do valor do contrato.
/// - **Vendedor**: valor fixo, independente do tamanho da venda —
///   US$ 7.500,00 normalmente, US$ 4.500,00 quando a venda veio de indicação
///   (os US$ 3.000,00 de diferença são a contribuição do vendedor para o
///   pagamento de quem indicou).
///
/// ⚠️ `sales.seller_commission` é o **bolo da venda, não o pagamento de uma
/// pessoa**: "7500, eu divido entre eles" (Thiago, 17/08). O rateio entre os
/// vendedores é feito fora do sistema. Por isso `sales.seller_id` — que hoje
/// recebe quem CRIOU a proposta — é atribuição informativa, não a definição
/// de quem recebe o quê; e o card "Comissão vendedores" do dashboard é o
/// total a distribuir, não o de ninguém em particular.
///
/// A comissão é calculada e **congelada** no momento da conversão
/// proposta→contrato: o resultado vai para `sales.company_commission` e
/// `sales.seller_commission` e não é recalculado depois. Editar o preço da
/// proposta mais tarde não mexe na comissão já gravada — é registro histórico
/// do que foi combinado.
///
/// As vendas anteriores a 17/08 **foram reprocessadas** com esta régua pela
/// migration `20260817140000_recalc_sale_commissions` (o dono pediu o acerto
/// depois de ter decidido o contrário — o dashboard mostrava número que não
/// correspondia mais ao combinado). Ou seja: hoje NÃO existe venda gravada com
/// a régua antiga de 25%/5%. Se um dia a régua mudar de novo, decida
/// explicitamente entre reprocessar ou não, e registre aqui.
///
/// Cálculo puro (sem I/O) para ser testável; quem aplica é a conversão em
/// `view_edit_proposal_widget.dart`.
library;

/// Percentual da AGSur sobre o valor do contrato.
const double kCompanyCommissionRate = 0.02;

/// Comissão do vendedor numa venda direta.
const double kSellerCommissionFlat = 7500.0;

/// Comissão do vendedor quando a venda veio de indicação.
const double kSellerCommissionReferral = 4500.0;

/// Quanto o vendedor abre mão por ter vindo de indicação. Derivado das duas
/// constantes acima de propósito: mudar um dos valores não pode deixar este
/// número mentindo (ele é o que o futuro card INDICAÇÃO vai somar).
const double kSellerReferralGiveback =
    kSellerCommissionFlat - kSellerCommissionReferral;

/// As duas comissões de uma venda.
class SaleCommission {
  const SaleCommission({required this.company, required this.seller});

  /// Vai para `sales.company_commission`.
  final double company;

  /// Vai para `sales.seller_commission`.
  final double seller;

  @override
  String toString() =>
      'SaleCommission(company: $company, seller: $seller)';

  @override
  bool operator ==(Object other) =>
      other is SaleCommission &&
      other.company == company &&
      other.seller == seller;

  @override
  int get hashCode => Object.hash(company, seller);
}

/// Quem indicou a venda. Capturado no cadastro do LEAD (migration
/// `20260817120000`), porque o dado precisa chegar à conversão a tempo de
/// definir a comissão do vendedor.
class ReferralInfo {
  const ReferralInfo({
    required this.name,
    this.phone,
    this.email,
    this.agreedValue,
  });

  /// Único campo obrigatório — é o que o CHECK `leads_referral_coerente`
  /// exige para uma linha marcada como indicação.
  final String name;
  final String? phone;
  final String? email;

  /// Valor combinado com quem indicou, em dólar. Ainda não é lido por
  /// nenhuma tela: guarda histórico para o card INDICAÇÃO futuro.
  ///
  /// **Quem paga sai do bolo dos VENDEDORES, não da AGSur** (decisão do dono,
  /// 17/08). Por isso `calcularComissao` não mexe na comissão da empresa
  /// quando há indicação — os 2% saem inteiros. Quando o card INDICAÇÃO for
  /// construído, a subtração é na linha dos vendedores.
  ///
  /// O rateio NÃO é negociado por venda: os US$ 7.500,00 são um bolo fixo,
  /// independente do avião, e numa indicação ele se parte sempre igual —
  /// US$ 3.000,00 para quem indicou, US$ 4.500,00 para o vendedor. Logo a
  /// perda por indicação é `kSellerReferralGiveback × nº de vendas
  /// indicadas`, e este campo é REGISTRO do que foi combinado, não uma
  /// variável de cálculo. Se um dia o combinado passar a variar por venda, é
  /// aqui que a régua muda — e aí `calcularComissao` precisa recebê-lo.
  final double? agreedValue;
}

/// Colunas de `leads` que representam a indicação.
///
/// `null` limpa tudo e desmarca — importante para não deixar nome/valor de
/// indicador pendurados num lead que deixou de ser indicação (o CHECK do
/// banco rejeitaria `is_referral=false` com nome preenchido, e o card futuro
/// somaria lixo).
Map<String, dynamic> leadReferralColumns(ReferralInfo? referral) => {
      'is_referral': referral != null,
      'referral_name': referral?.name,
      'referral_phone': referral?.phone,
      'referral_email': referral?.email,
      'referral_agreed_value': referral?.agreedValue,
    };

/// Calcula a comissão de uma venda de [fullprice].
///
/// [isIndicacao] vem do lead (`leads.is_referral`) — é lá que a indicação é
/// marcada, porque o dado precisa existir ANTES da conversão para a comissão
/// já nascer certa.
///
/// [fullprice] negativo ou não-finito é tratado como zero: a comissão da
/// empresa nunca sai negativa, e a do vendedor é fixa de qualquer forma.
SaleCommission calcularComissao({
  required double fullprice,
  required bool isIndicacao,
}) {
  final base = (fullprice.isFinite && fullprice > 0) ? fullprice : 0.0;
  return SaleCommission(
    company: base * kCompanyCommissionRate,
    seller: isIndicacao ? kSellerCommissionReferral : kSellerCommissionFlat,
  );
}
