import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/core/db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('saveCategory e saveItem persistem no banco', () async {
    await db.into(db.household).insert(const HouseholdCompanion());

    await db.saveCategory(
      name: 'Alimentos',
      iconKey: 'basket',
      colorHex: '3C6E5C',
    );

    final cats = await db.getCategories();
    expect(cats, hasLength(1));
    expect(cats.first.name, 'Alimentos');

    await db.saveItem(
      name: 'Arroz',
      categoryId: cats.first.id,
      quantity: 2,
      unit: 'kg',
      minQuantity: 1,
    );

    final items = await db.watchAllItems().first;
    expect(items, hasLength(1));
    expect(items.first.name, 'Arroz');
    expect(items.first.quantity, 2);
  });

  test('createList e addListItem persistem', () async {
    final listId = await db.createList('Compra da semana');
    await db.addListItem(
      ShoppingListItemsCompanion.insert(
        listId: listId,
        name: 'Leite',
        quantity: const Value(2),
        unit: const Value('L'),
      ),
    );

    final items = await db.watchListItems(listId).first;
    expect(items, hasLength(1));
    expect(items.first.name, 'Leite');
  });
}
