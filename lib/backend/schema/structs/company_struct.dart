// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CompanyStruct extends BaseStruct {
  CompanyStruct({
    String? id,
    String? companyName,
    String? cnpj,
    String? phone,
    String? cpf,
    String? typeDoc,
  })  : _id = id,
        _companyName = companyName,
        _cnpj = cnpj,
        _phone = phone,
        _cpf = cpf,
        _typeDoc = typeDoc;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "company_name" field.
  String? _companyName;
  String get companyName => _companyName ?? '';
  set companyName(String? val) => _companyName = val;

  bool hasCompanyName() => _companyName != null;

  // "cnpj" field.
  String? _cnpj;
  String get cnpj => _cnpj ?? '';
  set cnpj(String? val) => _cnpj = val;

  bool hasCnpj() => _cnpj != null;

  // "phone" field.
  String? _phone;
  String get phone => _phone ?? '';
  set phone(String? val) => _phone = val;

  bool hasPhone() => _phone != null;

  // "cpf" field.
  String? _cpf;
  String get cpf => _cpf ?? '';
  set cpf(String? val) => _cpf = val;

  bool hasCpf() => _cpf != null;

  // "type_doc" field.
  String? _typeDoc;
  String get typeDoc => _typeDoc ?? '1';
  set typeDoc(String? val) => _typeDoc = val;

  bool hasTypeDoc() => _typeDoc != null;

  static CompanyStruct fromMap(Map<String, dynamic> data) => CompanyStruct(
        id: data['id'] as String?,
        companyName: data['company_name'] as String?,
        cnpj: data['cnpj'] as String?,
        phone: data['phone'] as String?,
        cpf: data['cpf'] as String?,
        typeDoc: data['type_doc'] as String?,
      );

  static CompanyStruct? maybeFromMap(dynamic data) =>
      data is Map ? CompanyStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'company_name': _companyName,
        'cnpj': _cnpj,
        'phone': _phone,
        'cpf': _cpf,
        'type_doc': _typeDoc,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'company_name': serializeParam(
          _companyName,
          ParamType.String,
        ),
        'cnpj': serializeParam(
          _cnpj,
          ParamType.String,
        ),
        'phone': serializeParam(
          _phone,
          ParamType.String,
        ),
        'cpf': serializeParam(
          _cpf,
          ParamType.String,
        ),
        'type_doc': serializeParam(
          _typeDoc,
          ParamType.String,
        ),
      }.withoutNulls;

  static CompanyStruct fromSerializableMap(Map<String, dynamic> data) =>
      CompanyStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        companyName: deserializeParam(
          data['company_name'],
          ParamType.String,
          false,
        ),
        cnpj: deserializeParam(
          data['cnpj'],
          ParamType.String,
          false,
        ),
        phone: deserializeParam(
          data['phone'],
          ParamType.String,
          false,
        ),
        cpf: deserializeParam(
          data['cpf'],
          ParamType.String,
          false,
        ),
        typeDoc: deserializeParam(
          data['type_doc'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'CompanyStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is CompanyStruct &&
        id == other.id &&
        companyName == other.companyName &&
        cnpj == other.cnpj &&
        phone == other.phone &&
        cpf == other.cpf &&
        typeDoc == other.typeDoc;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([id, companyName, cnpj, phone, cpf, typeDoc]);
}

CompanyStruct createCompanyStruct({
  String? id,
  String? companyName,
  String? cnpj,
  String? phone,
  String? cpf,
  String? typeDoc,
}) =>
    CompanyStruct(
      id: id,
      companyName: companyName,
      cnpj: cnpj,
      phone: phone,
      cpf: cpf,
      typeDoc: typeDoc,
    );
