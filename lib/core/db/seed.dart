import 'database.dart';

/// Inicializa apenas o perfil da despensa — sem dados de exemplo.
Future<void> seedDatabase(AppDatabase db) async {
  await db.into(db.household).insert(const HouseholdCompanion());
}
