import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/edit_email_dialog/edit_email_dialog.dart';
import 'modal_register_company_model.dart';

export 'modal_register_company_model.dart';

class ModalRegisterCompanyWidget extends StatefulWidget {
  const ModalRegisterCompanyWidget({
    super.key,
    required this.leadId,
    required this.btnActions,
    this.onSaveEmail,
  });

  final String? leadId;
  final Future Function(
    String companyName,
    String companyCnpj,
    String companyPhone,
    String leadId,
    String? companyCpf,
    int? typeDoc,
    String? stateRegistration,
  )? btnActions;

  /// E-mail do lead exibido e editável na própria modal (pré-preenchido a
  /// partir do cadastro do lead). Se alterado, roda ANTES do [btnActions];
  /// retornar false mantém a modal aberta.
  final Future<bool> Function(String newEmail)? onSaveEmail;

  @override
  State<ModalRegisterCompanyWidget> createState() =>
      _ModalRegisterCompanyWidgetState();
}

class _ModalRegisterCompanyWidgetState
    extends State<ModalRegisterCompanyWidget> {
  late ModalRegisterCompanyModel _model;
  bool _busy = false;
  TextEditingController? _emailController;
  String _emailOriginal = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalRegisterCompanyModel());
    _model.tFCompanyNameTextController ??= TextEditingController();
    _model.tFCompanyNameFocusNode ??= FocusNode();
    _model.tFPhoneCompanyTextController ??= TextEditingController();
    _model.tFPhoneCompanyFocusNode ??= FocusNode();
    _model.tFPhoneCompanyMask =
        MaskTextInputFormatter(mask: '(##) #####.####');
    _model.tFCnpjCompanyTextController ??= TextEditingController();
    _model.tFCnpjCompanyFocusNode ??= FocusNode();
    _model.tFCnpjCompanyMask =
        MaskTextInputFormatter(mask: '##.###.###/####-##');
    _model.tFCpfCompanyTextController ??= TextEditingController();
    _model.tFCpfCompanyFocusNode ??= FocusNode();
    _model.tFCpfCompanyMask = MaskTextInputFormatter(mask: '###.###.###-##');
    _model.tFIncricCompanyTextController ??= TextEditingController();
    _model.tFIncricCompanyFocusNode ??= FocusNode();
    if (widget.onSaveEmail != null) {
      _emailController = TextEditingController();
    }

    // Pré-preenche com o que o lead já informou no cadastro (empresa,
    // telefone, CPF, e-mail) — evita redigitar dados que o funil já tem. Os
    // campos continuam editáveis; quem preencher por cima prevalece.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final leadId = widget.leadId ?? '';
      if (leadId.isEmpty) return;
      final rows = await LeadsTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', leadId),
      );
      if (!mounted) return;
      final lead = rows.firstOrNull;
      if (lead == null) return;
      if (_model.tFCompanyNameTextController!.text.isEmpty &&
          (lead.companyName ?? '').isNotEmpty) {
        _model.tFCompanyNameTextController!.text = lead.companyName!;
      }
      if (_model.tFPhoneCompanyTextController!.text.isEmpty &&
          lead.phone.isNotEmpty) {
        _applyMaskedText(_model.tFPhoneCompanyTextController!,
            _model.tFPhoneCompanyMask, lead.phone);
      }
      if (_model.tFCpfCompanyTextController!.text.isEmpty &&
          lead.cpf.isNotEmpty) {
        _applyMaskedText(_model.tFCpfCompanyTextController!,
            _model.tFCpfCompanyMask, lead.cpf);
      }
      if (_emailController != null && _emailController!.text.isEmpty) {
        _emailOriginal = lead.email.trim();
        _emailController!.text = _emailOriginal;
      }
      setState(() {});
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
      // E-mail primeiro: se a persistência falhar, a modal fica aberta e a
      // empresa não é cadastrada pela metade.
      if (widget.onSaveEmail != null && _emailController != null) {
        final newEmail = _emailController!.text.trim().toLowerCase();
        if (newEmail != _emailOriginal.toLowerCase()) {
          final okEmail = await widget.onSaveEmail!(newEmail);
          if (!okEmail) return;
        }
      }
      await widget.btnActions?.call(
        _model.tFCompanyNameTextController!.text,
        _model.tFCnpjCompanyTextController!.text,
        _model.tFPhoneCompanyTextController!.text,
        widget.leadId ?? '',
        _model.tFCpfCompanyTextController!.text,
        _model.docType,
        _model.tFIncricCompanyTextController!.text,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPj = _model.docType == 1;
    return AppModal(
      icon: Icons.apartment_rounded,
      title: 'Cadastrar empresa',
      description:
          'Vincule uma empresa a este lead — escolha pessoa jurídica ou física.',
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
            label: 'Cadastrar empresa',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
      child: Form(
        key: _model.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DocTypeSelector(
              docType: _model.docType,
              onChanged: (t) => setState(() => _model.docType = t),
            ),
            const SizedBox(height: 16),
            AppFormField(
              controller: _model.tFCompanyNameTextController,
              focusNode: _model.tFCompanyNameFocusNode,
              label: isPj ? 'Razão social' : 'Nome',
              placeholder:
                  isPj ? 'Razão social da empresa' : 'Nome completo',
              icon: isPj
                  ? Icons.business_rounded
                  : Icons.person_outline_rounded,
              required: true,
              validator: (v) => _model.tFCompanyNameTextControllerValidator
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
                    inputFormatters: [
                      isPj
                          ? _model.tFCnpjCompanyMask
                          : _model.tFCpfCompanyMask,
                    ],
                    validator: isPj
                        ? (v) => _model.tFCnpjCompanyTextControllerValidator
                            ?.call(context, v)
                        : null,
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
              keyboardType: TextInputType.number,
              // IE não tem formato único (varia por UF: RJ 8, SP 12, MG 13...)
              // e esta modal não tem UF — então só dígitos, sem pontuação.
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
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
  const _DocTypeSelector({required this.docType, required this.onChanged});

  final int docType;
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
              active: docType == 1,
              onTap: () => onChanged(1),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _DocTypeChip(
              icon: Icons.person_outline_rounded,
              label: 'Pessoa Física',
              active: docType == 2,
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
