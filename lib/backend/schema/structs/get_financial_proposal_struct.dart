// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GetFinancialProposalStruct extends BaseStruct {
  GetFinancialProposalStruct({
    double? fullprice,
    double? sinal,
    double? depositoInicial,
    double? taxaPremium,
    int? prazo,
    double? taxaJuros,
    double? taxaSofr,
    double? taxaJurosEfetivos,
    DateTime? dataCredito,
    double? creditoTotal,
    double? percentualPgtoTotal,
  })  : _fullprice = fullprice,
        _sinal = sinal,
        _depositoInicial = depositoInicial,
        _taxaPremium = taxaPremium,
        _prazo = prazo,
        _taxaJuros = taxaJuros,
        _taxaSofr = taxaSofr,
        _taxaJurosEfetivos = taxaJurosEfetivos,
        _dataCredito = dataCredito,
        _creditoTotal = creditoTotal,
        _percentualPgtoTotal = percentualPgtoTotal;

  // "fullprice" field.
  double? _fullprice;
  double get fullprice => _fullprice ?? 0.0;
  set fullprice(double? val) => _fullprice = val;

  void incrementFullprice(double amount) => fullprice = fullprice + amount;

  bool hasFullprice() => _fullprice != null;

  // "sinal" field.
  double? _sinal;
  double get sinal => _sinal ?? 0.0;
  set sinal(double? val) => _sinal = val;

  void incrementSinal(double amount) => sinal = sinal + amount;

  bool hasSinal() => _sinal != null;

  // "deposito_inicial" field.
  double? _depositoInicial;
  double get depositoInicial => _depositoInicial ?? 0.0;
  set depositoInicial(double? val) => _depositoInicial = val;

  void incrementDepositoInicial(double amount) =>
      depositoInicial = depositoInicial + amount;

  bool hasDepositoInicial() => _depositoInicial != null;

  // "taxa_premium" field.
  double? _taxaPremium;
  double get taxaPremium => _taxaPremium ?? 0.0;
  set taxaPremium(double? val) => _taxaPremium = val;

  void incrementTaxaPremium(double amount) =>
      taxaPremium = taxaPremium + amount;

  bool hasTaxaPremium() => _taxaPremium != null;

  // "prazo" field.
  int? _prazo;
  int get prazo => _prazo ?? 0;
  set prazo(int? val) => _prazo = val;

  void incrementPrazo(int amount) => prazo = prazo + amount;

  bool hasPrazo() => _prazo != null;

  // "taxa_juros" field.
  double? _taxaJuros;
  double get taxaJuros => _taxaJuros ?? 0.0;
  set taxaJuros(double? val) => _taxaJuros = val;

  void incrementTaxaJuros(double amount) => taxaJuros = taxaJuros + amount;

  bool hasTaxaJuros() => _taxaJuros != null;

  // "taxa_sofr" field.
  double? _taxaSofr;
  double get taxaSofr => _taxaSofr ?? 0.0;
  set taxaSofr(double? val) => _taxaSofr = val;

  void incrementTaxaSofr(double amount) => taxaSofr = taxaSofr + amount;

  bool hasTaxaSofr() => _taxaSofr != null;

  // "taxa_juros_efetivos" field.
  double? _taxaJurosEfetivos;
  double get taxaJurosEfetivos => _taxaJurosEfetivos ?? 0.0;
  set taxaJurosEfetivos(double? val) => _taxaJurosEfetivos = val;

  void incrementTaxaJurosEfetivos(double amount) =>
      taxaJurosEfetivos = taxaJurosEfetivos + amount;

  bool hasTaxaJurosEfetivos() => _taxaJurosEfetivos != null;

  // "data_credito" field.
  DateTime? _dataCredito;
  DateTime? get dataCredito => _dataCredito;
  set dataCredito(DateTime? val) => _dataCredito = val;

  bool hasDataCredito() => _dataCredito != null;

  // "credito_total" field.
  double? _creditoTotal;
  double get creditoTotal => _creditoTotal ?? 0.0;
  set creditoTotal(double? val) => _creditoTotal = val;

  void incrementCreditoTotal(double amount) =>
      creditoTotal = creditoTotal + amount;

  bool hasCreditoTotal() => _creditoTotal != null;

  // "percentual_pgto_total" field.
  double? _percentualPgtoTotal;
  double get percentualPgtoTotal => _percentualPgtoTotal ?? 0.0;
  set percentualPgtoTotal(double? val) => _percentualPgtoTotal = val;

  void incrementPercentualPgtoTotal(double amount) =>
      percentualPgtoTotal = percentualPgtoTotal + amount;

  bool hasPercentualPgtoTotal() => _percentualPgtoTotal != null;

  static GetFinancialProposalStruct fromMap(Map<String, dynamic> data) =>
      GetFinancialProposalStruct(
        fullprice: castToType<double>(data['fullprice']),
        sinal: castToType<double>(data['sinal']),
        depositoInicial: castToType<double>(data['deposito_inicial']),
        taxaPremium: castToType<double>(data['taxa_premium']),
        prazo: castToType<int>(data['prazo']),
        taxaJuros: castToType<double>(data['taxa_juros']),
        taxaSofr: castToType<double>(data['taxa_sofr']),
        taxaJurosEfetivos: castToType<double>(data['taxa_juros_efetivos']),
        dataCredito: data['data_credito'] as DateTime?,
        creditoTotal: castToType<double>(data['credito_total']),
        percentualPgtoTotal: castToType<double>(data['percentual_pgto_total']),
      );

  static GetFinancialProposalStruct? maybeFromMap(dynamic data) => data is Map
      ? GetFinancialProposalStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'fullprice': _fullprice,
        'sinal': _sinal,
        'deposito_inicial': _depositoInicial,
        'taxa_premium': _taxaPremium,
        'prazo': _prazo,
        'taxa_juros': _taxaJuros,
        'taxa_sofr': _taxaSofr,
        'taxa_juros_efetivos': _taxaJurosEfetivos,
        'data_credito': _dataCredito,
        'credito_total': _creditoTotal,
        'percentual_pgto_total': _percentualPgtoTotal,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'fullprice': serializeParam(
          _fullprice,
          ParamType.double,
        ),
        'sinal': serializeParam(
          _sinal,
          ParamType.double,
        ),
        'deposito_inicial': serializeParam(
          _depositoInicial,
          ParamType.double,
        ),
        'taxa_premium': serializeParam(
          _taxaPremium,
          ParamType.double,
        ),
        'prazo': serializeParam(
          _prazo,
          ParamType.int,
        ),
        'taxa_juros': serializeParam(
          _taxaJuros,
          ParamType.double,
        ),
        'taxa_sofr': serializeParam(
          _taxaSofr,
          ParamType.double,
        ),
        'taxa_juros_efetivos': serializeParam(
          _taxaJurosEfetivos,
          ParamType.double,
        ),
        'data_credito': serializeParam(
          _dataCredito,
          ParamType.DateTime,
        ),
        'credito_total': serializeParam(
          _creditoTotal,
          ParamType.double,
        ),
        'percentual_pgto_total': serializeParam(
          _percentualPgtoTotal,
          ParamType.double,
        ),
      }.withoutNulls;

  static GetFinancialProposalStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      GetFinancialProposalStruct(
        fullprice: deserializeParam(
          data['fullprice'],
          ParamType.double,
          false,
        ),
        sinal: deserializeParam(
          data['sinal'],
          ParamType.double,
          false,
        ),
        depositoInicial: deserializeParam(
          data['deposito_inicial'],
          ParamType.double,
          false,
        ),
        taxaPremium: deserializeParam(
          data['taxa_premium'],
          ParamType.double,
          false,
        ),
        prazo: deserializeParam(
          data['prazo'],
          ParamType.int,
          false,
        ),
        taxaJuros: deserializeParam(
          data['taxa_juros'],
          ParamType.double,
          false,
        ),
        taxaSofr: deserializeParam(
          data['taxa_sofr'],
          ParamType.double,
          false,
        ),
        taxaJurosEfetivos: deserializeParam(
          data['taxa_juros_efetivos'],
          ParamType.double,
          false,
        ),
        dataCredito: deserializeParam(
          data['data_credito'],
          ParamType.DateTime,
          false,
        ),
        creditoTotal: deserializeParam(
          data['credito_total'],
          ParamType.double,
          false,
        ),
        percentualPgtoTotal: deserializeParam(
          data['percentual_pgto_total'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'GetFinancialProposalStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is GetFinancialProposalStruct &&
        fullprice == other.fullprice &&
        sinal == other.sinal &&
        depositoInicial == other.depositoInicial &&
        taxaPremium == other.taxaPremium &&
        prazo == other.prazo &&
        taxaJuros == other.taxaJuros &&
        taxaSofr == other.taxaSofr &&
        taxaJurosEfetivos == other.taxaJurosEfetivos &&
        dataCredito == other.dataCredito &&
        creditoTotal == other.creditoTotal &&
        percentualPgtoTotal == other.percentualPgtoTotal;
  }

  @override
  int get hashCode => const ListEquality().hash([
        fullprice,
        sinal,
        depositoInicial,
        taxaPremium,
        prazo,
        taxaJuros,
        taxaSofr,
        taxaJurosEfetivos,
        dataCredito,
        creditoTotal,
        percentualPgtoTotal
      ]);
}

GetFinancialProposalStruct createGetFinancialProposalStruct({
  double? fullprice,
  double? sinal,
  double? depositoInicial,
  double? taxaPremium,
  int? prazo,
  double? taxaJuros,
  double? taxaSofr,
  double? taxaJurosEfetivos,
  DateTime? dataCredito,
  double? creditoTotal,
  double? percentualPgtoTotal,
}) =>
    GetFinancialProposalStruct(
      fullprice: fullprice,
      sinal: sinal,
      depositoInicial: depositoInicial,
      taxaPremium: taxaPremium,
      prazo: prazo,
      taxaJuros: taxaJuros,
      taxaSofr: taxaSofr,
      taxaJurosEfetivos: taxaJurosEfetivos,
      dataCredito: dataCredito,
      creditoTotal: creditoTotal,
      percentualPgtoTotal: percentualPgtoTotal,
    );
