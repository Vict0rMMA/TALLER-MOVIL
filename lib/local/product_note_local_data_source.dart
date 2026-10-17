import 'package:drift/drift.dart';

import '../models/product_note.dart';
import 'app_database.dart';

class ProductNoteLocalDataSource {
  final AppDatabase db;

  ProductNoteLocalDataSource(this.db);

  ProductNote _toDomain(ProductNoteRow row) {
    return ProductNote(
      productId: row.productId,
      note: row.note,
      priority: row.priority,
      updatedAt: row.updatedAt,
      pendingSync: row.pendingSync,
    );
  }

  Future<ProductNote?> getNoteForProduct(int productId) async {
    final query = db.select(db.productNotes)
      ..where((t) => t.productId.equals(productId));

    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> saveNote(ProductNote note) async {
    await db.into(db.productNotes).insertOnConflictUpdate(
          ProductNotesCompanion.insert(
            productId: Value(note.productId),
            note: note.note,
            priority: note.priority,
            updatedAt: note.updatedAt,
            pendingSync: const Value(true),
          ),
        );
  }

  Future<List<ProductNote>> getPendingNotes() async {
    final rows = await (db.select(db.productNotes)
          ..where((t) => t.pendingSync.equals(true)))
        .get();

    return rows.map(_toDomain).toList();
  }

  Future<void> markSynced(int productId) async {
    await (db.update(db.productNotes)
          ..where((t) => t.productId.equals(productId)))
        .write(
      const ProductNotesCompanion(
        pendingSync: Value(false),
      ),
    );
  }
}
