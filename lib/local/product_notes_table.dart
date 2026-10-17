import 'package:drift/drift.dart';

@DataClassName('ProductNoteRow')
class ProductNotes extends Table {
  IntColumn get productId => integer()();
  TextColumn get note => text()();
  IntColumn get priority => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  BoolColumn get pendingSync =>
      boolean().withDefault(const Constant(true))();

  // Un solo registro por producto
  @override
  Set<Column> get primaryKey => {productId};
}
