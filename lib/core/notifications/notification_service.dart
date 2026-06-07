import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../db/database.dart';
import '../format/formatters.dart';

/// Notificações locais de validade — sem serviço externo.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;

  static const _channel = AndroidNotificationChannel(
    'expiry_alerts',
    'Validade dos produtos',
    description: 'Avisos quando um produto está perto de vencer',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_ready) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    _ready = true;
  }

  /// Reagenda avisos com base nos itens atuais do estoque.
  Future<void> syncExpiryNotifications(List<Item> items) async {
    if (!_ready) return;

    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    for (final item in items) {
      final expiresAt = item.expiresAt;
      if (expiresAt == null) continue;

      final expiryDay = tz.TZDateTime(
        tz.local,
        expiresAt.year,
        expiresAt.month,
        expiresAt.day,
        9,
      );

      if (!expiryDay.isBefore(now)) {
        await _schedule(
          id: item.id * 2,
          when: expiryDay,
          title: 'Validade hoje',
          body: '${item.name} vence hoje.',
        );
      }

      final dayBefore = expiryDay.subtract(const Duration(days: 1));
      if (!dayBefore.isBefore(now)) {
        await _schedule(
          id: item.id * 2 + 1,
          when: dayBefore,
          title: 'Validade amanhã',
          body: '${item.name} ${expiryLabel(expiresAt).toLowerCase()}.',
        );
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Falha ao agendar notificação $id: $e');
    }
  }
}
