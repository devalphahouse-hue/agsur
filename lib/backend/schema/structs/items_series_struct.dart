// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ItemsSeriesStruct extends BaseStruct {
  ItemsSeriesStruct({
    int? qty,
    int? price,
    String? itemName,
    String? categoryName,
  })  : _qty = qty,
        _price = price,
        _itemName = itemName,
        _categoryName = categoryName;

  // "qty" field.
  int? _qty;
  int get qty => _qty ?? 0;
  set qty(int? val) => _qty = val;

  void incrementQty(int amount) => qty = qty + amount;

  bool hasQty() => _qty != null;

  // "price" field.
  int? _price;
  int get price => _price ?? 0;
  set price(int? val) => _price = val;

  void incrementPrice(int amount) => price = price + amount;

  bool hasPrice() => _price != null;

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

  static ItemsSeriesStruct fromMap(Map<String, dynamic> data) =>
      ItemsSeriesStruct(
        qty: castToType<int>(data['qty']),
        price: castToType<int>(data['price']),
        itemName: data['item_name'] as String?,
        categoryName: data['category_name'] as String?,
      );

  static ItemsSeriesStruct? maybeFromMap(dynamic data) => data is Map
      ? ItemsSeriesStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'qty': _qty,
        'price': _price,
        'item_name': _itemName,
        'category_name': _categoryName,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'qty': serializeParam(
          _qty,
          ParamType.int,
        ),
        'price': serializeParam(
          _price,
          ParamType.int,
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

  static ItemsSeriesStruct fromSerializableMap(Map<String, dynamic> data) =>
      ItemsSeriesStruct(
        qty: deserializeParam(
          data['qty'],
          ParamType.int,
          false,
        ),
        price: deserializeParam(
          data['price'],
          ParamType.int,
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
  String toString() => 'ItemsSeriesStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ItemsSeriesStruct &&
        qty == other.qty &&
        price == other.price &&
        itemName == other.itemName &&
        categoryName == other.categoryName;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([qty, price, itemName, categoryName]);
}

ItemsSeriesStruct createItemsSeriesStruct({
  int? qty,
  int? price,
  String? itemName,
  String? categoryName,
}) =>
    ItemsSeriesStruct(
      qty: qty,
      price: price,
      itemName: itemName,
      categoryName: categoryName,
    );
