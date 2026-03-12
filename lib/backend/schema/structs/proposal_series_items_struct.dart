// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ProposalSeriesItemsStruct extends BaseStruct {
  ProposalSeriesItemsStruct({
    String? itemName,
    String? itemType,
    int? qty,
    double? price,
    String? categoryId,
    String? categoryName,
  })  : _itemName = itemName,
        _itemType = itemType,
        _qty = qty,
        _price = price,
        _categoryId = categoryId,
        _categoryName = categoryName;

  // "item_name" field.
  String? _itemName;
  String get itemName => _itemName ?? '';
  set itemName(String? val) => _itemName = val;

  bool hasItemName() => _itemName != null;

  // "item_type" field.
  String? _itemType;
  String get itemType => _itemType ?? '';
  set itemType(String? val) => _itemType = val;

  bool hasItemType() => _itemType != null;

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

  // "category_name" field.
  String? _categoryName;
  String get categoryName => _categoryName ?? '';
  set categoryName(String? val) => _categoryName = val;

  bool hasCategoryName() => _categoryName != null;

  static ProposalSeriesItemsStruct fromMap(Map<String, dynamic> data) =>
      ProposalSeriesItemsStruct(
        itemName: data['item_name'] as String?,
        itemType: data['item_type'] as String?,
        qty: castToType<int>(data['qty']),
        price: castToType<double>(data['price']),
        categoryId: data['category_id'] as String?,
        categoryName: data['category_name'] as String?,
      );

  static ProposalSeriesItemsStruct? maybeFromMap(dynamic data) => data is Map
      ? ProposalSeriesItemsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'item_name': _itemName,
        'item_type': _itemType,
        'qty': _qty,
        'price': _price,
        'category_id': _categoryId,
        'category_name': _categoryName,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'item_name': serializeParam(
          _itemName,
          ParamType.String,
        ),
        'item_type': serializeParam(
          _itemType,
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
        'category_name': serializeParam(
          _categoryName,
          ParamType.String,
        ),
      }.withoutNulls;

  static ProposalSeriesItemsStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      ProposalSeriesItemsStruct(
        itemName: deserializeParam(
          data['item_name'],
          ParamType.String,
          false,
        ),
        itemType: deserializeParam(
          data['item_type'],
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
        categoryName: deserializeParam(
          data['category_name'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'ProposalSeriesItemsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ProposalSeriesItemsStruct &&
        itemName == other.itemName &&
        itemType == other.itemType &&
        qty == other.qty &&
        price == other.price &&
        categoryId == other.categoryId &&
        categoryName == other.categoryName;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([itemName, itemType, qty, price, categoryId, categoryName]);
}

ProposalSeriesItemsStruct createProposalSeriesItemsStruct({
  String? itemName,
  String? itemType,
  int? qty,
  double? price,
  String? categoryId,
  String? categoryName,
}) =>
    ProposalSeriesItemsStruct(
      itemName: itemName,
      itemType: itemType,
      qty: qty,
      price: price,
      categoryId: categoryId,
      categoryName: categoryName,
    );
