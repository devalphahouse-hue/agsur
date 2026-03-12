import 'package:collection/collection.dart';

enum ProfileType {
  AdminMaster,
  Admin,
  Cliente,
  Oficina,
  Piloto,
  Vendedor,
}

enum UserStatus {
  pending,
  approved,
  blocked,
  refused,
}

enum ItemType {
  series,
  optional,
}

enum AircraftStatus {
  available,
  delivered,
  processing,
}

enum FinancialType {
  income,
  expense,
}

enum FinancialStatus {
  pending,
  paid,
  received,
  overdue,
}

enum TupeServicesOffering {
  service_letter,
  service_boletim,
  airworthiness_directives,
}

enum AircraftItemType {
  series,
  optional,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (ProfileType):
      return ProfileType.values.deserialize(value) as T?;
    case (UserStatus):
      return UserStatus.values.deserialize(value) as T?;
    case (ItemType):
      return ItemType.values.deserialize(value) as T?;
    case (AircraftStatus):
      return AircraftStatus.values.deserialize(value) as T?;
    case (FinancialType):
      return FinancialType.values.deserialize(value) as T?;
    case (FinancialStatus):
      return FinancialStatus.values.deserialize(value) as T?;
    case (TupeServicesOffering):
      return TupeServicesOffering.values.deserialize(value) as T?;
    case (AircraftItemType):
      return AircraftItemType.values.deserialize(value) as T?;
    default:
      return null;
  }
}
