import '../local/product_note_local_data_source.dart';
import '../models/product_note.dart';
import '../remote/product_note_remote_data_source.dart';

class ProductNoteRepository {
  final ProductNoteLocalDataSource local;
  final ProductNoteRemoteDataSource? remote;

  ProductNoteRepository({
    required this.local,
    this.remote,
  });

  Future<ProductNote?> getNoteForProduct(int productId) =>
      local.getNoteForProduct(productId);

  Future<void> saveNote(ProductNote note) async {
    // Primero Drift y por fuera del try: la nota queda guardada
    // aunque Firebase falle o no haya internet.
    await local.saveNote(note);

    final remoteSource = remote;
    if (remoteSource == null) return;

    try {
      await remoteSource.upsertNote(note);
      await local.markSynced(note.productId);
    } catch (_) {
      // La nota ya quedó local con pendingSync = true
    }
  }

  Future<(int sent, int failed)> syncPending() async {
    final remoteSource = remote;
    if (remoteSource == null) return (0, 0);

    final pending = await local.getPendingNotes();
    var sent = 0;
    var failed = 0;

    for (final note in pending) {
      try {
        await remoteSource.upsertNote(note);
        await local.markSynced(note.productId);
        sent++;
      } catch (_) {
        // Esta nota sigue pendiente para el próximo intento
        failed++;
      }
    }

    return (sent, failed);
  }
}
