import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/instant_timer.dart';
import 'custom_snac_bar_widget.dart' show CustomSnacBarWidget;
import 'package:flutter/material.dart';

class CustomSnacBarModel extends FlutterFlowModel<CustomSnacBarWidget> {
  ///  Local state fields for this component.

  double? containerWidght = 100.0;

  ///  State fields for stateful widgets in this component.

  InstantTimer? instantTimer;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    instantTimer?.cancel();
  }
}
