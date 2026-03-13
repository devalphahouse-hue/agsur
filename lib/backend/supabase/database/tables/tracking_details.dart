import '../database.dart';

class TrackingDetailsTable extends SupabaseTable<TrackingDetailsRow> {
  @override
  String get tableName => 'tracking_details';

  @override
  TrackingDetailsRow createRow(Map<String, dynamic> data) =>
      TrackingDetailsRow(data);
}

class TrackingDetailsRow extends SupabaseDataRow {
  TrackingDetailsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TrackingDetailsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get trackingId => getField<String>('tracking_id')!;
  set trackingId(String value) => setField<String>('tracking_id', value);

  // Personalização de Aeronave
  String? get customizationDescription =>
      getField<String>('customization_description');
  set customizationDescription(String? value) =>
      setField<String>('customization_description', value);

  String? get customizationStripe => getField<String>('customization_stripe');
  set customizationStripe(String? value) =>
      setField<String>('customization_stripe', value);

  String? get customizationFilter => getField<String>('customization_filter');
  set customizationFilter(String? value) =>
      setField<String>('customization_filter', value);

  String? get customizationPanel => getField<String>('customization_panel');
  set customizationPanel(String? value) =>
      setField<String>('customization_panel', value);

  // Solicitar Proforma Invoice
  String? get invoiceNumber => getField<String>('invoice_number');
  set invoiceNumber(String? value) => setField<String>('invoice_number', value);

  // Reserva Equipamento Agrícola
  String? get equipmentType => getField<String>('equipment_type');
  set equipmentType(String? value) => setField<String>('equipment_type', value);

  // Pagamento da Reserva
  bool? get reservationPaid => getField<bool>('reservation_paid');
  set reservationPaid(bool? value) => setField<bool>('reservation_paid', value);

  // Pagamento 5%
  bool? get fivePercentPaid => getField<bool>('five_percent_paid');
  set fivePercentPaid(bool? value) =>
      setField<bool>('five_percent_paid', value);

  // Reserva de Marcas (RAB)
  String? get prefix => getField<String>('prefix');
  set prefix(String? value) => setField<String>('prefix', value);

  String? get prefixFileUrl => getField<String>('prefix_file_url');
  set prefixFileUrl(String? value) =>
      setField<String>('prefix_file_url', value);

  // Contratar Despachante Aduaneiro
  String? get brokerName => getField<String>('broker_name');
  set brokerName(String? value) => setField<String>('broker_name', value);

  // Benefício Fiscal
  bool? get fiscalBenefitActive => getField<bool>('fiscal_benefit_active');
  set fiscalBenefitActive(bool? value) =>
      setField<bool>('fiscal_benefit_active', value);

  bool? get hasRadar => getField<bool>('has_radar');
  set hasRadar(bool? value) => setField<bool>('has_radar', value);

  // Documento de Financiamento ou Pagto à Vista (Order 9 - new fields)
  String? get paymentMethod => getField<String>('payment_method');
  set paymentMethod(String? value) => setField<String>('payment_method', value);

  bool? get finDoc => getField<bool>('fin_doc');
  set finDoc(bool? value) => setField<bool>('fin_doc', value);

  bool? get finContadora => getField<bool>('fin_contadora');
  set finContadora(bool? value) => setField<bool>('fin_contadora', value);

  bool? get finEndUser => getField<bool>('fin_end_user');
  set finEndUser(bool? value) => setField<bool>('fin_end_user', value);

  bool? get finCpi => getField<bool>('fin_cpi');
  set finCpi(bool? value) => setField<bool>('fin_cpi', value);

  bool? get finCartaHistorico => getField<bool>('fin_carta_historico');
  set finCartaHistorico(bool? value) =>
      setField<bool>('fin_carta_historico', value);

  bool? get finRefsComerciais => getField<bool>('fin_refs_comerciais');
  set finRefsComerciais(bool? value) =>
      setField<bool>('fin_refs_comerciais', value);

  bool? get finRefBancaria => getField<bool>('fin_ref_bancaria');
  set finRefBancaria(bool? value) =>
      setField<bool>('fin_ref_bancaria', value);

  bool? get finFotosOperacao => getField<bool>('fin_fotos_operacao');
  set finFotosOperacao(bool? value) =>
      setField<bool>('fin_fotos_operacao', value);

  // Legacy payment fields
  String? get paymentType => getField<String>('payment_type');
  set paymentType(String? value) => setField<String>('payment_type', value);

  bool? get docContadora => getField<bool>('doc_contadora');
  set docContadora(bool? value) => setField<bool>('doc_contadora', value);

  bool? get docEndUser => getField<bool>('doc_end_user');
  set docEndUser(bool? value) => setField<bool>('doc_end_user', value);

  bool? get docCpi => getField<bool>('doc_cpi');
  set docCpi(bool? value) => setField<bool>('doc_cpi', value);

  bool? get docCartaHistorica => getField<bool>('doc_carta_historica');
  set docCartaHistorica(bool? value) =>
      setField<bool>('doc_carta_historica', value);

  bool? get docRefComercial => getField<bool>('doc_ref_comercial');
  set docRefComercial(bool? value) =>
      setField<bool>('doc_ref_comercial', value);

  bool? get docRefBancaria => getField<bool>('doc_ref_bancaria');
  set docRefBancaria(bool? value) =>
      setField<bool>('doc_ref_bancaria', value);

  bool? get docFotosOperacao => getField<bool>('doc_fotos_operacao');
  set docFotosOperacao(bool? value) =>
      setField<bool>('doc_fotos_operacao', value);

  // Financiamento Aprovado
  bool? get financingApproved => getField<bool>('financing_approved');
  set financingApproved(bool? value) =>
      setField<bool>('financing_approved', value);

  // Assinatura Pré-contrato
  bool? get preContractSigned => getField<bool>('pre_contract_signed');
  set preContractSigned(bool? value) =>
      setField<bool>('pre_contract_signed', value);

  // Contratar Seguro
  String? get insuranceCompany => getField<String>('insurance_company');
  set insuranceCompany(String? value) =>
      setField<String>('insurance_company', value);

  // Apólice CASCO, LUC, RETA
  bool? get insurancePolicySent => getField<bool>('insurance_policy_sent');
  set insurancePolicySent(bool? value) =>
      setField<bool>('insurance_policy_sent', value);

  // Pagamento Saldo Entrada
  String? get entryPaymentInfo => getField<String>('entry_payment_info');
  set entryPaymentInfo(String? value) =>
      setField<String>('entry_payment_info', value);

  // Assinatura Contrato Final
  bool? get finalContractSigned => getField<bool>('final_contract_signed');
  set finalContractSigned(bool? value) =>
      setField<bool>('final_contract_signed', value);

  // Despachante - Documentos (Order 18)
  bool? get despCnd => getField<bool>('desp_cnd');
  set despCnd(bool? value) => setField<bool>('desp_cnd', value);

  bool? get despInvoice => getField<bool>('desp_invoice');
  set despInvoice(bool? value) => setField<bool>('desp_invoice', value);

  bool? get despExportCertificate =>
      getField<bool>('desp_export_certificate');
  set despExportCertificate(bool? value) =>
      setField<bool>('desp_export_certificate', value);

  bool? get despBillOfSale => getField<bool>('desp_bill_of_sale');
  set despBillOfSale(bool? value) =>
      setField<bool>('desp_bill_of_sale', value);

  bool? get despTecat => getField<bool>('desp_tecat');
  set despTecat(bool? value) => setField<bool>('desp_tecat', value);

  bool? get despAvanac => getField<bool>('desp_avanac');
  set despAvanac(bool? value) => setField<bool>('desp_avanac', value);

  bool? get despGendec => getField<bool>('desp_gendec');
  set despGendec(bool? value) => setField<bool>('desp_gendec', value);

  bool? get despSpecialAirworthness =>
      getField<bool>('desp_special_airworthness');
  set despSpecialAirworthness(bool? value) =>
      setField<bool>('desp_special_airworthness', value);

  bool? get despSeguroReta => getField<bool>('desp_seguro_reta');
  set despSeguroReta(bool? value) =>
      setField<bool>('desp_seguro_reta', value);

  bool? get despBoletoReta => getField<bool>('desp_boleto_reta');
  set despBoletoReta(bool? value) =>
      setField<bool>('desp_boleto_reta', value);

  bool? get despComprovanteReta => getField<bool>('desp_comprovante_reta');
  set despComprovanteReta(bool? value) =>
      setField<bool>('desp_comprovante_reta', value);

  // Aeronave Entregue
  bool? get aircraftDelivered => getField<bool>('aircraft_delivered');
  set aircraftDelivered(bool? value) =>
      setField<bool>('aircraft_delivered', value);

  // Desembaraço Aduaneiro
  String? get customsStatus => getField<String>('customs_status');
  set customsStatus(String? value) =>
      setField<String>('customs_status', value);

  bool? get customsCnd => getField<bool>('customs_cnd');
  set customsCnd(bool? value) => setField<bool>('customs_cnd', value);

  // Documentação para Oficina
  bool? get oficInvoice => getField<bool>('ofic_invoice');
  set oficInvoice(bool? value) => setField<bool>('ofic_invoice', value);

  bool? get oficExportCertificate =>
      getField<bool>('ofic_export_certificate');
  set oficExportCertificate(bool? value) =>
      setField<bool>('ofic_export_certificate', value);

  bool? get oficBillOfSale => getField<bool>('ofic_bill_of_sale');
  set oficBillOfSale(bool? value) =>
      setField<bool>('ofic_bill_of_sale', value);

  bool? get oficTecat => getField<bool>('ofic_tecat');
  set oficTecat(bool? value) => setField<bool>('ofic_tecat', value);

  bool? get oficAadsac => getField<bool>('ofic_aadsac');
  set oficAadsac(bool? value) => setField<bool>('ofic_aadsac', value);

  bool? get oficGendec => getField<bool>('ofic_gendec');
  set oficGendec(bool? value) => setField<bool>('ofic_gendec', value);

  bool? get oficSpecialAirworthness =>
      getField<bool>('ofic_special_airworthness');
  set oficSpecialAirworthness(bool? value) =>
      setField<bool>('ofic_special_airworthness', value);

  bool? get oficSeguroReta => getField<bool>('ofic_seguro_reta');
  set oficSeguroReta(bool? value) =>
      setField<bool>('ofic_seguro_reta', value);

  bool? get oficBoletoReta => getField<bool>('ofic_boleto_reta');
  set oficBoletoReta(bool? value) =>
      setField<bool>('ofic_boleto_reta', value);

  bool? get oficComprovanteReta => getField<bool>('ofic_comprovante_reta');
  set oficComprovanteReta(bool? value) =>
      setField<bool>('ofic_comprovante_reta', value);

  bool? get oficDocsDespachante => getField<bool>('ofic_docs_despachante');
  set oficDocsDespachante(bool? value) =>
      setField<bool>('ofic_docs_despachante', value);

  bool? get oficCopiaCadernetas => getField<bool>('ofic_copia_cadernetas');
  set oficCopiaCadernetas(bool? value) =>
      setField<bool>('ofic_copia_cadernetas', value);

  bool? get oficPesoBalanceamento => getField<bool>('ofic_peso_balanceamento');
  set oficPesoBalanceamento(bool? value) =>
      setField<bool>('ofic_peso_balanceamento', value);

  bool? get oficDesregistro => getField<bool>('ofic_desregistro');
  set oficDesregistro(bool? value) =>
      setField<bool>('ofic_desregistro', value);

  bool? get oficFlightTest => getField<bool>('ofic_flight_test');
  set oficFlightTest(bool? value) =>
      setField<bool>('ofic_flight_test', value);

  bool? get oficForm337 => getField<bool>('ofic_form_337');
  set oficForm337(bool? value) => setField<bool>('ofic_form_337', value);

  bool? get oficListaComponentes => getField<bool>('ofic_lista_componentes');
  set oficListaComponentes(bool? value) =>
      setField<bool>('ofic_lista_componentes', value);

  bool? get oficListaAds => getField<bool>('ofic_lista_ads');
  set oficListaAds(bool? value) => setField<bool>('ofic_lista_ads', value);

  // Aeronave Liberada para Voo
  String? get caDocumentUrl => getField<String>('ca_document_url');
  set caDocumentUrl(String? value) =>
      setField<String>('ca_document_url', value);

  String? get cmDocumentUrl => getField<String>('cm_document_url');
  set cmDocumentUrl(String? value) =>
      setField<String>('cm_document_url', value);

  // Timestamps
  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
