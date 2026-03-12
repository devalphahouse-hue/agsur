import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'modal_register_mechanic_shop_widget.dart'
    show ModalRegisterMechanicShopWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ModalRegisterMechanicShopModel
    extends FlutterFlowModel<ModalRegisterMechanicShopWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TFName widget.
  FocusNode? tFNameFocusNode;
  TextEditingController? tFNameTextController;
  String? Function(BuildContext, String?)? tFNameTextControllerValidator;
  String? _tFNameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFCpf widget.
  FocusNode? tFCpfFocusNode;
  TextEditingController? tFCpfTextController;
  String? Function(BuildContext, String?)? tFCpfTextControllerValidator;
  String? _tFCpfTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFEmail widget.
  FocusNode? tFEmailFocusNode;
  TextEditingController? tFEmailTextController;
  String? Function(BuildContext, String?)? tFEmailTextControllerValidator;
  String? _tFEmailTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFPhone widget.
  FocusNode? tFPhoneFocusNode;
  TextEditingController? tFPhoneTextController;
  String? Function(BuildContext, String?)? tFPhoneTextControllerValidator;
  String? _tFPhoneTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFCity widget.
  FocusNode? tFCityFocusNode;
  TextEditingController? tFCityTextController;
  String? Function(BuildContext, String?)? tFCityTextControllerValidator;
  String? _tFCityTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFZipCode widget.
  FocusNode? tFZipCodeFocusNode;
  TextEditingController? tFZipCodeTextController;
  String? Function(BuildContext, String?)? tFZipCodeTextControllerValidator;
  String? _tFZipCodeTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFOwner widget.
  FocusNode? tFOwnerFocusNode;
  TextEditingController? tFOwnerTextController;
  String? Function(BuildContext, String?)? tFOwnerTextControllerValidator;
  String? _tFOwnerTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  // State field(s) for TFPasswordUser widget.
  FocusNode? tFPasswordUserFocusNode;
  TextEditingController? tFPasswordUserTextController;
  late bool tFPasswordUserVisibility;
  String? Function(BuildContext, String?)?
      tFPasswordUserTextControllerValidator;
  String? _tFPasswordUserTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    if (val.length < 6) {
      return 'A senha deve conter o mínimo de 6 caracteres';
    }

    return null;
  }

  // Stores action output result for [Validate Form] action in BTNRegisterLead widget.
  bool? formMechanic;
  // Stores action output result for [Backend Call - API (Create account another user)] action in BTNRegisterLead widget.
  ApiCallResponse? createAuthUserMechanic;
  // Stores action output result for [Backend Call - Insert Row] action in BTNRegisterLead widget.
  UsersRow? createUserMechanic;

  @override
  void initState(BuildContext context) {
    tFNameTextControllerValidator = _tFNameTextControllerValidator;
    tFCpfTextControllerValidator = _tFCpfTextControllerValidator;
    tFEmailTextControllerValidator = _tFEmailTextControllerValidator;
    tFPhoneTextControllerValidator = _tFPhoneTextControllerValidator;
    tFCityTextControllerValidator = _tFCityTextControllerValidator;
    tFZipCodeTextControllerValidator = _tFZipCodeTextControllerValidator;
    tFOwnerTextControllerValidator = _tFOwnerTextControllerValidator;
    tFPasswordUserVisibility = false;
    tFPasswordUserTextControllerValidator =
        _tFPasswordUserTextControllerValidator;
  }

  @override
  void dispose() {
    tFNameFocusNode?.dispose();
    tFNameTextController?.dispose();

    tFCpfFocusNode?.dispose();
    tFCpfTextController?.dispose();

    tFEmailFocusNode?.dispose();
    tFEmailTextController?.dispose();

    tFPhoneFocusNode?.dispose();
    tFPhoneTextController?.dispose();

    tFCityFocusNode?.dispose();
    tFCityTextController?.dispose();

    tFZipCodeFocusNode?.dispose();
    tFZipCodeTextController?.dispose();

    tFOwnerFocusNode?.dispose();
    tFOwnerTextController?.dispose();

    tFPasswordUserFocusNode?.dispose();
    tFPasswordUserTextController?.dispose();
  }
}
