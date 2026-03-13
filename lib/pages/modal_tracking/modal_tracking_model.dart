import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:math';
import 'dart:ui';
import 'modal_tracking_widget.dart' show ModalTrackingWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ModalTrackingModel extends FlutterFlowModel<ModalTrackingWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey8 = GlobalKey<FormState>();
  final formKey3 = GlobalKey<FormState>();
  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  final formKey5 = GlobalKey<FormState>();
  final formKey7 = GlobalKey<FormState>();
  final formKey6 = GlobalKey<FormState>();
  final formKey4 = GlobalKey<FormState>();
  // State field(s) for TFLink1 widget.
  FocusNode? tFLink1FocusNode;
  TextEditingController? tFLink1TextController;
  String? Function(BuildContext, String?)? tFLink1TextControllerValidator;
  // State field(s) for TFLink2 widget.
  FocusNode? tFLink2FocusNode;
  TextEditingController? tFLink2TextController;
  String? Function(BuildContext, String?)? tFLink2TextControllerValidator;
  // State field(s) for TFDescTecnica widget.
  FocusNode? tFDescTecnicaFocusNode;
  TextEditingController? tFDescTecnicaTextController;
  String? Function(BuildContext, String?)? tFDescTecnicaTextControllerValidator;
  // State field(s) for TFStripeColor widget.
  FocusNode? tFStripeColorFocusNode;
  TextEditingController? tFStripeColorTextController;
  String? Function(BuildContext, String?)? tFStripeColorTextControllerValidator;
  // State field(s) for TFFilter widget.
  FocusNode? tFFilterFocusNode;
  TextEditingController? tFFilterTextController;
  String? Function(BuildContext, String?)? tFFilterTextControllerValidator;
  // State field(s) for TFPanel widget.
  FocusNode? tFPanelFocusNode;
  TextEditingController? tFPanelTextController;
  String? Function(BuildContext, String?)? tFPanelTextControllerValidator;
  // State field(s) for TXTinvoice widget.
  FocusNode? tXTinvoiceFocusNode;
  TextEditingController? tXTinvoiceTextController;
  String? Function(BuildContext, String?)? tXTinvoiceTextControllerValidator;
  // State field(s) for TXTipoEquipamento widget.
  FocusNode? tXTipoEquipamentoFocusNode;
  TextEditingController? tXTipoEquipamentoTextController;
  String? Function(BuildContext, String?)?
      tXTipoEquipamentoTextControllerValidator;
  // State field(s) for TXTNomeDespachante widget.
  FocusNode? tXTNomeDespachanteFocusNode;
  TextEditingController? tXTNomeDespachanteTextController;
  String? Function(BuildContext, String?)?
      tXTNomeDespachanteTextControllerValidator;
  // State field(s) for TXTPrefixo widget.
  FocusNode? tXTPrefixoFocusNode;
  TextEditingController? tXTPrefixoTextController;
  String? Function(BuildContext, String?)? tXTPrefixoTextControllerValidator;
  // State field(s) for TXTMarca widget.
  FocusNode? tXTMarcaFocusNode;
  TextEditingController? tXTMarcaTextController;
  String? Function(BuildContext, String?)? tXTMarcaTextControllerValidator;
  bool isDataUploading_uploadDataPh0 = false;
  FFUploadedFile uploadedLocalFile_uploadDataPh0 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataPh0 = '';

  // State field(s) for order 6 toggle switches.
  bool fiscalBenefitActive = true;
  bool hasRadar = false;

  // State field(s) for boolean confirmation orders.
  bool reservationPaid = false;
  bool fivePercentPaid = false;
  bool financingApproved = false;
  bool preContractSigned = false;
  bool insurancePolicySent = false;
  bool finalContractSigned = false;

  // State field(s) for order 16 - Documentação para Oficina.
  bool oficInvoice = false;
  bool oficExportCertificate = false;
  bool oficBillOfSale = false;
  bool oficTecat = false;
  bool oficAadsac = false;
  bool oficGendec = false;
  bool oficSpecialAirworthness = false;
  bool oficSeguroReta = false;
  bool oficBoletoReta = false;
  bool oficComprovanteReta = false;
  bool oficDocsDespachante = false;
  bool oficCopiaCadernetas = false;
  bool oficPesoBalanceamento = false;
  bool oficDesregistro = false;
  bool oficFlightTest = false;
  bool oficForm337 = false;
  bool oficListaComponentes = false;
  bool oficListaAds = false;

  // State field(s) for order 18 - Documentação do Despachante.
  bool despCnd = false;
  bool despInvoice = false;
  bool despExportCertificate = false;
  bool despBillOfSale = false;
  bool despTecat = false;
  bool despAvanac = false;
  bool despGendec = false;
  bool despSpecialAirworthness = false;
  bool despSeguroReta = false;
  bool despBoletoReta = false;
  bool despComprovanteReta = false;

  // State field(s) for order 9 - Formalização de Pagamento.
  String? paymentMethod; // 'vista' or 'financiamento'
  bool finDoc = false;
  bool finContadora = false;
  bool finEndUser = false;
  bool finCpi = false;
  bool finCartaHistorico = false;
  bool finRefsComerciais = false;
  bool finRefBancaria = false;
  bool finFotosOperacao = false;

  // State field(s) for order 19 - Desembaraço Aduaneiro.
  String? customsStatus;
  bool customsCnd = false;

  // State field(s) for order 20 - Liberação para Voo.
  bool isDataUploading_caDoc = false;
  FFUploadedFile uploadedLocalFile_caDoc =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_caDoc = '';

  bool isDataUploading_cmDoc = false;
  FFUploadedFile uploadedLocalFile_cmDoc =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_cmDoc = '';

  // Existing tracking_details row ID (null = no row yet, needs insert)
  String? existingDetailsId;
  bool detailsLoaded = false;

  // State field(s) for DropDown widget.
  int? dropDownValue;
  FormFieldController<int>? dropDownValueController;
  // State field(s) for TXTSeguradora widget.
  FocusNode? tXTSeguradoraFocusNode;
  TextEditingController? tXTSeguradoraTextController;
  String? Function(BuildContext, String?)? tXTSeguradoraTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFLink1FocusNode?.dispose();
    tFLink1TextController?.dispose();

    tFLink2FocusNode?.dispose();
    tFLink2TextController?.dispose();

    tFDescTecnicaFocusNode?.dispose();
    tFDescTecnicaTextController?.dispose();

    tFStripeColorFocusNode?.dispose();
    tFStripeColorTextController?.dispose();

    tFFilterFocusNode?.dispose();
    tFFilterTextController?.dispose();

    tFPanelFocusNode?.dispose();
    tFPanelTextController?.dispose();

    tXTinvoiceFocusNode?.dispose();
    tXTinvoiceTextController?.dispose();

    tXTipoEquipamentoFocusNode?.dispose();
    tXTipoEquipamentoTextController?.dispose();

    tXTNomeDespachanteFocusNode?.dispose();
    tXTNomeDespachanteTextController?.dispose();

    tXTPrefixoFocusNode?.dispose();
    tXTPrefixoTextController?.dispose();

    tXTMarcaFocusNode?.dispose();
    tXTMarcaTextController?.dispose();

    tXTSeguradoraFocusNode?.dispose();
    tXTSeguradoraTextController?.dispose();

    // CA/CM doc uploads don't need dispose
  }
}
