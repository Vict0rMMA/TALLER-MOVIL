import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_note.dart';

class ProductNoteRemoteDataSource {
  final FirebaseFirestore firestore;

  ProductNoteRemoteDataSource(this.firestore);

  Future<void> upsertNote(ProductNote note) async {
    // doc(productId): el mismo producto siempre cae en el mismo documento,
    // así reintentar no crea duplicados, solo lo vuelve a escribir.
    // Sin red, set() no termina hasta que vuelva la conexión; el timeout
    // hace que falle y la nota quede pendiente en Drift.
    await firestore
        .collection('product_notes')
        .doc(note.productId.toString())
        .set(note.toJson())
        .timeout(const Duration(seconds: 8));
  }
}
