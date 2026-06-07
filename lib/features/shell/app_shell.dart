import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../movements/register_movement_sheet.dart';

/// Casca do app: corpo das abas + bottom navigation + FAB de registrar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showRegisterMovementSheet(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.greenSoft,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? AppColors.green
                  : AppColors.textMuted,
            ),
          ),
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.green),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
              selectedIcon:
                  Icon(Icons.inventory_2_rounded, color: AppColors.green),
              label: 'Estoque',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.checklist_rounded, color: AppColors.green),
              label: 'Listas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded,
                  color: AppColors.textMuted),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.green),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
