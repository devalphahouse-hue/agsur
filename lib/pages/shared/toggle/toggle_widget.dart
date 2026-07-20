import '/backend/supabase/supabase.dart';
import '/security/write_guard.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'toggle_model.dart';
export 'toggle_model.dart';

class ToggleWidget extends StatefulWidget {
  const ToggleWidget({
    super.key,
    this.parameter1,
    this.parameter2,
  });

  final bool? parameter1;
  final String? parameter2;

  @override
  State<ToggleWidget> createState() => _ToggleWidgetState();
}

class _ToggleWidgetState extends State<ToggleWidget> {
  late ToggleModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ToggleModel());

    _model.switchValue = widget!.parameter1! ? true : false;
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: _model.switchValue!,
      onChanged: (newValue) async {
        safeSetState(() => _model.switchValue = newValue!);
        if (newValue!) {
          // O switch já virou na tela antes da escrita. Se a RLS bloquear
          // (2xx com 0 linhas), reverte o visual — senão a UI mostra um
          // estado que o banco não tem.
          final ok = await guardWrite(
            context,
            () => UsersTable().update(
              data: {
                'is_active': false,
              },
              matchingRows: (rows) => rows.eqOrNull(
                'id',
                widget!.parameter2,
              ),
              returnRows: true,
            ),
          );
          if (!ok) {
            safeSetState(() => _model.switchValue = !newValue);
            return;
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Inativo',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
              ),
              duration: Duration(milliseconds: 4000),
              backgroundColor: FlutterFlowTheme.of(context).primary,
            ),
          );
        } else {
          // O switch já virou na tela antes da escrita. Se a RLS bloquear
          // (2xx com 0 linhas), reverte o visual — senão a UI mostra um
          // estado que o banco não tem.
          final ok = await guardWrite(
            context,
            () => UsersTable().update(
              data: {
                'is_active': true,
              },
              matchingRows: (rows) => rows.eqOrNull(
                'id',
                widget!.parameter2,
              ),
              returnRows: true,
            ),
          );
          if (!ok) {
            safeSetState(() => _model.switchValue = !newValue);
            return;
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ativo',
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
              ),
              duration: Duration(milliseconds: 4000),
              backgroundColor: FlutterFlowTheme.of(context).primary,
            ),
          );
        }
      },
      activeColor: FlutterFlowTheme.of(context).primary,
      activeTrackColor: Color(0xFF404040),
      inactiveTrackColor: Color(0xFF404040),
      inactiveThumbColor: Color(0x72FFFFFF),
    );
  }
}
