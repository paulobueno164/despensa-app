import 'package:flutter/material.dart';

/// Executa [action] e informa sucesso ou erro ao usuário.
Future<bool> runSave(
  BuildContext context,
  Future<void> Function() action, {
  String? successMessage,
}) async {
  try {
    await action();
    if (!context.mounted) return true;
    if (successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    }
    return true;
  } catch (e, stack) {
    debugPrint('Falha ao salvar: $e\n$stack');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar. Tente novamente.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
    return false;
  }
}
