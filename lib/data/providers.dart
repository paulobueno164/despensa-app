import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import '../core/format/formatters.dart';
import '../core/notifications/notification_service.dart';

/// Instância única do banco para todo o app.
final databaseProvider = Provider<AppDatabase>((ref) {
  ref.keepAlive();
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Abre o SQLite local e garante o registro do perfil.
final databaseReadyProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  await ref.watch(databaseProvider).ensureInitialized();
});

// ------------------------------------------------------------------ Perfil
final householdProvider = StreamProvider<HouseholdData?>((ref) {
  return ref.watch(databaseProvider).watchHousehold();
});

// --------------------------------------------------------------- Categorias
final categoriesWithCountsProvider =
    StreamProvider<List<CategoryWithCount>>((ref) {
  return ref.watch(databaseProvider).watchCategoriesWithCounts();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).watchCategories();
});

// -------------------------------------------------------------------- Itens
final allItemsProvider = StreamProvider<List<Item>>((ref) {
  return ref.watch(databaseProvider).watchAllItems();
});

final itemsByCategoryProvider =
    StreamProvider.family<List<Item>, int>((ref, categoryId) {
  return ref.watch(databaseProvider).watchItemsByCategory(categoryId);
});

final itemProvider = StreamProvider.family<Item?, int>((ref, id) {
  return ref.watch(databaseProvider).watchItem(id);
});

/// Itens acabando, ordenados por urgência (fração do estoque restante).
final lowStockProvider = Provider<List<Item>>((ref) {
  final items = ref.watch(allItemsProvider).value ?? const [];
  final low = items.where((i) => i.quantity <= i.minQuantity).toList();
  double frac(Item i) => i.minQuantity == 0 ? 0 : i.quantity / i.minQuantity;
  low.sort((a, b) => frac(a).compareTo(frac(b)));
  return low;
});

final expiringSoonProvider = StreamProvider<List<Item>>((ref) {
  return ref.watch(databaseProvider).watchExpiringSoon();
});

/// Itens vencendo nos próximos 7 dias, do mais urgente ao menos.
final expiringSoonListProvider = Provider<List<Item>>((ref) {
  final items = ref.watch(expiringSoonProvider).value ?? const [];
  final sorted = [...items];
  sorted.sort((a, b) {
    final da = daysUntil(a.expiresAt!);
    final db = daysUntil(b.expiresAt!);
    return da.compareTo(db);
  });
  return sorted;
});

/// Mantém as notificações locais sincronizadas com o estoque.
final expiryNotificationSyncProvider = Provider<void>((ref) {
  ref.listen(allItemsProvider, (_, next) {
    next.whenData((items) {
      NotificationService.instance.syncExpiryNotifications(items);
    });
  }, fireImmediately: true);
});

// ----------------------------------------------------------- Movimentações
final recentMovementsProvider =
    StreamProvider<List<MovementWithItem>>((ref) {
  return ref.watch(databaseProvider).watchRecentMovements();
});

// ------------------------------------------------------------------- Stats
class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.low,
    required this.expiring,
    required this.attention,
    required this.categories,
  });
  final int total;
  final int low;
  final int expiring;
  /// Itens únicos que precisam de atenção (estoque baixo ou validade).
  final int attention;
  final int categories;
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final items = ref.watch(allItemsProvider).value ?? const [];
  final cats = ref.watch(categoriesWithCountsProvider).value ?? const [];
  final low = items.where((i) => i.quantity <= i.minQuantity).length;
  final expiring = items
      .where((i) => i.expiresAt != null && daysUntil(i.expiresAt!) <= 7)
      .length;
  final attentionIds = {
    ...items.where((i) => i.quantity <= i.minQuantity).map((i) => i.id),
    ...items
        .where((i) => i.expiresAt != null && daysUntil(i.expiresAt!) <= 7)
        .map((i) => i.id),
  };
  return DashboardStats(
    total: items.length,
    low: low,
    expiring: expiring,
    attention: attentionIds.length,
    categories: cats.length,
  );
});

// ------------------------------------------------------------------ Listas
final activeListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  return ref.watch(databaseProvider).watchActiveLists();
});

final templateListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  return ref.watch(databaseProvider).watchTemplates();
});

final listProvider = StreamProvider.family<ShoppingList?, int>((ref, id) {
  return ref.watch(databaseProvider).watchList(id);
});

final listItemsProvider =
    StreamProvider.family<List<ShoppingListItem>, int>((ref, listId) {
  return ref.watch(databaseProvider).watchListItems(listId);
});
