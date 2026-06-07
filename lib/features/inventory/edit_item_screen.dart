import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'item_form_screen.dart';

/// Carrega o item pelo id e abre o formulário de edição.
class EditItemScreen extends ConsumerWidget {
  const EditItemScreen({super.key, required this.itemId});
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemProvider(itemId)).value;
    if (item == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ItemFormScreen(item: item);
  }
}

/// Atalho para criar item novo.
class NewItemScreen extends ConsumerWidget {
  const NewItemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ItemFormScreen();
  }
}
