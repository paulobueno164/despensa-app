import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'seed.dart';
import '../constants.dart';
import 'tables.dart';

part 'database.g.dart';

/// Categoria + número de itens nela.
class CategoryWithCount {
  CategoryWithCount(this.category, this.itemCount);
  final Category category;
  final int itemCount;
}

/// Movimentação + o item relacionado.
class MovementWithItem {
  MovementWithItem(this.movement, this.item);
  final Movement movement;
  final Item item;
}

@DriftDatabase(
  tables: [
    Categories,
    Items,
    Movements,
    ShoppingLists,
    ShoppingListItems,
    Household,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'pantry.sqlite'));
      return NativeDatabase(file);
    });
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedDatabase(this);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement('DELETE FROM shopping_list_items');
            await customStatement('DELETE FROM shopping_lists');
            await customStatement('DELETE FROM movements');
            await customStatement('DELETE FROM items');
            await customStatement('DELETE FROM categories');
            await (update(household)..where((t) => t.id.isNotNull())).write(
              HouseholdCompanion(
                displayName: Value(kDefaultHouseholdName),
              ),
            );
          }
        },
      );

  // ---------------------------------------------------------------- Perfil
  Future<HouseholdData> getHousehold() async {
    final existing = await select(household).getSingleOrNull();
    if (existing != null) return existing;
    final id =
        await into(household).insert(const HouseholdCompanion(), mode: InsertMode.insertOrReplace);
    return (select(household)..where((t) => t.id.equals(id))).getSingle();
  }

  Stream<HouseholdData?> watchHousehold() =>
      select(household).watchSingleOrNull();

  Future<void> setHouseholdName(String name) async {
    final current = await getHousehold();
    await (update(household)..where((t) => t.id.equals(current.id)))
        .write(HouseholdCompanion(displayName: Value(name)));
  }

  /// Garante que o banco abriu e o perfil existe antes de usar o app.
  Future<void> ensureInitialized() async {
    await getHousehold();
  }

  // ------------------------------------------------------------- Categorias
  Stream<List<CategoryWithCount>> watchCategoriesWithCounts() {
    final count = items.id.count();
    final query = select(categories).join([
      leftOuterJoin(items, items.categoryId.equalsExp(categories.id)),
    ])
      ..addColumns([count])
      ..groupBy([categories.id])
      ..orderBy([OrderingTerm(expression: categories.sortOrder)]);
    return query.map((row) {
      return CategoryWithCount(row.readTable(categories), row.read(count) ?? 0);
    }).watch();
  }

  Stream<List<Category>> watchCategories() =>
      (select(categories)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .watch();

  Future<List<Category>> getCategories() =>
      (select(categories)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

  // ------------------------------------------------------------------ Itens
  Stream<List<Item>> watchAllItems() =>
      (select(items)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();

  Stream<List<Item>> watchItemsByCategory(int categoryId) =>
      (select(items)..where((t) => t.categoryId.equals(categoryId))).watch();

  Stream<List<Item>> watchLowStockItems() {
    return (select(items)
          ..where((t) => t.quantity.isSmallerOrEqual(t.minQuantity))
          ..orderBy([(t) => OrderingTerm(expression: t.quantity)]))
        .watch();
  }

  /// Itens vencendo nos próximos [days] dias.
  Stream<List<Item>> watchExpiringSoon({int days = 7}) {
    final limit = DateTime.now().add(Duration(days: days));
    return (select(items)
          ..where((t) =>
              t.expiresAt.isNotNull() &
              t.expiresAt.isSmallerOrEqualValue(limit))
          ..orderBy([(t) => OrderingTerm(expression: t.expiresAt)]))
        .watch();
  }

  Stream<Item?> watchItem(int id) =>
      (select(items)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> upsertItem(ItemsCompanion item) =>
      into(items).insertOnConflictUpdate(item);

  Future<void> deleteItem(int id) =>
      (delete(items)..where((t) => t.id.equals(id))).go();

  /// Cria (id == null) ou atualiza um item a partir do formulário.
  Future<void> saveItem({
    int? id,
    required String name,
    int? categoryId,
    required double quantity,
    required String unit,
    required double minQuantity,
    double? fullQuantity,
    DateTime? expiresAt,
  }) async {
    if (id == null) {
      await into(items).insert(ItemsCompanion.insert(
        name: name,
        categoryId: Value(categoryId),
        quantity: Value(quantity),
        unit: Value(unit),
        minQuantity: Value(minQuantity),
        fullQuantity: Value(fullQuantity),
        expiresAt: Value(expiresAt),
      ));
    } else {
      await (update(items)..where((t) => t.id.equals(id))).write(ItemsCompanion(
        name: Value(name),
        categoryId: Value(categoryId),
        quantity: Value(quantity),
        unit: Value(unit),
        minQuantity: Value(minQuantity),
        fullQuantity: Value(fullQuantity),
        expiresAt: Value(expiresAt),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  // ------------------------------------------------- Categorias (CRUD)
  Future<void> saveCategory({
    int? id,
    required String name,
    required String iconKey,
    required String colorHex,
  }) async {
    if (id == null) {
      final cats = await getCategories();
      final nextOrder =
          cats.isEmpty ? 0 : cats.map((c) => c.sortOrder).reduce(math.max) + 1;
      await into(categories).insert(CategoriesCompanion.insert(
        name: name,
        iconKey: Value(iconKey),
        colorHex: Value(colorHex),
        sortOrder: Value(nextOrder),
      ));
    } else {
      await (update(categories)..where((t) => t.id.equals(id)))
          .write(CategoriesCompanion(
        name: Value(name),
        iconKey: Value(iconKey),
        colorHex: Value(colorHex),
      ));
    }
  }

  /// Exclui a categoria; os itens dela ficam "Sem categoria".
  Future<void> deleteCategory(int id) async {
    await transaction(() async {
      await (update(items)..where((t) => t.categoryId.equals(id)))
          .write(const ItemsCompanion(categoryId: Value(null)));
      await (delete(categories)..where((t) => t.id.equals(id))).go();
    });
  }

  // ----------------------------------------------------------- Movimentações
  Stream<List<MovementWithItem>> watchRecentMovements({int limit = 12}) {
    final query = select(movements).join([
      innerJoin(items, items.id.equalsExp(movements.itemId)),
    ])
      ..orderBy([OrderingTerm.desc(movements.createdAt)])
      ..limit(limit);
    return query
        .map((row) =>
            MovementWithItem(row.readTable(movements), row.readTable(items)))
        .watch();
  }

  /// Registra uma entrada ('in') ou saída ('out') e ajusta o estoque.
  Future<void> registerMovement({
    required int itemId,
    required String type,
    required double quantity,
    required String unit,
    String? note,
  }) async {
    await transaction(() async {
      await into(movements).insert(MovementsCompanion.insert(
        itemId: itemId,
        type: type,
        quantity: quantity,
        unit: unit,
        note: Value(note),
      ));
      final item =
          await (select(items)..where((t) => t.id.equals(itemId))).getSingle();
      final delta = type == 'in' ? quantity : -quantity;
      final newQty = (item.quantity + delta).clamp(0, double.infinity);
      await (update(items)..where((t) => t.id.equals(itemId))).write(
        ItemsCompanion(
          quantity: Value(newQty.toDouble()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Dá entrada no estoque a partir de um nome (cria o item se não existir).
  /// Usado pela nota fiscal e pela conclusão de listas.
  Future<void> addStockEntryByName({
    required String name,
    required double quantity,
    required String unit,
    int? categoryId,
    String? note,
  }) async {
    final existing = await (select(items)
          ..where((t) => t.name.lower().equals(name.toLowerCase())))
        .getSingleOrNull();
    final itemId = existing?.id ??
        await into(items).insert(ItemsCompanion.insert(
          name: name,
          categoryId: Value(categoryId),
          unit: Value(unit),
          minQuantity: const Value(1),
          quantity: const Value(0),
        ));
    await registerMovement(
      itemId: itemId,
      type: 'in',
      quantity: quantity,
      unit: unit,
      note: note,
    );
  }

  // ----------------------------------------------------------- Listas
  Stream<List<ShoppingList>> watchActiveLists() => (select(shoppingLists)
        ..where((t) => t.isTemplate.equals(false) & t.archived.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Stream<List<ShoppingList>> watchTemplates() => (select(shoppingLists)
        ..where((t) => t.isTemplate.equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.name)]))
      .watch();

  Stream<List<ShoppingListItem>> watchListItems(int listId) =>
      (select(shoppingListItems)
            ..where((t) => t.listId.equals(listId))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .watch();

  Stream<ShoppingList?> watchList(int id) =>
      (select(shoppingLists)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> createList(String name, {bool isTemplate = false}) =>
      into(shoppingLists).insert(
        ShoppingListsCompanion.insert(name: name, isTemplate: Value(isTemplate)),
      );

  Future<int> addListItem(ShoppingListItemsCompanion item) =>
      into(shoppingListItems).insert(item);

  /// Adiciona uma lista de nomes a uma lista de compras, ignorando os que já
  /// estão nela e vinculando ao item do estoque quando o nome coincide.
  /// Retorna quantos foram realmente adicionados.
  Future<int> addNamesToList(int listId, List<String> names) async {
    final existing = await (select(shoppingListItems)
          ..where((t) => t.listId.equals(listId)))
        .get();
    final present = existing.map((e) => e.name.toLowerCase()).toSet();
    var added = 0;
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty || present.contains(name.toLowerCase())) continue;
      final stock = await (select(items)
            ..where((t) => t.name.lower().equals(name.toLowerCase())))
          .getSingleOrNull();
      await into(shoppingListItems).insert(ShoppingListItemsCompanion.insert(
        listId: listId,
        name: name,
        itemId: Value(stock?.id),
        categoryId: Value(stock?.categoryId),
        unit: Value(stock?.unit ?? 'un'),
      ));
      present.add(name.toLowerCase());
      added++;
    }
    return added;
  }

  Future<void> setChecked(int listItemId, bool checked) =>
      (update(shoppingListItems)..where((t) => t.id.equals(listItemId)))
          .write(ShoppingListItemsCompanion(checked: Value(checked)));

  Future<void> deleteListItem(int id) =>
      (delete(shoppingListItems)..where((t) => t.id.equals(id))).go();

  Future<void> deleteList(int id) =>
      (delete(shoppingLists)..where((t) => t.id.equals(id))).go();

  /// Adiciona à lista os itens que estão acabando no estoque.
  Future<void> fillListWithLowStock(int listId) async {
    final low = await (select(items)
          ..where((t) => t.quantity.isSmallerOrEqual(t.minQuantity)))
        .get();
    final existing = await (select(shoppingListItems)
          ..where((t) => t.listId.equals(listId)))
        .get();
    final existingItemIds = existing.map((e) => e.itemId).toSet();
    await batch((b) {
      for (final it in low) {
        if (existingItemIds.contains(it.id)) continue;
        b.insert(
          shoppingListItems,
          ShoppingListItemsCompanion.insert(
            listId: listId,
            name: it.name,
            itemId: Value(it.id),
            categoryId: Value(it.categoryId),
            unit: Value(it.unit),
            quantity: Value(it.fullQuantity ?? it.minQuantity),
          ),
        );
      }
    });
  }

  /// Conclui a lista: itens marcados viram entradas no estoque.
  /// Retorna quantos itens foram para a despensa.
  Future<int> completeList(int listId) async {
    final checked = await (select(shoppingListItems)
          ..where((t) => t.listId.equals(listId) & t.checked.equals(true)))
        .get();

    await transaction(() async {
      for (final li in checked) {
        // Item novo: cria no estoque se ainda não existir.
        final itemId = li.itemId ??
            await into(items).insert(ItemsCompanion.insert(
              name: li.name,
              categoryId: Value(li.categoryId),
              unit: Value(li.unit),
              minQuantity: const Value(1),
              quantity: const Value(0),
            ));
        await registerMovementInternal(
          itemId: itemId,
          type: 'in',
          quantity: li.quantity,
          unit: li.unit,
          note: const Value('Da lista de compras'),
        );
      }
      await (update(shoppingLists)..where((t) => t.id.equals(listId))).write(
        ShoppingListsCompanion(
          archived: const Value(true),
          completedAt: Value(DateTime.now()),
        ),
      );
    });
    return checked.length;
  }

  /// Versão sem nova transação (usada dentro de completeList).
  Future<void> registerMovementInternal({
    required int itemId,
    required String type,
    required double quantity,
    required String unit,
    Value<String?> note = const Value.absent(),
  }) async {
    await into(movements).insert(MovementsCompanion.insert(
      itemId: itemId,
      type: type,
      quantity: quantity,
      unit: unit,
      note: note,
    ));
    final item =
        await (select(items)..where((t) => t.id.equals(itemId))).getSingle();
    final delta = type == 'in' ? quantity : -quantity;
    final newQty = (item.quantity + delta).clamp(0, double.infinity);
    await (update(items)..where((t) => t.id.equals(itemId))).write(
      ItemsCompanion(
        quantity: Value(newQty.toDouble()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
