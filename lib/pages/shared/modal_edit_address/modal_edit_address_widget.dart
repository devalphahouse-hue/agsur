import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'modal_edit_address_model.dart';

export 'modal_edit_address_model.dart';

class ModalEditAddressWidget extends StatefulWidget {
  const ModalEditAddressWidget({
    super.key,
    required this.addressId,
    required this.btnAction,
  });

  final String? addressId;
  final Future Function(
    String zipcode,
    String street,
    String number,
    String neighborhood,
    String city,
    String state,
    String complement,
    String addressId,
  )? btnAction;

  @override
  State<ModalEditAddressWidget> createState() => _ModalEditAddressWidgetState();
}

class _ModalEditAddressWidgetState extends State<ModalEditAddressWidget> {
  late ModalEditAddressModel _model;
  bool _busy = false;
  bool _prefilled = false;
  String? _lastCepLookup;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalEditAddressModel());
    _model.tFZipCodeFocusNode ??= FocusNode();
    _model.tFZipCodeMask = MaskTextInputFormatter(mask: '#####-###');
    _model.tFZipCodeTextController ??= TextEditingController();
    _model.tFStreetFocusNode ??= FocusNode();
    _model.tFStreetTextController ??= TextEditingController();
    _model.tFNumberFocusNode ??= FocusNode();
    _model.tFNumberTextController ??= TextEditingController();
    _model.tFNeibhFocusNode ??= FocusNode();
    _model.tFNeibhTextController ??= TextEditingController();
    _model.tFCityFocusNode ??= FocusNode();
    _model.tFCityTextController ??= TextEditingController();
    _model.tFufFocusNode ??= FocusNode();
    _model.tFufTextController ??= TextEditingController();
    _model.tFComplementFocusNode ??= FocusNode();
    _model.tFComplementTextController ??= TextEditingController();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _onCepChanged(String val) async {
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8 || _lastCepLookup == digits) return;
    _lastCepLookup = digits;
    try {
      final response = await ViaCepCall.call(cep: digits);
      if (!mounted) return;
      if (!response.succeeded) return;
      final body = response.jsonBody;
      final localidade = ViaCepCall.localidade(body);
      final uf = ViaCepCall.uf(body);
      final logradouro = (body is Map ? body['logradouro'] : null)?.toString();
      final bairro = (body is Map ? body['bairro'] : null)?.toString();
      setState(() {
        if (localidade != null && localidade.isNotEmpty) {
          _model.tFCityTextController?.text = localidade;
        }
        if (uf != null && uf.isNotEmpty) {
          _model.tFufTextController?.text = uf;
        }
        if (logradouro != null && logradouro.isNotEmpty) {
          _model.tFStreetTextController?.text = logradouro;
        }
        if (bairro != null && bairro.isNotEmpty) {
          _model.tFNeibhTextController?.text = bairro;
        }
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.btnAction?.call(
        _model.tFZipCodeTextController!.text,
        _model.tFStreetTextController!.text,
        _model.tFNumberTextController!.text,
        _model.tFNeibhTextController!.text,
        _model.tFCityTextController!.text,
        _model.tFufTextController!.text,
        _model.tFComplementTextController!.text,
        widget.addressId ?? '',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.edit_location_alt_rounded,
      title: 'Editar endereço',
      description: 'Atualize os dados do endereço cadastrado.',
      maxWidth: 720,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Salvar alterações',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
      child: FutureBuilder<List<AddressRow>>(
        future: AddressTable().querySingleRow(
          queryFn: (q) => q.eqOrNull('id', widget.addressId),
        ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 60),
                ),
              ),
            );
          }
          final row = snap.data!.isNotEmpty ? snap.data!.first : null;
          if (row != null && !_prefilled) {
            _prefilled = true;
            _model.tFZipCodeTextController!.text = row.zipcode ?? '';
            _model.tFStreetTextController!.text = row.street ?? '';
            _model.tFNumberTextController!.text = row.number ?? '';
            _model.tFNeibhTextController!.text = row.neighborhood ?? '';
            _model.tFCityTextController!.text = row.city ?? '';
            _model.tFufTextController!.text = row.state ?? '';
            _model.tFComplementTextController!.text = row.complement ?? '';
          }
          return Form(
            key: _model.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppFormField(
                  controller: _model.tFZipCodeTextController,
                  focusNode: _model.tFZipCodeFocusNode,
                  label: 'CEP',
                  placeholder: '00000-000',
                  icon: Icons.local_post_office_outlined,
                  required: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_model.tFZipCodeMask],
                  helper:
                      'Endereço, cidade e UF são preenchidos automaticamente.',
                  onChanged: _onCepChanged,
                  validator: (v) => _model.tFZipCodeTextControllerValidator
                      ?.call(context, v),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppFormField(
                        controller: _model.tFStreetTextController,
                        focusNode: _model.tFStreetFocusNode,
                        label: 'Rua',
                        placeholder: 'Logradouro',
                        icon: Icons.location_on_outlined,
                        required: true,
                        validator: (v) => _model.tFStreetTextControllerValidator
                            ?.call(context, v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: AppFormField(
                        controller: _model.tFNumberTextController,
                        focusNode: _model.tFNumberFocusNode,
                        label: 'Número',
                        placeholder: 'Nº',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppFormField(
                  controller: _model.tFNeibhTextController,
                  focusNode: _model.tFNeibhFocusNode,
                  label: 'Bairro',
                  placeholder: 'Bairro',
                  icon: Icons.location_city_outlined,
                  required: true,
                  validator: (v) =>
                      _model.tFNeibhTextControllerValidator?.call(context, v),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppFormField(
                        controller: _model.tFCityTextController,
                        focusNode: _model.tFCityFocusNode,
                        label: 'Cidade',
                        placeholder: 'Cidade',
                        icon: Icons.location_city_rounded,
                        required: true,
                        validator: (v) => _model.tFCityTextControllerValidator
                            ?.call(context, v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 88,
                      child: AppFormField(
                        controller: _model.tFufTextController,
                        focusNode: _model.tFufFocusNode,
                        label: 'UF',
                        placeholder: 'UF',
                        required: true,
                        validator: (v) => _model.tFufTextControllerValidator
                            ?.call(context, v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppFormField(
                  controller: _model.tFComplementTextController,
                  focusNode: _model.tFComplementFocusNode,
                  label: 'Complemento',
                  placeholder: 'Apto, sala, bloco, etc.',
                  icon: Icons.notes_rounded,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
