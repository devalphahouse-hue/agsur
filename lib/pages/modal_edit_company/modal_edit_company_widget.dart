import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/edit_email_dialog/edit_email_dialog.dart';
import 'modal_edit_company_model.dart';

export 'modal_edit_company_model.dart';

class ModalEditCompanyWidget extends StatefulWidget {
  const ModalEditCompanyWidget({
    super.key,
    required this.companyId,
    required this.btnActions,
    this.emailInitial,
    this.onSaveEmail,
  });

  final String? companyId;
  final Future Function(
    String companyName,
    String companyCnpj,
    String companyPhone,
    String companyId,
    String? cpf,
    int? typeDoc,
    String? stateRegistration,
  )? btnActions;

  /// E-mail do lead/cliente exibido e editável na própria modal.
  /// Quando [onSaveEmail] é fornecido, o campo aparece pré-preenchido com
  /// [emailInitial]; se alterado, [onSaveEmail] roda ANTES do [btnActions]
  /// (retornar false mantém a modal aberta — o erro é sinalizado por quem
  /// persiste: guardWrite/RPC/snackbar).
  final String? emailInitial;
  final Future<bool> Function(String newEmail)? onSaveEmail;

  @override
  State<ModalEditCompanyWidget> createState() => _ModalEditCompanyWidgetState();
}

class _ModalEditCompanyWidgetState extends State<ModalEditCompanyWidget> {
  late ModalEditCompanyModel _model;
  bool _busy = false;
  bool _loading = true;
  TextEditingController? _emailController;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalEditCompanyModel());
    if (widget.onSaveEmail != null) {
      _emailController =
          TextEditingController(text: (widget.emailInitial ?? '').trim());
    }
    _model.tFCompanyNameTextController ??= TextEditingController();
    _model.tFCompanyNameFocusNode ??= FocusNode();
    _model.tFPhoneCompanyTextController ??= TextEditingController();
    _model.tFPhoneCompanyFocusNode ??= FocusNode();
    _model.tFPhoneCompanyMask =
        MaskTextInputFormatter(mask: '(##) #####.####');
    _model.tFCpfCompanyTextController ??= TextEditingController();
    _model.tFCpfCompanyFocusNode ??= FocusNode();
    _model.tFCpfCompanyMask = MaskTextInputFormatter(mask: '###.###.###-##');
    _model.tFCnpjCompanyTextController ??= TextEditingController();
    _model.tFCnpjCompanyFocusNode ??= FocusNode();
    _model.tFCnpjCompanyMask =
        MaskTextInputFormatter(mask: '##.###.###/####-##');
    _model.tFIncricCompanyTextController ??= TextEditingController();
    _model.tFIncricCompanyFocusNode ??= FocusNode();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.getCompany = await CompanyTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', widget.companyId),
      );
      if (!mounted) return;
      final row = _model.getCompany?.firstOrNull;
      if (row != null) {
        _model.typeDoc = row.typeDoc == '1' ? 1 : 2;
        _model.tFCompanyNameTextController!.text = row.companyName;
        _applyMaskedText(_model.tFPhoneCompanyTextController!,
            _model.tFPhoneCompanyMask, row.phone ?? '');
        _applyMaskedText(_model.tFCpfCompanyTextController!,
            _model.tFCpfCompanyMask, row.cpf ?? '');
        _applyMaskedText(_model.tFCnpjCompanyTextController!,
            _model.tFCnpjCompanyMask, row.cnpj ?? '');
        _model.tFIncricCompanyTextController!.text =
            row.stateRegistration ?? '';
      }
      setState(() => _loading = false);
    });
  }

  void _applyMaskedText(TextEditingController c, MaskTextInputFormatter mask,
      String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    c.text = mask.maskText(digits);
    mask.updateMask(newValue: TextEditingValue(text: c.text));
  }

  @override
  void dispose() {
    _emailController?.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // E-mail primeiro: se a persistência dele falhar (RLS/RPC), a modal
      // fica aberta e nada da empresa é salvo pela metade.
      if (widget.onSaveEmail != null && _emailController != null) {
        final newEmail = _emailController!.text.trim().toLowerCase();
        final oldEmail = (widget.emailInitial ?? '').trim().toLowerCase();
        if (newEmail != oldEmail) {
          final okEmail = await widget.onSaveEmail!(newEmail);
          if (!okEmail) return;
        }
      }
      await widget.btnActions?.call(
        _model.tFCompanyNameTextController!.text,
        _model.tFCnpjCompanyTextController!.text,
        _model.tFPhoneCompanyTextController!.text,
        widget.companyId ?? '',
        _model.tFCpfCompanyTextController!.text,
        _model.typeDoc,
        _model.tFIncricCompanyTextController!.text,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPj = _model.typeDoc == 1;
    return AppModal(
      icon: Icons.edit_rounded,
      title: 'Editar empresa',
      description: 'Atualize as informações da empresa.',
      maxWidth: 700,
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
      child: _loading
          ? Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 60),
                ),
              ),
            )
          : Form(
              key: _model.formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DocTypeSelector(
                    typeDoc: _model.typeDoc,
                    onChanged: (t) => setState(() => _model.typeDoc = t),
                  ),
                  const SizedBox(height: 16),
                  AppFormField(
                    controller: _model.tFCompanyNameTextController,
                    focusNode: _model.tFCompanyNameFocusNode,
                    label: isPj ? 'Razão social' : 'Nome',
                    placeholder: isPj
                        ? 'Razão social da empresa'
                        : 'Nome completo',
                    icon: isPj
                        ? Icons.business_rounded
                        : Icons.person_outline_rounded,
                    required: true,
                    validator: (v) => _model
                        .tFCompanyNameTextControllerValidator
                        ?.call(context, v),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppFormField(
                          controller: isPj
                              ? _model.tFCnpjCompanyTextController
                              : _model.tFCpfCompanyTextController,
                          focusNode: isPj
                              ? _model.tFCnpjCompanyFocusNode
                              : _model.tFCpfCompanyFocusNode,
                          label: isPj ? 'CNPJ' : 'CPF',
                          placeholder: isPj
                              ? '00.000.000/0000-00'
                              : '000.000.000-00',
                          icon: Icons.badge_outlined,
                          required: isPj,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            isPj
                                ? _model.tFCnpjCompanyMask
                                : _model.tFCpfCompanyMask,
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppFormField(
                          controller: _model.tFPhoneCompanyTextController,
                          focusNode: _model.tFPhoneCompanyFocusNode,
                          label: 'Telefone',
                          placeholder: '(00) 00000.0000',
                          icon: Icons.phone_iphone_rounded,
                          required: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [_model.tFPhoneCompanyMask],
                          validator: (v) => _model
                              .tFPhoneCompanyTextControllerValidator
                              ?.call(context, v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppFormField(
                    controller: _model.tFIncricCompanyTextController,
                    focusNode: _model.tFIncricCompanyFocusNode,
                    label: 'Inscrição estadual',
                    placeholder: 'Opcional',
                    icon: Icons.confirmation_number_outlined,
                  ),
                  if (widget.onSaveEmail != null) ...[
                    const SizedBox(height: 14),
                    AppFormField(
                      controller: _emailController,
                      label: 'E-mail do cliente',
                      placeholder: 'email@exemplo.com',
                      icon: Icons.mail_outline_rounded,
                      required: true,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final email = (v ?? '').trim();
                        if (email.isEmpty) return 'Informe o e-mail.';
                        if (!isValidEmailFormat(email)) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DocTypeSelector extends StatelessWidget {
  const _DocTypeSelector({required this.typeDoc, required this.onChanged});

  final int typeDoc;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DocTypeChip(
              icon: Icons.business_rounded,
              label: 'Pessoa Jurídica',
              active: typeDoc == 1,
              onTap: () => onChanged(1),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _DocTypeChip(
              icon: Icons.person_outline_rounded,
              label: 'Pessoa Física',
              active: typeDoc == 2,
              onTap: () => onChanged(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocTypeChip extends StatefulWidget {
  const _DocTypeChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_DocTypeChip> createState() => _DocTypeChipState();
}

class _DocTypeChipState extends State<_DocTypeChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.active
                ? const Color(0x33C2D51C)
                : _hover
                    ? const Color(0x14C2D51C)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: widget.active
                  ? const Color(0x88C2D51C)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.active
                    ? const Color(0xFFC2D51C)
                    : const Color(0xCCFFFFFF),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight:
                      widget.active ? FontWeight.w700 : FontWeight.w500,
                  color: widget.active
                      ? const Color(0xFFC2D51C)
                      : const Color(0xCCFFFFFF),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
