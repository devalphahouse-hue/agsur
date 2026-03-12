import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import 'modal_register_note_widget.dart' show ModalRegisterNoteWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ModalRegisterNoteModel extends FlutterFlowModel<ModalRegisterNoteWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for TFNotes widget.
  FocusNode? tFNotesFocusNode;
  TextEditingController? tFNotesTextController;
  String? Function(BuildContext, String?)? tFNotesTextControllerValidator;
  String? _tFNotesTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Campo obrigatório';
    }

    return null;
  }

  @override
  void initState(BuildContext context) {
    tFNotesTextControllerValidator = _tFNotesTextControllerValidator;
  }

  @override
  void dispose() {
    tFNotesFocusNode?.dispose();
    tFNotesTextController?.dispose();
  }
}
