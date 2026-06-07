import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }
  await initializeDateFormatting('pt_BR', null);

  try {
    await NotificationService.instance.init();
  } catch (e, stack) {
    debugPrint('Notificações indisponíveis: $e\n$stack');
  }

  runApp(const ProviderScope(child: PantryApp()));
}
