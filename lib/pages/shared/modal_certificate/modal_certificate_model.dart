import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'modal_certificate_widget.dart' show ModalCertificateWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ModalCertificateModel extends FlutterFlowModel<ModalCertificateWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey2 = GlobalKey<FormState>();
  final formKey1 = GlobalKey<FormState>();
  // State field(s) for TFCertificateName widget.
  FocusNode? tFCertificateNameFocusNode;
  TextEditingController? tFCertificateNameTextController;
  String? Function(BuildContext, String?)?
      tFCertificateNameTextControllerValidator;
  // State field(s) for TFEditCertificateName widget.
  FocusNode? tFEditCertificateNameFocusNode;
  TextEditingController? tFEditCertificateNameTextController;
  String? Function(BuildContext, String?)?
      tFEditCertificateNameTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tFCertificateNameFocusNode?.dispose();
    tFCertificateNameTextController?.dispose();

    tFEditCertificateNameFocusNode?.dispose();
    tFEditCertificateNameTextController?.dispose();
  }
}
