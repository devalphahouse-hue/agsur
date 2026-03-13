// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProposalCompanyStruct extends BaseStruct {
  ProposalCompanyStruct({
    String? id,
    String? companyName,
    String? cnpj,
    String? phone,
    String? typeDoc,
    String? cpf,
    String? stateRegistration,
  })  : _id = id,
        _companyName = companyName,
        _cnpj = cnpj,
        _phone = phone,
        _typeDoc = typeDoc,
        _cpf = cpf,
        _stateRegistration = stateRegistration;

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

  // "type_doc" field.
  String? _typeDoc;
  String get typeDoc => _typeDoc ?? '';
  set typeDoc(String? val) => _typeDoc = val;

  bool hasTypeDoc() => _typeDoc != null;

  // "cpf" field.
  String? _cpf;
  String get cpf => _cpf ?? '';
  set cpf(String? val) => _cpf = val;

  bool hasCpf() => _cpf != null;

  // "state_registration" field.
  String? _stateRegistration;
  String get stateRegistration => _stateRegistration ?? '';
  set stateRegistration(String? val) => _stateRegistration = val;

  bool hasStateRegistration() => _stateRegistration != null;

  static ProposalCompanyStruct fromMap(Map<String, dynamic> data) =>
      ProposalCompanyStruct(
        id: data['id'] as String?,
        companyName: data['company_name'] as String?,
        cnpj: data['cnpj'] as String?,
        phone: data['phone'] as String?,
        typeDoc: data['type_doc'] as String?,
        cpf: data['cpf'] as String?,
        stateRegistration: data['state_registration'] as String?,
      );

  static ProposalCompanyStruct? maybeFromMap(dynamic data) => data is Map
      ? ProposalCompanyStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'company_name': _companyName,
        'cnpj': _cnpj,
        'phone': _phone,
        'type_doc': _typeDoc,
        'cpf': _cpf,
        'state_registration': _stateRegistration,
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
        'type_doc': serializeParam(
          _typeDoc,
          ParamType.String,
        ),
        'cpf': serializeParam(
          _cpf,
          ParamType.String,
        ),
        'state_registration': serializeParam(
          _stateRegistration,
          ParamType.String,
        ),
      }.withoutNulls;

  static ProposalCompanyStruct fromSerializableMap(Map<String, dynamic> data) =>
      ProposalCompanyStruct(
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
        typeDoc: deserializeParam(
          data['type_doc'],
          ParamType.String,
          false,
        ),
        cpf: deserializeParam(
          data['cpf'],
          ParamType.String,
          false,
        ),
        stateRegistration: deserializeParam(
          data['state_registration'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ProposalCompanyStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProposalCompanyStruct &&
        id == other.id &&
        companyName == other.companyName &&
        cnpj == other.cnpj &&
        phone == other.phone &&
        typeDoc == other.typeDoc &&
        cpf == other.cpf &&
        stateRegistration == other.stateRegistration;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([id, companyName, cnpj, phone, typeDoc, cpf, stateRegistration]);
}

ProposalCompanyStruct createProposalCompanyStruct({
  String? id,
  String? companyName,
  String? cnpj,
  String? phone,
  String? typeDoc,
  String? cpf,
  String? stateRegistration,
}) =>
    ProposalCompanyStruct(
      id: id,
      companyName: companyName,
      cnpj: cnpj,
      phone: phone,
      typeDoc: typeDoc,
      cpf: cpf,
      stateRegistration: stateRegistration,
    );
