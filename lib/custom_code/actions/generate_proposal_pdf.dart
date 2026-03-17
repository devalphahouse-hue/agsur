// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// ===================== HELPERS =====================

DateTime addMonths(DateTime date, int months) {
  int newYear = date.year + ((date.month + months - 1) ~/ 12);
  int newMonth = ((date.month + months - 1) % 12) + 1;
  int newDay = date.day;
  int lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
  if (newDay > lastDayOfNewMonth) newDay = lastDayOfNewMonth;
  return DateTime(newYear, newMonth, newDay);
}

double roundUp(double value) {
  return (value * 100).ceil() / 100;
}

String formatCurrency(double value) {
  final formatter = NumberFormat("#,##0.00", "en_US");
  return "\$ ${formatter.format(value)}";
}

String formatCurrencyU(double value) {
  final formatter = NumberFormat("#,##0.00", "en_US");
  return "U\$${formatter.format(value)}";
}

Future<pw.ImageProvider> safeNetworkImage(String url) async {
  final uri = Uri.parse(url);
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('Falha ao baixar imagem ($url). Status: ${res.statusCode}');
  }
  final contentType = res.headers['content-type'] ?? '';
  if (!contentType.startsWith('image/')) {
    throw Exception('URL não retornou imagem válida. content-type="$contentType"');
  }
  return pw.MemoryImage(res.bodyBytes);
}

String normalizeTypeDoc(dynamic v) {
  if (v == null) return '';
  final s = v.toString().trim();
  if (s.isEmpty) return '';
  if (s.toLowerCase() == 'não cadastrado' || s.toLowerCase() == 'nao cadastrado') return '';
  return s;
}

// ===================== PARCELAS =====================
List<Map<String, dynamic>> calcularParcelas(
  double creditoTotal,
  int numParcelas,
  DateTime dataCredito,
  double taxaJurosEfetivos,
) {
  double principalParcelado = creditoTotal / numParcelas;
  double principalRestante = creditoTotal;
  List<Map<String, dynamic>> parcelas = [];
  DateTime dataParcela = addMonths(dataCredito, 6);

  for (int i = 1; i <= numParcelas; i++) {
    DateTime dataAnterior = (i == 1) ? dataCredito : addMonths(dataCredito, 6 * (i - 1));
    int diasJuros = dataParcela.difference(dataAnterior).inDays;
    double juros = roundUp((principalRestante * taxaJurosEfetivos / 360) * diasJuros);
    principalParcelado = roundUp(principalParcelado);
    principalRestante = roundUp(principalRestante);
    double pagamentoTotal = roundUp(principalParcelado + juros);
    principalRestante -= principalParcelado;
    if (principalRestante < 0) principalRestante = 0;
    if (i == numParcelas && principalRestante < 1) principalRestante = 0;

    parcelas.add({
      'n': i.toString(),
      'data': DateFormat('dd/MM/yyyy').format(dataParcela),
      'principal': formatCurrency(principalParcelado),
      'juros': formatCurrency(juros),
      'total': formatCurrency(pagamentoTotal),
      'saldo': formatCurrency(principalRestante),
      'dias': diasJuros.toString(),
    });
    dataParcela = addMonths(dataParcela, 6);
  }
  return parcelas;
}

// ===================== COLORS =====================
final _darkBg = PdfColor.fromHex('#333333');
final _white = PdfColors.white;
final _black = PdfColors.black;
final _headerTableBg = PdfColor.fromHex('#4a4a4a');
final _lightGrey = PdfColor.fromHex('#f5f5f5');

// ===================== SHARED WIDGETS =====================

pw.Widget _buildHeader(pw.ImageProvider logoImage, String year, String clientName, String invoiceRef, String date, String previsaoEntrega, {String? proposalYear}) {
  return pw.Column(children: [
    // Dark banner with logo + PROPOSTA title
    pw.Container(
      color: _darkBg,
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Image(logoImage, width: 220),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Representante AGSUR AVIONES',
                  style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'CNPJ.: 38.097.750/0001-04 / IE.: 127.705.682.110',
                  style: pw.TextStyle(fontSize: 6, color: _white),
                ),
                pw.Text(
                  'Rua Francisco Antonio Miranda, 31 - 07090-140 - Guarulhos-SP / Brasil',
                  style: pw.TextStyle(fontSize: 6, color: _white),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('PROPOSTA - ${proposalYear ?? year}',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _white)),
                pw.SizedBox(height: 4),
                pw.Text('Previsão de Entrega.:',
                    style: pw.TextStyle(fontSize: 8, color: _white)),
                pw.Text(previsaoEntrega,
                    style: pw.TextStyle(fontSize: 8, color: _white)),
                pw.SizedBox(height: 8),
                pw.Text(clientName,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _white)),
                pw.SizedBox(height: 4),
                pw.Text('INVOICE.: $invoiceRef',
                    style: pw.TextStyle(fontSize: 7, color: _white)),
                pw.Text('DATE.: $date',
                    style: pw.TextStyle(fontSize: 7, color: _white)),
              ],
            ),
          ),
        ],
      ),
    ),
  ]);
}

pw.Widget _buildPageNumber(int page, int total) {
  return pw.Container(
    alignment: pw.Alignment.bottomRight,
    child: pw.Text('PAGE $page / $total', style: pw.TextStyle(fontSize: 8)),
  );
}

pw.Widget _labelValue(String label, String value, {bool bold = true, double fontSize = 8}) {
  return pw.Row(children: [
    pw.Expanded(
      child: pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    ),
    pw.Text(value, style: pw.TextStyle(fontSize: fontSize)),
  ]);
}

pw.Widget _tableHeader(String title) {
  return pw.Container(
    width: double.infinity,
    color: _headerTableBg,
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: pw.Text(title,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _white),
        textAlign: pw.TextAlign.center),
  );
}

pw.Widget _tableRow(String label, String value, {bool boldLabel = true, pw.EdgeInsets? padding}) {
  return pw.Container(
    padding: padding ?? const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#dddddd'), width: 0.5)),
    ),
    child: pw.Row(children: [
      pw.Expanded(
        child: pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: boldLabel ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ),
      pw.Text(value, style: pw.TextStyle(fontSize: 8)),
    ]),
  );
}

// ===================== GERAR PDF =====================
Future<void> generateProposalPdf(
  GetProposalDetailsStruct asGetProposalDetails,
  GetFinancialProposalStruct asGetFinancialProposal,
  String sellerName,
) async {
  final pdf = pw.Document();

  // Load logo
  final logoImage = await safeNetworkImage(
    'https://bkzybtmxxzpxtztesdye.supabase.co/storage/v1/object/public/AGSur//agsur_brasil_logo.jpg',
  );

  // Data extraction
  final proposal = asGetProposalDetails.proposal;
  final lead = asGetProposalDetails.proposalLead;
  final company = asGetProposalDetails.proposalCompany;
  final address = asGetProposalDetails.proposalAddress;
  final aircraft = asGetProposalDetails.proposalAircraft;
  final seriesItems = asGetProposalDetails.proposalSeriesItems ?? [];
  final optionalItems = asGetProposalDetails.proposalOptionalItems ?? [];

  final fullPrice = asGetFinancialProposal.fullprice;
  final sinalPercent = asGetFinancialProposal.sinal;
  final depositoPercent = asGetFinancialProposal.depositoInicial;
  final sinalValor = roundUp(fullPrice * sinalPercent);
  final depositoValor = roundUp(fullPrice * depositoPercent);
  final depositoTotal = roundUp(sinalValor + depositoValor);
  final subtotal = roundUp(fullPrice - sinalValor - depositoValor);
  final taxaPremium = asGetFinancialProposal.taxaPremium;
  final premium = roundUp(subtotal * taxaPremium);
  final creditoTotal = roundUp(subtotal + premium);
  final prazo = asGetFinancialProposal.prazo;
  final qtdParcelas = prazo * 2;
  final taxaJuros = asGetFinancialProposal.taxaJuros;
  final taxaSofr = asGetFinancialProposal.taxaSofr;
  final taxaJurosEfetivos = asGetFinancialProposal.taxaJurosEfetivos;
  final dataCredito = asGetFinancialProposal.dataCredito;
  final percentualPgtoTotal = asGetFinancialProposal.percentualPgtoTotal;

  final parcelas = calcularParcelas(creditoTotal, qtdParcelas, dataCredito!, taxaJurosEfetivos);

  // Common data
  final year = aircraft.aircraftYear.isNotEmpty ? aircraft.aircraftYear : DateTime.now().year.toString();
  final proposalYear = DateTime.now().year.toString();
  final invoiceRef = proposal.idRef;
  final date = proposal.createdAt != null && proposal.createdAt!.isNotEmpty
      ? DateFormat('dd/MM/yyyy').format(DateTime.parse(proposal.createdAt!))
      : '';
  final clientName = lead.fullname;

  // Document info
  final typeDoc = normalizeTypeDoc(company.typeDoc);
  String docLabel = 'CPF';
  String docValue = '';
  if (typeDoc == '1') {
    docLabel = 'CNPJ';
    docValue = company.cnpj;
  } else if (typeDoc == '2') {
    docLabel = 'CPF';
    docValue = company.cpf;
  }
  if (docValue.isEmpty || docValue.toLowerCase().contains('não cadastrado') || docValue.toLowerCase().contains('nao cadastrado')) {
    docValue = '';
  }

  // Inscrição Estadual
  final ie = company.stateRegistration;

  // Address
  final fullAddress = '${address.street}, ${address.number}${address.complement.isNotEmpty ? ' - ${address.complement}' : ''}';
  final cityState = '${address.city} - ${address.state}';
  final cep = address.zipcode;

  // Forma de pagamento
  final formaPagamento = 'FINANCIADO - $prazo ANOS';
  final previsaoEntrega = '';

  final totalPages = 3;

  // Aircraft title
  final aircraftTitle = '$year ${aircraft.aircraftModel}';

  // Calculate optionals total
  double optionalsTotal = 0.0;
  for (final opt in optionalItems) {
    optionalsTotal += roundUp(opt.item.price * opt.item.qty);
  }
  // Aircraft price is the base price (fullPrice), optionals are added on top
  final aircraftOnlyPrice = fullPrice;
  final aircraftDescription = aircraft.aircraftDescription;

  // ==================== PAGE 1 - INVOICE / ITEMS ====================
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logoImage, year, clientName, invoiceRef, date, previsaoEntrega, proposalYear: proposalYear),
            pw.SizedBox(height: 12),

            // SOLD TO / SHIP TO
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // SOLD TO
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 14,
                          child: pw.Column(
                            children: [
                              pw.Text('S', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.Text('O', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.Text('L', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.Text('D', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 2),
                              pw.Text('T', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.Text('O', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(clientName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              pw.Text('$docLabel.: $docValue', style: pw.TextStyle(fontSize: 7)),
                              pw.Text('IE.: $ie', style: pw.TextStyle(fontSize: 7)),
                              pw.Text('Endereço.: $fullAddress', style: pw.TextStyle(fontSize: 7)),
                              pw.SizedBox(height: 2),
                              pw.Text('Cidade e UF.: $cityState', style: pw.TextStyle(fontSize: 7)),
                              pw.Text('CEP $cep', style: pw.TextStyle(fontSize: 7)),
                              pw.Text('Pais.: Brasil', style: pw.TextStyle(fontSize: 7)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // SHIP TO
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 14,
                          child: pw.Column(
                            children: [
                              pw.Text('S', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.Text('H', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.Text('I', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.Text('P', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 2),
                              pw.Text('T', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                              pw.Text('O', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(clientName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              pw.Text('$docLabel.: $docValue', style: pw.TextStyle(fontSize: 7)),
                              pw.Text('IE.: $ie', style: pw.TextStyle(fontSize: 7)),
                              pw.Text('Endereço.: $fullAddress', style: pw.TextStyle(fontSize: 7)),
                              pw.SizedBox(height: 2),
                              pw.Text('Cidade e UF.: $cityState', style: pw.TextStyle(fontSize: 7)),
                              pw.Text('CEP $cep', style: pw.TextStyle(fontSize: 7)),
                              pw.Text('Pais.: Brasil', style: pw.TextStyle(fontSize: 7)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // FORMA DE PAGAMENTO / INCOTERMS
            pw.Row(children: [
              pw.Expanded(
                child: pw.Column(children: [
                  pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text('FORMA DE PAGAMENTO',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(formaPagamento, style: pw.TextStyle(fontSize: 8)),
                ]),
              ),
              pw.Expanded(
                child: pw.Column(children: [
                  pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text('INCOTERMS',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text('CPT "CARRIAGE PAID TO" - BRASIL', style: pw.TextStyle(fontSize: 8)),
                ]),
              ),
            ]),
            pw.SizedBox(height: 8),

            // ITEMS TABLE HEADER
            pw.Container(
              color: _darkBg,
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: pw.Row(children: [
                pw.Container(width: 30, child: pw.Text('ITEM', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold))),
                pw.Container(width: 25, child: pw.Text('QTD', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold))),
                pw.Expanded(child: pw.Text('DESCRIÇÃO', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold))),
                pw.Container(width: 90, child: pw.Text('PREÇO UNITARIO (U\$)', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                pw.Container(width: 80, child: pw.Text('TOTAL (U\$)', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
              ]),
            ),

            // Item 1 - Aircraft (title + description)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.3))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.3))),
                    child: pw.Text(aircraftTitle,
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 30, child: pw.Text('1', style: pw.TextStyle(fontSize: 7))),
                      pw.Container(width: 25, child: pw.Text('', style: pw.TextStyle(fontSize: 7))),
                      pw.Expanded(
                        child: pw.Text(
                          aircraftDescription,
                          style: pw.TextStyle(fontSize: 7),
                        ),
                      ),
                      pw.Container(
                        width: 90,
                        child: pw.Text(formatCurrencyU(aircraftOnlyPrice), style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
                      ),
                      pw.Container(
                        width: 80,
                        child: pw.Text(formatCurrencyU(aircraftOnlyPrice), style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Optional items
            ...List.generate(optionalItems.length, (index) {
              final opt = optionalItems[index];
              final item = opt.item;
              final itemPrice = item.price;
              final itemQty = item.qty;
              final itemTotal = roundUp(itemPrice * itemQty);
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.3))),
                child: pw.Row(children: [
                  pw.Container(width: 30, child: pw.Text('${index + 2}', style: pw.TextStyle(fontSize: 7))),
                  pw.Container(width: 25, child: pw.Text('$itemQty', style: pw.TextStyle(fontSize: 7))),
                  pw.Expanded(child: pw.Text(item.itemName, style: pw.TextStyle(fontSize: 7))),
                  pw.Container(width: 90, child: pw.Text(formatCurrencyU(itemPrice), style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right)),
                  pw.Container(width: 80, child: pw.Text(formatCurrencyU(itemTotal), style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right)),
                ]),
              );
            }),

            pw.Spacer(),

            // Bottom separator lines
            pw.Divider(thickness: 0.5),
            pw.Divider(thickness: 0.5),

            pw.SizedBox(height: 4),
            _buildPageNumber(1, totalPages),
          ],
        );
      },
    ),
  );

  // Aircraft price is the base price, optionals are added on top
  final invoiceTotal = roundUp(fullPrice + optionalsTotal);

  // ==================== PAGE 2 - PAYMENT CONDITIONS / BANKING ====================
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logoImage, year, clientName, invoiceRef, date, previsaoEntrega, proposalYear: proposalYear),
            pw.SizedBox(height: 16),

            // CONDIÇÕES DE PAGAMENTO
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.Column(children: [
                _tableHeader('CONDIÇÕES DE PAGAMENTO'),
                _tableRow('FINANCIAMENTO', '$prazo ANOS'),
                _tableRow('PERIODICIDADE', 'PAGAMENTOS SEMESTRAIS'),
                _tableRow('CARENCIA INICIAL', '6 MESES'),
                _tableRow('VALOR DO BEM', formatCurrency(fullPrice)),
                _tableRow('DEPOSITO ENTRADA ${(sinalPercent * 100).toStringAsFixed(0)}% - ATE (DATA)', formatCurrency(sinalValor)),
                _tableRow('DEPOSITO SALDO ${(depositoPercent * 100).toStringAsFixed(0)}% - (ANTES DA ENTREGA)', formatCurrency(depositoValor)),
                _tableRow('SALDO', formatCurrency(premium)),
                _tableRow('RISCO PAIS - TAXA EXIM (ESTIMADA)', formatCurrency(creditoTotal)),
                _tableRow('TOTAL FINANCIADO', formatCurrency(roundUp(creditoTotal - premium))),
                _tableRow('CUSTO BANCARIO', formatCurrency(2500)),
                _tableRow('*PAGAMENTO CAUÇÃO (ATO)', formatCurrency(10000)),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '**pagamento caução é reembolsavel apor 12 meses da entrega da aeroanave, se não houver inadimplemento nas parcelas',
                        style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            pw.SizedBox(height: 16),

            // INFORMAÇÕES BANCÁRIAS
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.Column(children: [
                _tableHeader('INFORMAÇÕES BANCARIAS PARA TRANFERENCIA - VIA BANCO CENTRAL'),
                _tableRow('NOME DO BANCO', 'WELLS FARGO BANK, N.A.'),
                _tableRow('ENDEREÇO DO BANCO', 'SAN FRANCISCO, CA 94104 USA'),
                _tableRow('NUMERO DE TRANSITO', '121000248'),
                _tableRow('SWIFT', 'WFBIUS6S'),
                _tableRow('NUMERO DA CONTA', '5140101725'),
                _tableRow('BENEFICIARIO', 'AIR TRACTOR, INC.'),
              ]),
            ),
            pw.SizedBox(height: 24),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(children: [
                  pw.Container(width: 180, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
                  pw.SizedBox(height: 4),
                  pw.Text('COMPRADOR', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ]),
                pw.Column(children: [
                  pw.Container(width: 180, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
                  pw.SizedBox(height: 4),
                  pw.Text('AGSUR BRASIL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ]),
              ],
            ),
            pw.Spacer(),

            // SUBTOTAL / SHIPPING / INVOICE TOTAL
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(children: [
                      pw.Text('SUBTOTAL', style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(width: 20),
                      pw.Text(formatCurrency(invoiceTotal), style: pw.TextStyle(fontSize: 9)),
                    ]),
                    pw.Row(children: [
                      pw.Text('SHIPPING', style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(width: 20),
                      pw.Text('\$ -', style: pw.TextStyle(fontSize: 9)),
                    ]),
                    pw.Row(children: [
                      pw.Text('INVOICE TOTAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(width: 20),
                      pw.Text(formatCurrency(invoiceTotal), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ]),
                    pw.Text('TODOS OS PREÇOS ESTAO EM USD (DOLAR AMERICANO)',
                        style: pw.TextStyle(fontSize: 6)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '**O depósito de ${(sinalPercent * 100).toStringAsFixed(0)}% é reembolsável até 120 dias antes da data estimada de entrega. Após esse prazo, não é mais reembolsável.**',
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 4),
            _buildPageNumber(2, totalPages),
          ],
        );
      },
    ),
  );

  // ==================== PAGE 3 - FINANCING PLAN ====================
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logoImage, year, clientName, invoiceRef, date, previsaoEntrega, proposalYear: proposalYear),
            pw.SizedBox(height: 12),

            // Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('PLANO DE FINANCIAMENTO - EXIM BANK',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('PRAZO- $prazo ANOS',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 8),

            // Two side-by-side info tables
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // INFORMAÇÃO DE CRÉDITO
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                    child: pw.Column(children: [
                      _tableHeader('INFORMAÇÃO DE CRÉDITO'),
                      _tableRow('PREÇO NA FATURA', formatCurrency(fullPrice), boldLabel: false),
                      _tableRow('SINAL', formatCurrency(sinalValor), boldLabel: false),
                      _tableRow('DEPOSITO (ANTES DA ENTREGA)', formatCurrency(depositoValor), boldLabel: false),
                      _tableRow('DEPOSITO TOTAL', formatCurrency(depositoTotal), boldLabel: false),
                      _tableRow('SUBTORAL', formatCurrency(subtotal), boldLabel: false),
                      _tableRow('TAXA PREMIUL (ESTIMATIVA)', '${(taxaPremium * 100).toStringAsFixed(2)}%', boldLabel: false),
                      _tableRow('PREMIUM', formatCurrency(premium), boldLabel: false),
                      _tableRow('CREDITO TOTAL', formatCurrency(creditoTotal), boldLabel: false),
                    ]),
                  ),
                ),
                pw.SizedBox(width: 8),
                // DETALHAMENTO DO CÁLCULO
                pw.Expanded(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                    child: pw.Column(children: [
                      _tableHeader('DETALHAMENTO DO CÁLCULO'),
                      _tableRow('DATA DO CREDITO', dataCredito != null ? DateFormat('dd/MM/yyyy').format(dataCredito) : '', boldLabel: false),
                      _tableRow('TAXA DE JUROS', '${(taxaJuros * 100).toStringAsFixed(4)}%', boldLabel: false),
                      _tableRow('TAXA DE SOFR (ESTIMADA)', '${(taxaSofr * 100).toStringAsFixed(4)}%', boldLabel: false),
                      _tableRow('TAXA DE JUROS EFETIVO', '${(taxaJurosEfetivos * 100).toStringAsFixed(4)}%', boldLabel: false),
                      _tableRow('PRAZO', '$prazo ANOS', boldLabel: false),
                      _tableRow('PAIS', 'BRASIL', boldLabel: false),
                      _tableRow('N° DE PAGAMENTOS', '$qtdParcelas', boldLabel: false),
                      _tableRow('% TOTAL DE ENTRADA', '${(percentualPgtoTotal * 100).toStringAsFixed(0)}%', boldLabel: false),
                    ]),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Installments table
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.Column(children: [
                // Header
                pw.Container(
                  color: _darkBg,
                  padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  child: pw.Row(children: [
                    pw.Container(width: 20, child: pw.Text('N°', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Container(width: 65, child: pw.Text('DATA PARCELA', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Expanded(child: pw.Text('PRINCIPAL', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Expanded(child: pw.Text('JUROS', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Expanded(child: pw.Text('PGTO TOTAL', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Expanded(child: pw.Text('PRINCIPAL', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    pw.Container(width: 45, child: pw.Text('JUROS DIA', style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  ]),
                ),
                // Rows (always show 14 rows)
                ...List.generate(14, (i) {
                  final hasData = i < parcelas.length;
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#dddddd'), width: 0.3)),
                    ),
                    child: pw.Row(children: [
                      pw.Container(width: 20, child: pw.Text('${i + 1}', style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center)),
                      pw.Container(width: 65, child: pw.Text(hasData ? parcelas[i]['data'] : '', style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center)),
                      pw.Expanded(child: pw.Text(hasData ? parcelas[i]['principal'] : '', style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center)),
                      pw.Expanded(child: pw.Text(hasData ? parcelas[i]['juros'] : '', style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center)),
                      pw.Expanded(child: pw.Text(hasData ? parcelas[i]['total'] : '', style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center)),
                      pw.Expanded(child: pw.Text(hasData ? parcelas[i]['saldo'] : '', style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center)),
                      pw.Container(width: 45, child: pw.Text(hasData ? parcelas[i]['dias'] : '', style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center)),
                    ]),
                  );
                }),
              ]),
            ),
            pw.SizedBox(height: 8),

            // CONDIÇÕES DE FINANCIAMENTO
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.Column(children: [
                _tableHeader('CONDIÇÕES DE FINANCIAMENTO'),
                _tableRow('PRAZO', '$prazo ANOS'),
                _tableRow('PERIODICIDADE', 'PAGAMENTOS SEMESTRAIS'),
                _tableRow('CARENCIA INICIAL', '6 MESES'),
                _tableRow('VALOR DO BEM', formatCurrency(fullPrice)),
                _tableRow('SINAL.: 1° PAGAMENTO', formatCurrency(sinalValor)),
                _tableRow('2° PAGAMENTO (ANTES DA ENTREGA)', formatCurrency(depositoValor)),
                _tableRow('VALOR DO PREMIO ESTIMATIVO', formatCurrency(premium)),
                _tableRow('TOTAL FIANCIADO', formatCurrency(creditoTotal)),
                pw.Container(height: 4),
                _tableRow('ENCARGO BANCARIO', formatCurrency(2500)),
                _tableRow('RESERVA DE SEGURO (ATO)', formatCurrency(10000)),
              ]),
            ),
            pw.Spacer(),
            _buildPageNumber(3, totalPages),
          ],
        );
      },
    ),
  );

  // ==================== PAGE 4 - TERMOS DE PRE-COMPRA ====================
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        final boldStyle = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
        final normalStyle = pw.TextStyle(fontSize: 8);

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logoImage, year, clientName, invoiceRef, date, previsaoEntrega, proposalYear: proposalYear),
            pw.SizedBox(height: 16),

            pw.Center(
              child: pw.Text('TERMOS DE PRE-COMPRA',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 12),

            pw.Text(
              'Os presentes Termos de Proposta para Intenção de Compra estabelecem as condições comerciais, financeiras e operacionais aplicáveis à futura aquisição da aeronave, alinhadas às práticas contratuais da Air Tractor e às exigências do EXIM Bank, possuindo caráter pré-contratual.',
              style: normalStyle,
            ),
            pw.SizedBox(height: 8),

            pw.Text('1. ENTRADA (SINAL)', style: boldStyle),
            pw.Text('A entrada total corresponderá a 15% do valor da aeronave, sendo:', style: normalStyle),
            pw.Text('a) 5% pagos antecipadamente, no ato da intenção de compra;', style: normalStyle),
            pw.Text('b) 10% pagos antes do traslado da aeronave.', style: normalStyle),
            pw.Text('1.1 CONDIÇÕES DE ESTORNO', style: boldStyle),
            pw.Text('a) Os 5% antecipados serão estornados em caso de cancelamento até 120 dias antes da entrega;', style: normalStyle),
            pw.Text('b) Os 5% também serão estornados em caso de negativa formal do financiamento pelo EXIM Bank;', style: normalStyle),
            pw.Text('c) Não haverá estorno e será aplicada multa contratual caso o cancelamento ocorra após 120 dias, por vontade própria ou após aprovação do crédito.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('2. CAUÇÃO', style: boldStyle),
            pw.Text('Será exigida caução no valor de USD 10.000,00, retida pela Air Tractor por 365 dias após a entrega.', style: normalStyle),
            pw.Text('Não haverá estorno em caso de inadimplência. Haverá estorno em caso de adimplência, mediante solicitação com 60 dias de antecedência via e-mail thiago@agsurbrasil.com.br. Em caso de pagamento à vista, esta cláusula não se aplica.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('3. TAXA BANCÁRIA', style: boldStyle),
            pw.Text('Será devido o pagamento de USD 2.500,00, sem possibilidade de estorno, referente exclusivamente a taxa bancária americana. O valor poderá ser maior em caso de utilização de trading. Em caso de pagamento à vista, esta taxa não se aplica.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('4. FINANCIAMENTO', style: boldStyle),
            pw.Text('É responsabilidade do comprador fornecer todas as informações e documentos exigidos conforme normas americanas e EXIM Bank.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('5. JUROS', style: boldStyle),
            pw.Text('Taxa variável baseada na SOFR, recalculada semestralmente.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('6. TRANSLADO', style: boldStyle),
            pw.Text('O traslado se inicia nos EUA e passa a ser responsabilidade do comprador. Caso utilize empresa própria, deverá informar antes da aprovação do financiamento.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('7. SEGUROS', style: boldStyle),
            pw.Text('Obrigatória a contratação de seguro Casco, RETA e LUC antes da decolagem ao Brasil.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('8. IMPORTAÇÃO', style: boldStyle),
            pw.Text('Despachante aduaneiro e benefícios fiscais são de responsabilidade do comprador.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('9. VTI', style: boldStyle),
            pw.Text('A oficina para Vistoria Técnica Inicial será indicada pelo comprador.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('10. EQUIPAMENTOS AGRÍCOLAS', style: boldStyle),
            pw.Text('Aquisição por conta do comprador, podendo ser incluída no financiamento se adquirida nos EUA.', style: normalStyle),
            pw.SizedBox(height: 4),

            pw.Text('11. GARANTIA', style: boldStyle),
            pw.Text('Garantia de 365 dias ou 500 horas, o que ocorrer primeiro. Itens de consumo e serviços não estão cobertos.', style: normalStyle),

            pw.Spacer(),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(children: [
                  pw.Container(width: 180, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
                  pw.SizedBox(height: 4),
                  pw.Text('COMPRADOR', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ]),
                pw.Column(children: [
                  pw.Container(width: 180, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
                  pw.SizedBox(height: 4),
                  pw.Text('AGSUR BRASIL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ]),
              ],
            ),
            pw.SizedBox(height: 8),
            _buildPageNumber(3, totalPages),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (_) async => pdf.save(),
  );
}
