import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/pages/shared/warming_air_craft_photo/warming_air_craft_photo_widget.dart';
import '/pages/shared/warming_m_pecas/warming_m_pecas_widget.dart';
import '/pages/shared/warming_m_proprietario/warming_m_proprietario_widget.dart';
import '/pages/shared/warming_m_voo/warming_m_voo_widget.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime_type/mime_type.dart' show mime;
import 'package:google_fonts/google_fonts.dart';
import '/core_ui/core_ui.dart';
import 'create_aircraft_model.dart';
export 'create_aircraft_model.dart';

class CreateAircraftWidget extends StatefulWidget {
  const CreateAircraftWidget({super.key, this.aircraftId});

  /// Quando informado, a tela abre em modo edição: carrega o modelo,
  /// pré-preenche os campos e o salvar passa a ATUALIZAR (em vez de inserir).
  final String? aircraftId;

  static String routeName = 'CreateAircraft';
  static String routePath = '/createAircraft';

  @override
  State<CreateAircraftWidget> createState() => _CreateAircraftWidgetState();
}

class _CreateAircraftWidgetState extends State<CreateAircraftWidget> {
  late CreateAircraftModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _submitting = false;

  // ── Modo edição ──────────────────────────────────────────────────
  bool get _isEdit => widget.aircraftId != null;
  bool _loadingForEdit = false;
  // Ids dos manuais existentes (para UPDATE em vez de INSERT na edição).
  String? _oemManualId;
  String? _vooManualId;
  String? _pecasManualId;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateAircraftModel());

    _model.tFAircraftNameTextController ??= TextEditingController();
    _model.tFAircraftNameFocusNode ??= FocusNode();

    _model.tFPriceTextController ??= TextEditingController();
    _model.tFPriceFocusNode ??= FocusNode();

    _model.tFAircraftYearTextController ??= TextEditingController();
    _model.tFAircraftYearFocusNode ??= FocusNode();

    _model.tFAircraftHopperTextController ??= TextEditingController();
    _model.tFAircraftHopperFocusNode ??= FocusNode();

    _model.tFDescriptionTextController ??= TextEditingController();
    _model.tFDescriptionFocusNode ??= FocusNode();

    if (widget.aircraftId != null) {
      _loadForEdit(widget.aircraftId!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  /// Carrega o modelo e seus manuais e pré-preenche o formulário (edição).
  Future<void> _loadForEdit(String id) async {
    safeSetState(() => _loadingForEdit = true);
    try {
      final rows = await AircraftsTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', id),
      );
      final row = rows.firstOrNull;
      if (row == null) {
        _snack('Aeronave não encontrada.', error: true);
        if (mounted) safeSetState(() => _loadingForEdit = false);
        return;
      }

      _model.tFAircraftNameTextController?.text = row.aircraftModel.trim();
      _model.tFAircraftYearTextController?.text = row.aircraftYear;
      _model.tFAircraftHopperTextController?.text =
          row.hopper == row.hopper.roundToDouble()
              ? row.hopper.round().toString()
              : row.hopper.toString();
      _model.tFDescriptionTextController?.text = row.aircraftDescription;
      // O campo de preço trabalha em "centavos"; reaproveita o mesmo
      // formatador usado no onChanged para exibir igual ao cadastro.
      _model.tFPriceTextController?.text = functions.formatarMoedaEmDolar(
        (row.price * 100).round().toString(),
      );
      _model.uploadedFileUrl_uploadAircraft = row.aircraftPhotoUrl;

      final manuals = await AircraftManualsTable().queryRows(
        queryFn: (q) => q.eqOrNull('aircraft_id', id).eqOrNull('deleted', false),
      );
      for (final m in manuals) {
        switch (m.type) {
          case 'Manual do proprietário':
            _oemManualId = m.id;
            _model.uploadedFileUrl_uploadOEM = m.documentionUrl;
            break;
          case 'Manual de voo':
            _vooManualId = m.id;
            _model.uploadedFileUrl_uploadManualVoo = m.documentionUrl;
            break;
          case 'Manual de peças':
            _pecasManualId = m.id;
            _model.uploadedFileUrl_uploadManualPeca = m.documentionUrl;
            break;
        }
      }
    } catch (e) {
      _snack('Erro ao carregar a aeronave: $e', error: true);
    } finally {
      if (mounted) safeSetState(() => _loadingForEdit = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ───────────────────────── uploads ─────────────────────────

  Future<void> _pickPhoto() async {
    try {
      debugPrint('[pickPhoto] selectMedia start');
      final selected = await selectMedia(
        storageFolderPath: '',
        mediaSource: MediaSource.photoGallery,
        multiImage: false,
      );
      debugPrint('[pickPhoto] selectMedia returned ${selected?.length ?? 0}');
      if (selected == null || selected.isEmpty) return;
      final mimes = selected.map((m) => mime(m.storagePath)).toList();
      debugPrint('[pickPhoto] mimes=$mimes (allowed=$allowedFormats)');
      if (!mimes.every((m) => allowedFormats.contains(m))) {
        _snack('Formato não suportado: ${mimes.join(", ")} — use PNG, JPG ou GIF.', error: true);
        return;
      }
      safeSetState(() => _model.isDataUploading_uploadAircraft = true);
      final files = selected
          .map((m) => FFUploadedFile(
                name: m.storagePath.split('/').last,
                bytes: m.bytes,
                height: m.dimensions?.height,
                width: m.dimensions?.width,
                blurHash: m.blurHash,
                originalFilename: m.originalFilename,
              ))
          .toList();
      debugPrint('[pickPhoto] upload start, bytes=${selected.first.bytes.length}');
      final urls = await uploadSupabaseStorageFiles(
        bucketName: 'AGSur',
        selectedFiles: selected,
      );
      debugPrint('[pickPhoto] upload ok, url=${urls.firstOrNull}');
      if (files.length != selected.length || urls.length != selected.length) {
        _snack('Falha no upload da foto.', error: true);
        return;
      }
      safeSetState(() {
        _model.uploadedLocalFile_uploadAircraft = files.first;
        _model.uploadedFileUrl_uploadAircraft = urls.first;
      });
    } catch (e, st) {
      debugPrint('[pickPhoto] ERROR: $e\n$st');
      _snack('Erro ao enviar foto: $e', error: true);
    } finally {
      if (mounted) {
        safeSetState(() => _model.isDataUploading_uploadAircraft = false);
      }
    }
  }

  void _clearPhoto() {
    safeSetState(() {
      _model.uploadedLocalFile_uploadAircraft =
          FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
      _model.uploadedFileUrl_uploadAircraft = '';
      _model.isDataUploading_uploadAircraft = false;
    });
  }

  Future<void> _pickPdfSlot(_PdfSlot slot) async {
    final selected = await selectFiles(
      storageFolderPath: '',
      allowedExtensions: ['pdf'],
      multiFile: false,
    );
    if (selected == null) return;
    safeSetState(() => _setSlotUploading(slot, true));
    try {
      final files = selected
          .map((m) => FFUploadedFile(
                name: m.storagePath.split('/').last,
                bytes: m.bytes,
                originalFilename: m.originalFilename,
              ))
          .toList();
      final urls = await uploadSupabaseStorageFiles(
        bucketName: 'AGSur',
        selectedFiles: selected,
      );
      if (files.length != selected.length || urls.length != selected.length) {
        _snack('Falha no upload do PDF.', error: true);
        return;
      }
      safeSetState(() => _setSlotUploaded(slot, files.first, urls.first));
    } catch (e) {
      _snack('Erro ao enviar PDF: $e', error: true);
    } finally {
      safeSetState(() => _setSlotUploading(slot, false));
    }
  }

  void _clearPdfSlot(_PdfSlot slot) {
    safeSetState(() {
      _setSlotUploaded(
        slot,
        FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: ''),
        '',
      );
      _setSlotUploading(slot, false);
    });
  }

  void _setSlotUploading(_PdfSlot slot, bool v) {
    switch (slot) {
      case _PdfSlot.oem:
        _model.isDataUploading_uploadOEM = v;
        break;
      case _PdfSlot.afm:
        _model.isDataUploading_uploadManualVoo = v;
        break;
      case _PdfSlot.ipc:
        _model.isDataUploading_uploadManualPeca = v;
        break;
    }
  }

  void _setSlotUploaded(_PdfSlot slot, FFUploadedFile file, String url) {
    switch (slot) {
      case _PdfSlot.oem:
        _model.uploadedLocalFile_uploadOEM = file;
        _model.uploadedFileUrl_uploadOEM = url;
        break;
      case _PdfSlot.afm:
        _model.uploadedLocalFile_uploadManualVoo = file;
        _model.uploadedFileUrl_uploadManualVoo = url;
        break;
      case _PdfSlot.ipc:
        _model.uploadedLocalFile_uploadManualPeca = file;
        _model.uploadedFileUrl_uploadManualPeca = url;
        break;
    }
  }

  // ───────────────────────── submit ─────────────────────────

  Future<void> _showMissingDialog(Widget dialogChild) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: AlignmentDirectional.center
            .resolve(Directionality.of(context)),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(dialogContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: dialogChild,
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: error ? Colors.white : FlutterFlowTheme.of(context).primaryText,
          ),
        ),
        duration: const Duration(milliseconds: 3500),
        backgroundColor: error
            ? const Color(0xFFFF5963)
            : FlutterFlowTheme.of(context).primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final formOk = _model.formKey.currentState?.validate() ?? false;
    if (!formOk) {
      _snack('Preencha os campos obrigatórios.', error: true);
      return;
    }
    if (_model.uploadedFileUrl_uploadAircraft.isEmpty) {
      await _showMissingDialog(WarmingAirCraftPhotoWidget());
      return;
    }
    if (_model.uploadedFileUrl_uploadOEM.isEmpty) {
      await _showMissingDialog(WarmingMProprietarioWidget());
      return;
    }
    if (_model.uploadedFileUrl_uploadManualVoo.isEmpty) {
      await _showMissingDialog(WarmingMVooWidget());
      return;
    }
    if (_model.uploadedFileUrl_uploadManualPeca.isEmpty) {
      await _showMissingDialog(WarmingMPecasWidget());
      return;
    }

    setState(() => _submitting = true);
    try {
      final data = <String, dynamic>{
        'aircraft_model': _model.tFAircraftNameTextController.text,
        'aircraft_year': _model.tFAircraftYearTextController.text,
        'aircraft_description': _model.tFDescriptionTextController.text,
        'aircraft_photo_url': _model.uploadedFileUrl_uploadAircraft,
        'hopper': valueOrDefault<double>(
          double.tryParse(_model.tFAircraftHopperTextController.text),
          0.0,
        ),
        'price': valueOrDefault<double>(
          functions.parsePriceToDouble(_model.tFPriceTextController.text),
          0.0,
        ),
      };

      if (_isEdit) {
        await _saveEdit(widget.aircraftId!, data);
      } else {
        await _saveCreate(data);
      }

      _snack(_isEdit
          ? 'Aeronave atualizada com sucesso!'
          : 'Aeronave cadastrada com sucesso!');

      if (!_isEdit) {
        safeSetState(() {
          _model.tFPriceTextController?.clear();
          _model.tFAircraftNameTextController?.clear();
          _model.tFAircraftYearTextController?.clear();
          _model.tFDescriptionTextController?.clear();
          _model.tFAircraftHopperTextController?.clear();
        });
      }

      if (mounted) {
        context.pushNamed(RegistedAircraftWidget.routeName);
      }
    } catch (e) {
      _snack('Erro ao ${_isEdit ? 'atualizar' : 'cadastrar'}: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveCreate(Map<String, dynamic> data) async {
    _model.createAircraft = await AircraftsTable().insert({
      ...data,
      'created_by': currentUserUid,
    });
    final aircraftId = _model.createAircraft?.id;

    _model.createManualProprietario = await AircraftManualsTable().insert(
        _manualData(aircraftId, _model.uploadedFileUrl_uploadOEM,
            'Manual do proprietário'));
    _model.createManualVoo = await AircraftManualsTable().insert(_manualData(
        aircraftId, _model.uploadedFileUrl_uploadManualVoo, 'Manual de voo'));
    _model.createManualPecas = await AircraftManualsTable().insert(_manualData(
        aircraftId, _model.uploadedFileUrl_uploadManualPeca, 'Manual de peças'));
  }

  Future<void> _saveEdit(String id, Map<String, dynamic> data) async {
    // created_by permanece inalterado na edição.
    await AircraftsTable().update(
      data: data,
      matchingRows: (rows) => rows.eqOrNull('id', id),
    );

    await _upsertManual(
        id, _oemManualId, _model.uploadedFileUrl_uploadOEM,
        'Manual do proprietário');
    await _upsertManual(
        id, _vooManualId, _model.uploadedFileUrl_uploadManualVoo,
        'Manual de voo');
    await _upsertManual(
        id, _pecasManualId, _model.uploadedFileUrl_uploadManualPeca,
        'Manual de peças');
  }

  Map<String, dynamic> _manualData(String? aircraftId, String url, String type) {
    return {
      'aircraft_id': aircraftId,
      'documention_name': valueOrDefault<String>(
        functions.fileNamePath(url),
        'arquivo.pdf',
      ),
      'documention_url': url,
      'type': type,
    };
  }

  /// Atualiza o manual existente (se houver id) ou insere um novo.
  Future<void> _upsertManual(
      String aircraftId, String? manualId, String url, String type) async {
    if (manualId != null) {
      await AircraftManualsTable().update(
        data: {
          'documention_name': valueOrDefault<String>(
            functions.fileNamePath(url),
            'arquivo.pdf',
          ),
          'documention_url': url,
        },
        matchingRows: (rows) => rows.eqOrNull('id', manualId),
      );
    } else {
      await AircraftManualsTable().insert(_manualData(aircraftId, url, type));
    }
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppDetailsScaffold(
      title: _isEdit
          ? 'Editar aeronave (catálogo)'
          : 'Cadastrar aeronave (catálogo)',
      subtitle: _isEdit
          ? 'Atualize o modelo, mídia e documentação. Unidades físicas ficam em Estoque.'
          : 'Defina o modelo, mídia e documentação. Unidades físicas são cadastradas em Estoque.',
      body: Form(
        key: _model.formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoBanner().appStagger(0),
            const SizedBox(height: 18),
            _SectionCard(
              icon: Icons.flight_takeoff_rounded,
              title: 'Dados cadastrais',
              subtitle: 'Identificação principal do modelo no catálogo.',
              child: Column(
                children: [
                  _PhotoUploadCard(
                    photoUrl: _model.uploadedFileUrl_uploadAircraft,
                    isUploading: _model.isDataUploading_uploadAircraft,
                    onPick: _pickPhoto,
                    onClear: _clearPhoto,
                  ),
                  const SizedBox(height: 16),
                  AppFormField(
                    controller: _model.tFAircraftNameTextController,
                    focusNode: _model.tFAircraftNameFocusNode,
                    label: 'Modelo da aeronave',
                    placeholder: 'Ex.: Cessna 208B',
                    icon: Icons.flight_outlined,
                    required: true,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _model
                        .tFAircraftNameTextControllerValidator
                        ?.call(context, v),
                  ),
                  const SizedBox(height: 14),
                  AppFormField(
                    controller: _model.tFPriceTextController,
                    focusNode: _model.tFPriceFocusNode,
                    label: 'Preço de venda',
                    placeholder: '\$ 0.00',
                    icon: Icons.attach_money_rounded,
                    required: true,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (_) => EasyDebounce.debounce(
                      '_model.tFPriceTextController',
                      const Duration(milliseconds: 500),
                      () async {
                        safeSetState(() {
                          _model.tFPriceTextController?.text =
                              valueOrDefault<String>(
                            functions.formatarMoedaEmDolar(
                                _model.tFPriceTextController.text),
                            '0',
                          );
                          _model.tFPriceFocusNode?.requestFocus();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _model.tFPriceTextController?.selection =
                                TextSelection.collapsed(
                              offset: _model
                                  .tFPriceTextController!.text.length,
                            );
                          });
                        });
                      },
                    ),
                    validator: (v) => _model.tFPriceTextControllerValidator
                        ?.call(context, v),
                  ),
                ],
              ),
            ).appStagger(1),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.description_outlined,
              title: 'Descrição',
              subtitle: 'Especificações e detalhes que aparecem no catálogo.',
              child: Column(
                children: [
                  AppFormField(
                    controller: _model.tFAircraftYearTextController,
                    focusNode: _model.tFAircraftYearFocusNode,
                    label: 'Ano de fabricação',
                    placeholder: 'Ex.: 2024',
                    icon: Icons.event_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                    ],
                    validator: (v) => _model
                        .tFAircraftYearTextControllerValidator
                        ?.call(context, v),
                  ),
                  const SizedBox(height: 14),
                  AppFormField(
                    controller: _model.tFAircraftHopperTextController,
                    focusNode: _model.tFAircraftHopperFocusNode,
                    label: 'Hopper (capacidade)',
                    placeholder: 'Litros',
                    icon: Icons.water_drop_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                    ],
                    validator: (v) => _model
                        .tFAircraftHopperTextControllerValidator
                        ?.call(context, v),
                  ),
                  const SizedBox(height: 14),
                  AppFormField(
                    controller: _model.tFDescriptionTextController,
                    focusNode: _model.tFDescriptionFocusNode,
                    label: 'Descrição',
                    placeholder:
                        'Características, equipamentos, observações…',
                    icon: Icons.notes_rounded,
                    maxLines: 5,
                    validator: (v) => _model
                        .tFDescriptionTextControllerValidator
                        ?.call(context, v),
                  ),
                ],
              ),
            ).appStagger(2),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.menu_book_outlined,
              title: 'Manuais (PDF)',
              subtitle:
                  'OEM, AFM e IPC são obrigatórios para concluir o cadastro.',
              child: Column(
                children: [
                  _ManualUploadTile(
                    label: 'OEM — Manual do proprietário',
                    fileUrl: _model.uploadedFileUrl_uploadOEM,
                    isUploading: _model.isDataUploading_uploadOEM,
                    icon: Icons.workspace_premium_outlined,
                    onPick: () => _pickPdfSlot(_PdfSlot.oem),
                    onClear: () => _clearPdfSlot(_PdfSlot.oem),
                  ),
                  const SizedBox(height: 12),
                  _ManualUploadTile(
                    label: 'AFM — Manual de voo',
                    fileUrl: _model.uploadedFileUrl_uploadManualVoo,
                    isUploading: _model.isDataUploading_uploadManualVoo,
                    icon: Icons.flight_takeoff_outlined,
                    onPick: () => _pickPdfSlot(_PdfSlot.afm),
                    onClear: () => _clearPdfSlot(_PdfSlot.afm),
                  ),
                  const SizedBox(height: 12),
                  _ManualUploadTile(
                    label: 'IPC — Manual de peças',
                    fileUrl: _model.uploadedFileUrl_uploadManualPeca,
                    isUploading: _model.isDataUploading_uploadManualPeca,
                    icon: Icons.precision_manufacturing_outlined,
                    onPick: () => _pickPdfSlot(_PdfSlot.ipc),
                    onClear: () => _clearPdfSlot(_PdfSlot.ipc),
                  ),
                ],
              ),
            ).appStagger(3),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppSecondaryButton(
                  label: 'Cancelar',
                  icon: Icons.close_rounded,
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                AppPrimaryButton(
                  label: _isEdit
                      ? (_submitting ? 'Salvando…' : 'Salvar alterações')
                      : (_submitting ? 'Cadastrando…' : 'Cadastrar modelo'),
                  icon: Icons.check_circle_outline_rounded,
                  busy: _submitting,
                  onPressed: _loadingForEdit ? null : _submit,
                ),
              ],
            ).appStagger(4),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

enum _PdfSlot { oem, afm, ipc }

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0x22C2D51C),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x55C2D51C)),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: Color(0xFFC2D51C),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cadastro de modelo no catálogo',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Defina aqui as características do modelo (nome, foto, ano, hopper, descrição). Depois você adiciona as unidades físicas em "Estoque (unidades)".',
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    color: const Color(0xCCFFFFFF),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0x22C2D51C),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: const Color(0xFFC2D51C), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: const Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0x14FFFFFF)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PhotoUploadCard extends StatefulWidget {
  const _PhotoUploadCard({
    required this.photoUrl,
    required this.isUploading,
    required this.onPick,
    required this.onClear,
  });

  final String photoUrl;
  final bool isUploading;
  final Future<void> Function() onPick;
  final VoidCallback onClear;

  @override
  State<_PhotoUploadCard> createState() => _PhotoUploadCardState();
}

class _PhotoUploadCardState extends State<_PhotoUploadCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoUrl.isNotEmpty;

    return MouseRegion(
      cursor: widget.isUploading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.isUploading || hasPhoto ? null : widget.onPick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasPhoto
                  ? const Color(0x55C2D51C)
                  : _hover
                      ? const Color(0x77C2D51C)
                      : const Color(0x44FFFFFF),
              width: 1.4,
            ),
            boxShadow: _hover && !hasPhoto
                ? [
                    BoxShadow(
                      color: const Color(0xFFC2D51C).withValues(alpha: 0.18),
                      blurRadius: 18,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  Image.network(
                    widget.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderEmpty(),
                  )
                else
                  _placeholderEmpty(),
                if (widget.isUploading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFFC2D51C),
                        ),
                      ),
                    ),
                  ),
                if (hasPhoto && !widget.isUploading)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _floatingChip(
                          label: 'Trocar',
                          icon: Icons.swap_horiz_rounded,
                          onTap: widget.onPick,
                        ),
                        const SizedBox(width: 8),
                        _floatingChip(
                          label: 'Remover',
                          icon: Icons.delete_outline_rounded,
                          danger: true,
                          onTap: widget.onClear,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0x22C2D51C),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: Color(0xFFC2D51C),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Adicionar foto da aeronave',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PNG / JPG · Recomendado 16:9',
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                color: const Color(0x99FFFFFF),
              ),
            ),
          ],
        ),
      );

  Widget _floatingChip({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFFF7B82) : const Color(0xFFC2D51C);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualUploadTile extends StatefulWidget {
  const _ManualUploadTile({
    required this.label,
    required this.fileUrl,
    required this.isUploading,
    required this.icon,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final String fileUrl;
  final bool isUploading;
  final IconData icon;
  final Future<void> Function() onPick;
  final VoidCallback onClear;

  @override
  State<_ManualUploadTile> createState() => _ManualUploadTileState();
}

class _ManualUploadTileState extends State<_ManualUploadTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.fileUrl.isNotEmpty;
    final fileName = hasFile
        ? valueOrDefault<String>(
            functions.fileNamePath(widget.fileUrl),
            'arquivo.pdf',
          )
        : '';

    return MouseRegion(
      cursor: widget.isUploading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.isUploading ? null : widget.onPick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFile
                  ? const Color(0x66C2D51C)
                  : _hover
                      ? const Color(0x77C2D51C)
                      : const Color(0x33FFFFFF),
              width: 1.2,
            ),
            boxShadow: _hover && !hasFile
                ? [
                    BoxShadow(
                      color: const Color(0xFFC2D51C).withValues(alpha: 0.14),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: hasFile
                      ? const Color(0x33C2D51C)
                      : const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasFile ? Icons.picture_as_pdf_rounded : widget.icon,
                  size: 18,
                  color: hasFile
                      ? const Color(0xFFC2D51C)
                      : const Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasFile ? fileName : 'Selecione um arquivo PDF',
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: hasFile
                            ? const Color(0xFFC2D51C)
                            : const Color(0x99FFFFFF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.isUploading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC2D51C),
                  ),
                )
              else if (hasFile) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x33C2D51C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_rounded,
                          size: 12, color: Color(0xFFC2D51C)),
                      SizedBox(width: 4),
                      Text(
                        'Carregado',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFFC2D51C),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onClear,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0x22FF5963),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFFFF7B82),
                      ),
                    ),
                  ),
                ),
              ] else
                const Icon(
                  Icons.upload_rounded,
                  size: 18,
                  color: Color(0xCCFFFFFF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
