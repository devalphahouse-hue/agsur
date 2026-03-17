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

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

// ===================== HELPERS =====================

double _roundUp(double value) {
  return (value * 100).ceil() / 100;
}

String _formatCurrency(double value) {
  final formatter = NumberFormat("#,##0.00", "en_US");
  return "\$ ${formatter.format(value)}";
}

String _formatCurrencyUS(double value) {
  final formatter = NumberFormat("#,##0.00", "en_US");
  return "US\$ ${formatter.format(value)}";
}

String _formatCurrencyU(double value) {
  final formatter = NumberFormat("#,##0.00", "en_US");
  return "U\$${formatter.format(value)}";
}

Future<pw.ImageProvider> _safeNetworkImage(String url) async {
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

String _normalizeTypeDoc(dynamic v) {
  if (v == null) return '';
  final s = v.toString().trim();
  if (s.isEmpty) return '';
  if (s.toLowerCase() == 'não cadastrado' || s.toLowerCase() == 'nao cadastrado') return '';
  return s;
}

// ===================== COLORS =====================
final _darkBg = PdfColor.fromHex('#333333');
final _white = PdfColors.white;
final _headerTableBg = PdfColor.fromHex('#4a4a4a');

// ===================== SHARED WIDGETS =====================

pw.Widget _buildHeader(pw.ImageProvider logoImage, String clientName, String invoiceRef, String date, String previsaoEntrega) {
  return pw.Container(
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
              pw.Text('PROFORMA INVOICE',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _white)),
              pw.SizedBox(height: 4),
              pw.Text('Previsão de Entrega.:',
                  style: pw.TextStyle(fontSize: 8, color: _white)),
              pw.Text(previsaoEntrega,
                  style: pw.TextStyle(fontSize: 8, color: _white)),
              pw.SizedBox(height: 8),
              pw.Text('INVOICE.: $invoiceRef',
                  style: pw.TextStyle(fontSize: 7, color: _white)),
              pw.Text('DATE.: $date',
                  style: pw.TextStyle(fontSize: 7, color: _white)),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildPageNumber(int page, int total) {
  return pw.Container(
    alignment: pw.Alignment.bottomRight,
    child: pw.Text('PAGE $page / $total', style: pw.TextStyle(fontSize: 8)),
  );
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

pw.Widget _tableRow(String label, String value, {bool boldLabel = true}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
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
Future<void> generateContractPdf(
    GetProposalDetailsStruct asGetProposalDetails,
    GetFinancialProposalStruct asGetFinancialProposal,
    String terms,
    String instructions) async {
  final pdf = pw.Document();

  // Load logo
  final logoImage = await _safeNetworkImage(
    'https://bkzybtmxxzpxtztesdye.supabase.co/storage/v1/object/public/AGSur//agsur_brasil_logo.jpg',
  );

  // Data extraction
  final proposal = asGetProposalDetails.proposal;
  final lead = asGetProposalDetails.proposalLead;
  final company = asGetProposalDetails.proposalCompany;
  final address = asGetProposalDetails.proposalAddress;
  final aircraft = asGetProposalDetails.proposalAircraft;
  final optionalItems = asGetProposalDetails.proposalOptionalItems ?? [];

  final fullPrice = asGetFinancialProposal.fullprice;
  final sinalPercent = asGetFinancialProposal.sinal;
  final depositoPercent = asGetFinancialProposal.depositoInicial;
  final sinalValor = _roundUp(fullPrice * sinalPercent);
  final depositoValor = _roundUp(fullPrice * depositoPercent);
  final depositoTotal = _roundUp(sinalValor + depositoValor);
  final subtotal = _roundUp(fullPrice - depositoTotal);
  final taxaPremium = asGetFinancialProposal.taxaPremium;
  final premium = _roundUp(subtotal * taxaPremium);
  final creditoTotal = _roundUp(subtotal + premium);
  final prazo = asGetFinancialProposal.prazo;

  // Common data
  final year = aircraft.aircraftYear.isNotEmpty ? aircraft.aircraftYear : DateTime.now().year.toString();
  final invoiceRef = proposal.idRef;
  final date = proposal.createdAt != null && proposal.createdAt!.isNotEmpty
      ? DateFormat('dd/MM/yyyy').format(DateTime.parse(proposal.createdAt!))
      : '';
  final clientName = lead.fullname;
  final previsaoEntrega = '';

  // Document info
  final typeDoc = _normalizeTypeDoc(company.typeDoc);
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

  // Aircraft title
  final aircraftTitle = '$year ${aircraft.aircraftModel}';
  final aircraftDescription = aircraft.aircraftDescription;

  // Calculate optionals total
  double optionalsTotal = 0;
  for (final opt in optionalItems) {
    optionalsTotal += _roundUp(opt.item.price * opt.item.qty);
  }
  // Aircraft price is the base price (fullPrice), optionals are added on top
  final aircraftOnlyPrice = fullPrice;
  final invoiceTotal = _roundUp(fullPrice + optionalsTotal);

  final totalPages = 2;

  // ==================== PAGE 1 - PROFORMA INVOICE / ITEMS ====================
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logoImage, clientName, invoiceRef, date, previsaoEntrega),
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
                          child: pw.Column(children: [
                            pw.Text('S', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text('O', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text('L', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text('D', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text('T', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text('O', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                          ]),
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
                          child: pw.Column(children: [
                            pw.Text('S', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text('H', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text('I', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text('P', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text('T', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text('O', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                          ]),
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
                        child: pw.Text(aircraftDescription, style: pw.TextStyle(fontSize: 7)),
                      ),
                      pw.Container(
                        width: 90,
                        child: pw.Text(_formatCurrencyU(aircraftOnlyPrice), style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
                      ),
                      pw.Container(
                        width: 80,
                        child: pw.Text(_formatCurrencyU(aircraftOnlyPrice), style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right),
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
              final itemTotal = _roundUp(itemPrice * itemQty);
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.3))),
                child: pw.Row(children: [
                  pw.Container(width: 30, child: pw.Text('${index + 2}', style: pw.TextStyle(fontSize: 7))),
                  pw.Container(width: 25, child: pw.Text('$itemQty', style: pw.TextStyle(fontSize: 7))),
                  pw.Expanded(child: pw.Text(item.itemName, style: pw.TextStyle(fontSize: 7))),
                  pw.Container(width: 90, child: pw.Text(_formatCurrencyU(itemPrice), style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right)),
                  pw.Container(width: 80, child: pw.Text(_formatCurrencyU(itemTotal), style: pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right)),
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

  // ==================== PAGE 2 - PAYMENT / BANKING / SIGNATURES ====================
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Condições de pagamento
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.Column(children: [
                _tableRow('Financiamento:', '$prazo anos'),
                _tableRow('Carência Inicial:', '6 meses'),
                _tableRow('Valor do Bem:', _formatCurrencyUS(fullPrice)),
                _tableRow('Deposito N° 1 - ${(sinalPercent * 100).toStringAsFixed(0)}% (ate: )', _formatCurrencyUS(sinalValor)),
                _tableRow('Deposito N° 2: - (antes da entrega)', _formatCurrencyUS(depositoValor)),
                _tableRow('Saldo:', _formatCurrencyUS(subtotal)),
                _tableRow('Risco Pais - Taxa EXIM (estimada)', _formatCurrencyUS(premium)),
                _tableRow('Total Financiado:', _formatCurrencyUS(creditoTotal)),
                _tableRow('Custo Bancário:', _formatCurrencyUS(2500)),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    '*US\$ 10,000 reembolsável apos 12 meses se não ocorrer inadimplemento nas parcelas',
                    style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ]),
            ),
            pw.SizedBox(height: 16),

            // Instruções de Pagamento (digitadas pelo usuário)
            if (instructions.isNotEmpty) ...[
              pw.Text('Instruções de Pagamento',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.Text(instructions, style: pw.TextStyle(fontSize: 9)),
              ),
              pw.SizedBox(height: 12),
            ],

            // Instruções para transferência bancária
            pw.Text('Instruções para transferência bancária',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.only(left: 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _bankInfoRow('Nome do Banco:', 'Wells Fargo Bank, N.A.'),
                  _bankInfoRow('Endereço do banco:', 'San Francisco, CA 94104 USA'),
                  _bankInfoRow('Número de Transito:', '121000248'),
                  _bankInfoRow('SWIFT:', 'WFBIUS6S'),
                  _bankInfoRow('Número da conta:', '5140101725'),
                  _bankInfoRow('Beneficiário', 'Air Tractor, Inc.'),
                ],
              ),
            ),
            // Termos do Contrato (digitados pelo usuário)
            if (terms.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('Termos do Contrato',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.Text(terms, style: pw.TextStyle(fontSize: 9)),
              ),
            ],
            pw.SizedBox(height: 24),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(children: [
                  pw.Container(width: 180, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
                  pw.SizedBox(height: 4),
                  pw.Text('Comprador', style: pw.TextStyle(fontSize: 9)),
                ]),
                pw.Column(children: [
                  pw.Container(width: 180, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
                  pw.SizedBox(height: 4),
                  pw.Text('AgSur Aviones, SA', style: pw.TextStyle(fontSize: 9)),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // SUBTOTAL / SHIPPING / INVOICE TOTAL
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(children: [
                      pw.Text('SUBTOTAL', style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(width: 8),
                      pw.Text('\$', style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(width: 8),
                      pw.Container(
                        width: 80,
                        child: pw.Text(NumberFormat("#,##0.00", "en_US").format(invoiceTotal),
                            style: pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
                      ),
                    ]),
                    pw.Row(children: [
                      pw.Text('SHIPPING', style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(width: 8),
                      pw.Text('\$', style: pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(width: 8),
                      pw.Container(
                        width: 80,
                        child: pw.Text('-', style: pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
                      ),
                    ]),
                    pw.Row(children: [
                      pw.Text('INVOICE TOTAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 8),
                      pw.Text('\$', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 8),
                      pw.Container(
                        width: 80,
                        child: pw.Text(NumberFormat("#,##0.00", "en_US").format(invoiceTotal),
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                    ]),
                    pw.Text('Todos los precios en USD',
                        style: pw.TextStyle(fontSize: 6)),
                  ],
                ),
              ],
            ),

            pw.Spacer(),

            // Legal texts at the bottom
            pw.Divider(thickness: 0.3),
            pw.SizedBox(height: 4),
            pw.Text(
              'O depósito de ${(sinalPercent * 100).toStringAsFixed(0)}% é reembolsável até 120 dias antes da data estimada de entrega. Após esse prazo, não é mais reembolsável.',
              style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Estes itens são controlados pelo Governo dos Estados Unidos e sua exportação está autorizada apenas para o pais de destino final para ser utilizado pelo consignatário ou usuário(s) finais aqui identificados. '
              'Estes itens não podem ser revendidos, transferidos, ou descartados de outra maneira, para qualquer outro país ou qualquer outra pessoa que não seja o consignatário ou usuário(s) finais autorizados, seja na '
              'sua forma original ou após ser incorporados em outros itens, sem que antes seja obtida a autorização prévia do Governo dos Estados Unidos ou conforme autorizado pelas leis e regulamentos dos Estados Unidos. EAR part 758.6',
              style: pw.TextStyle(fontSize: 5, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Na eventualidade da venda ser fechada com data de entrega agendada para o ano seguinte ao do fechamento do pedido, o preco devera ser obrigatoriamente reajustado assim que a Air Tractor emitir sua lista '
              'de precos vigente para o ano de entrega.',
              style: pw.TextStyle(fontSize: 5, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Se ocorrer atraso justificavel, que demande a substituicao da aeronave por outra para o ano subsequente ao da data de entrega contratual, o preco acordado podera ser reajustado conforme tabela Air Tractor. '
              'Caso ocorrer uma variacao inflacionaria alta na producao da aeronave durante o ano de sua fabricacao, que afete o equilibrio economico financeiro da Air Tractor, as partes desde logo acordam em renogociar '
              'os valores deste contrato, a qualquer momento, sob a pena de rescisao unilateral por parte da AgSur Aviones, SA, na falta de consenso quanto a renegociacao. Na hipotese de rescisao conforme ora mencionado, o comprador perera em favor a AgSur Aviones, SA o sinal pago de reserva da aeronave.',
              style: pw.TextStyle(fontSize: 5, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 4),
            _buildPageNumber(2, totalPages),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (_) async => pdf.save(),
  );
}

pw.Widget _bankInfoRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(children: [
      pw.Container(
        width: 120,
        child: pw.Text(label, style: pw.TextStyle(fontSize: 8)),
      ),
      pw.Text(value, style: pw.TextStyle(fontSize: 8)),
    ]),
  );
}
