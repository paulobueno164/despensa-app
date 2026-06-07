import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/receipt_scan_screen.dart';
import '../features/ai/recipes_screen.dart';
import '../features/home/home_screen.dart';
import '../features/inventory/edit_item_screen.dart';
import '../features/inventory/expiring_soon_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/inventory/item_detail_screen.dart';
import '../features/inventory/low_stock_screen.dart';
import '../features/lists/list_detail_screen.dart';
import '../features/lists/lists_screen.dart';
import '../features/profile/categories_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/inicio',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/inicio',
            builder: (context, state) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/estoque',
            builder: (context, state) => const InventoryScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/listas',
            builder: (context, state) => const ListsScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/item/novo',
      builder: (context, state) => const NewItemScreen(),
    ),
    GoRoute(
      path: '/item/:id',
      builder: (context, state) => ItemDetailScreen(
        itemId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/item/:id/editar',
      builder: (context, state) => EditItemScreen(
        itemId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/acabando',
      builder: (context, state) => const LowStockScreen(),
    ),
    GoRoute(
      path: '/vencendo',
      builder: (context, state) => const ExpiringSoonScreen(),
    ),
    GoRoute(
      path: '/categorias',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/category/:id',
      builder: (context, state) => InventoryScreen(
        initialCategoryId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/lista/:id',
      builder: (context, state) => ListDetailScreen(
        listId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/receitas',
      builder: (context, state) => const RecipesScreen(),
    ),
    GoRoute(
      path: '/nota',
      builder: (context, state) => const ReceiptScanScreen(),
    ),
  ],
);
