import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';

String fileNamePath(String path) {
  // function for catch de name of the archive uploaded in storage
  // Function to extract the file name from a storage path
  List<String> segments = path.split('/');
  return segments.last;
}

String formatarMoedaBrasileira(String entrada) {
  String apenasNumeros = entrada.replaceAll(RegExp(r'[^0-9]'), '');
  if (apenasNumeros.isEmpty) {
    return 'R\$ 0,00';
  }
  double valor = double.parse(apenasNumeros) / 100;

  String formatado =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  print(formatado);
  return formatado;
}

String? convertToImagePath(String urlPhoto) {
  // Verifica se a URL é vazia ou nula, retorna um ImagePath padrão se for o caso
  if (urlPhoto == null || urlPhoto.isEmpty) {
    return 'https://bkzybtmxxzpxtztesdye.supabase.co/storage/v1/object/public/AGSur//Design%20sem%20nome%20(13).png'; // Placeholder caso a URL seja inválida
  }
  // Retorna a URL como string, que o FlutterFlow aceita como ImagePath
  return urlPhoto;
}

String formatPercent(String inputValue) {
  if (inputValue.isEmpty) return '';

  // Remove % e tudo que não é número
  String clean = inputValue.replaceAll(RegExp(r'[^0-9]'), '');

  if (clean.isEmpty) return '';

  // Converte para número e divide por 10 para criar a % conforme regra
  double value = int.parse(clean) / 10;

  // Formata com máximo de 2 casas, sem zeros desnecessários
  String formatted = value.toString().replaceAll(RegExp(r'\.0+$'), '');

  return "$formatted%";
}

String generateRandomSixDigitCode() {
  // Cria uma instância de Random
  final random = math.Random();

  // Gera um número aleatório entre 0 e 999999 (inclusive)
  int randomNumber = random.nextInt(1000000); // 0 a 999999

  // Formata o número pra ter exatamente 6 dígitos, preenchendo com zeros à esquerda
  return randomNumber.toString().padLeft(6, '0');
}

DateTime timetodate(String createdAt) {
  // transforme o timestamptz em data dd/MM/yyyy
// Parse the timestamp string to DateTime
  DateTime dateTime = DateTime.parse(createdAt);
  // Format the DateTime to dd/MM/yyyy
  String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
  // Return the DateTime object
  return DateFormat('dd/MM/yyyy').parse(formattedDate);
}

DateTime subtractDate(DateTime data) {
  // subtraia 60 dias do argumento data e formate em dd/MM/yyyy
  return data.subtract(Duration(days: 60));
}

DateTime addDate(DateTime dataAdd) {
  // adicione ao argumento dataAdd 45 dias
  return dataAdd.add(Duration(days: 45));
}

String formatarMoedaEmDolar(String entradaDolar) {
  String apenasNumeros = entradaDolar.replaceAll(RegExp(r'[^0-9]'), '');
  if (apenasNumeros.isEmpty) {
    return '\$0.00';
  }
  double valor = double.parse(apenasNumeros) / 100;

  String formatado =
      NumberFormat.currency(locale: 'en_US', symbol: '\$').format(valor);
  print(formatado);
  return formatado;
}

double textToNumeric(String textValue) {
  final cleaned = textValue.replaceAll(RegExp(r'[^\d.]'), '');
  return double.tryParse(cleaned) ?? 0.0;
}

double? parsePriceToDouble(String price) {
  if (price.isEmpty) return 0.0;

  String clean = price.replaceAll(RegExp(r'[^0-9.,]'), '');

  // Formato americano: decimal = ponto
  if (clean.contains('.') && clean.lastIndexOf('.') > clean.lastIndexOf(',')) {
    clean = clean.replaceAll(',', '');

    return double.tryParse(clean) ?? 0.0;
  }

  // Formato brasileiro: decimal = vírgula
  if (clean.contains(',')) {
    clean = clean.replaceAll('.', '');
    clean = clean.replaceFirst(',', '.');

    return double.tryParse(clean) ?? 0.0;
  }

  // Sem separadores
  return double.tryParse(clean) ?? 0.0;
}

bool checkItem(
  List<ProposalOptionalItemsStruct> optional,
  String id,
) {
  return optional.any((optionalItem) =>
      optionalItem.item != null && optionalItem.item!.id == id);
}
