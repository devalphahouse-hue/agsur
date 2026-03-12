// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProposalOptionalItemsStruct extends BaseStruct {
  ProposalOptionalItemsStruct({
    String? id,
    String? proposalId,
    String? aircraftItemId,
    String? createdAt,
    ItemStruct? item,
  })  : _id = id,
        _proposalId = proposalId,
        _aircraftItemId = aircraftItemId,
        _createdAt = createdAt,
        _item = item;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "proposal_id" field.
  String? _proposalId;
  String get proposalId => _proposalId ?? '';
  set proposalId(String? val) => _proposalId = val;

  bool hasProposalId() => _proposalId != null;

  // "aircraft_item_id" field.
  String? _aircraftItemId;
  String get aircraftItemId => _aircraftItemId ?? '';
  set aircraftItemId(String? val) => _aircraftItemId = val;

  bool hasAircraftItemId() => _aircraftItemId != null;

  // "created_at" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  set createdAt(String? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  // "item" field.
  ItemStruct? _item;
  ItemStruct get item => _item ?? ItemStruct();
  set item(ItemStruct? val) => _item = val;

  void updateItem(Function(ItemStruct) updateFn) {
    updateFn(_item ??= ItemStruct());
  }

  bool hasItem() => _item != null;

  static ProposalOptionalItemsStruct fromMap(Map<String, dynamic> data) =>
      ProposalOptionalItemsStruct(
        id: data['id'] as String?,
        proposalId: data['proposal_id'] as String?,
        aircraftItemId: data['aircraft_item_id'] as String?,
        createdAt: data['created_at'] as String?,
        item: data['item'] is ItemStruct
            ? data['item']
            : ItemStruct.maybeFromMap(data['item']),
      );

  static ProposalOptionalItemsStruct? maybeFromMap(dynamic data) => data is Map
      ? ProposalOptionalItemsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'proposal_id': _proposalId,
        'aircraft_item_id': _aircraftItemId,
        'created_at': _createdAt,
        'item': _item?.toMap(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'proposal_id': serializeParam(
          _proposalId,
          ParamType.String,
        ),
        'aircraft_item_id': serializeParam(
          _aircraftItemId,
          ParamType.String,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.String,
        ),
        'item': serializeParam(
          _item,
          ParamType.DataStruct,
        ),
      }.withoutNulls;

  static ProposalOptionalItemsStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      ProposalOptionalItemsStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        proposalId: deserializeParam(
          data['proposal_id'],
          ParamType.String,
          false,
        ),
        aircraftItemId: deserializeParam(
          data['aircraft_item_id'],
          ParamType.String,
          false,
        ),
        createdAt: deserializeParam(
          data['created_at'],
          ParamType.String,
          false,
        ),
        item: deserializeStructParam(
          data['item'],
          ParamType.DataStruct,
          false,
          structBuilder: ItemStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'ProposalOptionalItemsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProposalOptionalItemsStruct &&
        id == other.id &&
        proposalId == other.proposalId &&
        aircraftItemId == other.aircraftItemId &&
        createdAt == other.createdAt &&
        item == other.item;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([id, proposalId, aircraftItemId, createdAt, item]);
}

ProposalOptionalItemsStruct createProposalOptionalItemsStruct({
  String? id,
  String? proposalId,
  String? aircraftItemId,
  String? createdAt,
  ItemStruct? item,
}) =>
    ProposalOptionalItemsStruct(
      id: id,
      proposalId: proposalId,
      aircraftItemId: aircraftItemId,
      createdAt: createdAt,
      item: item ?? ItemStruct(),
    );
