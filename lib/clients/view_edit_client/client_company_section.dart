import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';

/// Seção "Dados da empresa" da tela do cliente: razão social, CNPJ/CPF e
/// **inscrição estadual**.
///
/// A IE já existia no banco (`company.state_registration`) e já saía na
/// minuta, mas não aparecia em lugar nenhum da tela do cliente — reclamação da
/// reunião de 2026-09-22. Somente leitura: a empresa é editada nas modais de
/// empresa da proposta/contrato, que é onde o funil já escreve.
///
/// Widget próprio, fora do código gerado pelo FlutterFlow.
class ClientCompanySection extends StatefulWidget {
  const ClientCompanySection({super.key, required this.leadId});

  final String leadId;

  @override
  State<ClientCompanySection> createState() => _ClientCompanySectionState();
}

class _ClientCompanySectionState extends State<ClientCompanySection> {
  CompanyRow? _company;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await CompanyTable().queryRows(
        queryFn: (q) => q.eqOrNull('lead_id', widget.leadId),
      );
      if (!mounted) return;
      setState(() {
        _company = rows.firstOrNull;
        _loading = false;
      });
    } catch (e, st) {
      // Falha de leitura não derruba a tela do cliente.
      Sentry.captureException(e,
          stackTrace: st,
          withScope: (s) => s.setTag('acao', 'cliente.empresa_load'));
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cliente sem empresa cadastrada: a seção não aparece (o fluxo permite
    // proposta sem empresa).
    if (!_loading && _company == null) return const SizedBox.shrink();
    final c = _company;
    final isCnpj = (c?.typeDoc ?? '').toLowerCase().contains('cnpj');
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF404040),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(36.0, 28.0, 36.0, 36.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dados da empresa',
                style: GoogleFonts.roboto(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const Divider(thickness: 2.0, color: Color(0x74FFFFFF)),
              const SizedBox(height: 12),
              if (_loading)
                AppSkeleton.box(height: 48)
              else
                ResponsiveRow(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Field('Razão social', c!.companyName),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(isCnpj ? 'CNPJ' : 'CPF',
                          isCnpj ? c.cnpj : c.cpf),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field('Inscrição estadual', c.stateRegistration),
                    ),
                  ],
                ),
              if (!_loading) ...[
                const SizedBox(height: 10),
                Text(
                  'Editado na proposta ou no contrato, em "Dados Empresariais".',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0x99FFFFFF),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final v = (value ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label /',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xCCFFFFFF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          v.isEmpty ? 'Não cadastrado' : v,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: v.isEmpty ? const Color(0x80FFFFFF) : Colors.white,
          ),
        ),
      ],
    );
  }
}
