// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ItemStruct extends BaseStruct {
  ItemStruct({
    String? id,
    int? qty,
    double? price,
    String? categoryId,
    String? itemName,
    String? categoryName,
  })  : _id = id,
        _qty = qty,
        _price = price,
        _categoryId = categoryId,
        _itemName = itemName,
        _categoryName = categoryName;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "qty" field.
  int? _qty;
  int get qty => _qty ?? 0;
  set qty(int? val) => _qty = val;

  void incrementQty(int amount) => qty = qty + amount;

  bool hasQty() => _qty != null;

  // "price" field.
  double? _price;
  double get price => _price ?? 0.0;
  set price(double? val) => _price = val;

  void incrementPrice(double amount) => price = price + amount;

  bool hasPrice() => _price != null;

  // "category_id" field.
  String? _categoryId;
  String get categoryId => _categoryId ?? '';
  set categoryId(String? val) => _categoryId = val;

  bool hasCategoryId() => _categoryId != null;

  // "item_name" field.
  String? _itemName;
  String get itemName => _itemName ?? '';
  set itemName(String? val) => _itemName = val;

  bool hasItemName() => _itemName != null;

  // "category_name" field.
  String? _categoryName;
  String get categoryName => _categoryName ?? '';
  set categoryName(String? val) => _categoryName = val;

  bool hasCategoryName() => _categoryName != null;

  static ItemStruct fromMap(Map<String, dynamic> data) => ItemStruct(
        id: data['id'] as String?,
        qty: castToType<int>(data['qty']),
        price: castToType<double>(data['price']),
        categoryId: data['category_id'] as String?,
        itemName: data['item_name'] as String?,
        categoryName: data['category_name'] as String?,
      );

  static ItemStruct? maybeFromMap(dynamic data) =>
      data is Map ? ItemStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'qty': _qty,
        'price': _price,
        'category_id': _categoryId,
        'item_name': _itemName,
        'category_name': _categoryName,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'qty': serializeParam(
          _qty,
          ParamType.int,
        ),
        'price': serializeParam(
          _price,
          ParamType.double,
        ),
        'category_id': serializeParam(
          _categoryId,
          ParamType.String,
        ),
        'item_name': serializeParam(
          _itemName,
          ParamType.String,
        ),
        'category_name': serializeParam(
          _categoryName,
          ParamType.String,
        ),
      }.withoutNulls;

  static ItemStruct fromSerializableMap(Map<String, dynamic> data) =>
      ItemStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        qty: deserializeParam(
          data['qty'],
          ParamType.int,
          false,
        ),
        price: deserializeParam(
          data['price'],
          ParamType.double,
          false,
        ),
        categoryId: deserializeParam(
          data['category_id'],
          ParamType.String,
          false,
        ),
        itemName: deserializeParam(
          data['item_name'],
          ParamType.String,
          false,
        ),
        categoryName: deserializeParam(
          data['category_name'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ItemStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ItemStruct &&
        id == other.id &&
        qty == other.qty &&
        price == other.price &&
        categoryId == other.categoryId &&
        itemName == other.itemName &&
        categoryName == other.categoryName;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([id, qty, price, categoryId, itemName, categoryName]);
}

ItemStruct createItemStruct({
  String? id,
  int? qty,
  double? price,
  String? categoryId,
  String? itemName,
  String? categoryName,
}) =>
    ItemStruct(
      id: id,
      qty: qty,
      price: price,
      categoryId: categoryId,
      itemName: itemName,
      categoryName: categoryName,
    );
