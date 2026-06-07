import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'routing/app_router.dart';

class PantryApp extends ConsumerWidget {
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbReady = ref.watch(databaseReadyProvider);

    return dbReady.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Erro ao abrir a despensa local:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      data: (_) {
        ref.watch(expiryNotificationSyncProvider);
        return MaterialApp.router(
          title: 'Despensa',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: appRouter,
        );
      },
    );
  }
}
