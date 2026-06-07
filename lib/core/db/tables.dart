import 'package:drift/drift.dart';

import '../constants.dart';

/// Categorias de produtos (Alimentos, Limpeza, Higiene...).
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get iconKey => text().withDefault(const Constant('dots'))();
  TextColumn get colorHex => text().withDefault(const Constant('3C6E5C'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Itens do estoque (a despensa em si).
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  /// Quantidade atual em estoque.
  RealColumn get quantity => real().withDefault(const Constant(0))();
  TextColumn get unit => text().withDefault(const Constant('un'))();

  /// Abaixo (ou igual) deste valor o item entra em "está acabando".
  RealColumn get minQuantity => real().withDefault(const Constant(0))();

  /// Quantidade considerada "cheio" (100% da barra de progresso).
  RealColumn get fullQuantity => real().nullable()();

  /// Rótulo qualitativo opcional, ex.: "Quase vazio".
  TextColumn get lowLabel => text().nullable()();

  TextColumn get note => text().nullable()();
  TextColumn get imagePath => text().nullable()();

  /// Data de validade (alerta de vencimento).
  DateTimeColumn get expiresAt => dateTime().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Movimentações de estoque (entradas e saídas).
class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId =>
      integer().references(Items, #id, onDelete: KeyAction.cascade)();

  /// 'in' (entrada / compra) ou 'out' (saída / retirada).
  TextColumn get type => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Listas de compras (ativas, concluídas ou modelos salvos).
class ShoppingLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// Lista salva/modelo reutilizável (ex.: "Frutas").
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Itens dentro de uma lista de compras.
class ShoppingListItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId =>
      integer().references(ShoppingLists, #id, onDelete: KeyAction.cascade)();

  /// Vínculo opcional com um item do estoque (null = ainda não existe).
  IntColumn get itemId => integer().nullable().references(Items, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant('un'))();

  /// "Já peguei" — marcado durante a compra.
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Perfil único do app (a família / despensa).
class Household extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName =>
      text().withDefault(Constant(kDefaultHouseholdName))();
  TextColumn get avatarKey => text().nullable()();
}
