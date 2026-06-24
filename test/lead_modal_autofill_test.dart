import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import 'package:a_g_sur_back_office/core_ui/app_form_field.dart';

/// Replica fiel da estrutura da modal de lead: City + UF em Row/Expanded,
/// e o autofill setando AMBOS os controllers dentro de um setState do pai
/// (igual ao _onCepChanged). Depois valida igual ao _submit.
class _MiniModal extends StatefulWidget {
  const _MiniModal({required this.formKey, required this.onReady});
  final GlobalKey<FormState> formKey;
  final void Function(VoidCallback autofill) onReady;

  @override
  State<_MiniModal> createState() => _MiniModalState();
}

class _MiniModalState extends State<_MiniModal> {
  final cityCtrl = TextEditingController();
  final ufCtrl = TextEditingController();
  final ufMask = MaskTextInputFormatter(mask: 'AA');

  void _autofill() {
    setState(() {
      cityCtrl.text = 'Taubaté';
      ufCtrl.text = 'SP';
    });
  }

  @override
  void initState() {
    super.initState();
    widget.onReady(_autofill);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: widget.formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppFormField(
                  controller: cityCtrl,
                  label: 'Cidade',
                  required: true,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 88,
                child: AppFormField(
                  controller: ufCtrl,
                  label: 'UF',
                  required: true,
                  inputFormatters: <TextInputFormatter>[ufMask],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obrigatório';
                    if (v.trim().length != 2) return 'UF';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('modal de lead: autofill em setState do pai -> validate() passa',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    late VoidCallback autofill;

    await tester.pumpWidget(
      _MiniModal(formKey: formKey, onReady: (fn) => autofill = fn),
    );

    // Usuário tenta salvar vazio -> vermelho nos dois.
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsOneWidget);
    expect(find.text('Obrigatório'), findsOneWidget);

    // CEP dispara autofill (setState do pai seta os dois controllers).
    autofill();
    await tester.pump();

    // Erros devem sumir sozinhos (fluxo real, sem re-validate).
    expect(find.text('Campo obrigatório'), findsNothing,
        reason: 'cidade deveria limpar');
    expect(find.text('Obrigatório'), findsNothing,
        reason: 'uf deveria limpar');

    // E o submit deve validar.
    expect(formKey.currentState!.validate(), isTrue,
        reason: 'após autofill, validate() do submit deveria passar');
  });
}
