// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TrackingStruct extends BaseStruct {
  TrackingStruct({
    String? id,
    String? userAircraftId,
    String? trackingDescription,
    bool? isCheck,
    String? createdAt,
    String? order,
    String? link,
    String? link2,
  })  : _id = id,
        _userAircraftId = userAircraftId,
        _trackingDescription = trackingDescription,
        _isCheck = isCheck,
        _createdAt = createdAt,
        _order = order,
        _link = link,
        _link2 = link2;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "user_aircraft_id" field.
  String? _userAircraftId;
  String get userAircraftId => _userAircraftId ?? '';
  set userAircraftId(String? val) => _userAircraftId = val;

  bool hasUserAircraftId() => _userAircraftId != null;

  // "tracking_description" field.
  String? _trackingDescription;
  String get trackingDescription => _trackingDescription ?? '';
  set trackingDescription(String? val) => _trackingDescription = val;

  bool hasTrackingDescription() => _trackingDescription != null;

  // "isCheck" field.
  bool? _isCheck;
  bool get isCheck => _isCheck ?? false;
  set isCheck(bool? val) => _isCheck = val;

  bool hasIsCheck() => _isCheck != null;

  // "created_at" field.
  String? _createdAt;
  String get createdAt => _createdAt ?? '';
  set createdAt(String? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  // "order" field.
  String? _order;
  String get order => _order ?? '';
  set order(String? val) => _order = val;

  bool hasOrder() => _order != null;

  // "link" field.
  String? _link;
  String get link => _link ?? '';
  set link(String? val) => _link = val;

  bool hasLink() => _link != null;

  // "link2" field.
  String? _link2;
  String get link2 => _link2 ?? '';
  set link2(String? val) => _link2 = val;

  bool hasLink2() => _link2 != null;

  static TrackingStruct fromMap(Map<String, dynamic> data) => TrackingStruct(
        id: data['id'] as String?,
        userAircraftId: data['user_aircraft_id'] as String?,
        trackingDescription: data['tracking_description'] as String?,
        isCheck: data['isCheck'] as bool?,
        createdAt: data['created_at'] as String?,
        order: data['order'] as String?,
        link: data['link'] as String?,
        link2: data['link2'] as String?,
      );

  static TrackingStruct? maybeFromMap(dynamic data) =>
      data is Map ? TrackingStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'user_aircraft_id': _userAircraftId,
        'tracking_description': _trackingDescription,
        'isCheck': _isCheck,
        'created_at': _createdAt,
        'order': _order,
        'link': _link,
        'link2': _link2,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'user_aircraft_id': serializeParam(
          _userAircraftId,
          ParamType.String,
        ),
        'tracking_description': serializeParam(
          _trackingDescription,
          ParamType.String,
        ),
        'isCheck': serializeParam(
          _isCheck,
          ParamType.bool,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.String,
        ),
        'order': serializeParam(
          _order,
          ParamType.String,
        ),
        'link': serializeParam(
          _link,
          ParamType.String,
        ),
        'link2': serializeParam(
          _link2,
          ParamType.String,
        ),
      }.withoutNulls;

  static TrackingStruct fromSerializableMap(Map<String, dynamic> data) =>
      TrackingStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        userAircraftId: deserializeParam(
          data['user_aircraft_id'],
          ParamType.String,
          false,
        ),
        trackingDescription: deserializeParam(
          data['tracking_description'],
          ParamType.String,
          false,
        ),
        isCheck: deserializeParam(
          data['isCheck'],
          ParamType.bool,
          false,
        ),
        createdAt: deserializeParam(
          data['created_at'],
          ParamType.String,
          false,
        ),
        order: deserializeParam(
          data['order'],
          ParamType.String,
          false,
        ),
        link: deserializeParam(
          data['link'],
          ParamType.String,
          false,
        ),
        link2: deserializeParam(
          data['link2'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'TrackingStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is TrackingStruct &&
        id == other.id &&
        userAircraftId == other.userAircraftId &&
        trackingDescription == other.trackingDescription &&
        isCheck == other.isCheck &&
        createdAt == other.createdAt &&
        order == other.order &&
        link == other.link &&
        link2 == other.link2;
  }

  @override
  int get hashCode => const ListEquality().hash([
        id,
        userAircraftId,
        trackingDescription,
        isCheck,
        createdAt,
        order,
        link,
        link2
      ]);
}

TrackingStruct createTrackingStruct({
  String? id,
  String? userAircraftId,
  String? trackingDescription,
  bool? isCheck,
  String? createdAt,
  String? order,
  String? link,
  String? link2,
}) =>
    TrackingStruct(
      id: id,
      userAircraftId: userAircraftId,
      trackingDescription: trackingDescription,
      isCheck: isCheck,
      createdAt: createdAt,
      order: order,
      link: link,
      link2: link2,
    );
