import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_note.dart';

class ProductNoteRemoteDataSource {
  final FirebaseFirestore firestore;

  ProductNoteRemoteDataSource(this.firestore);

  Future<void> upsertNote(ProductNote note) async {
    await firestore
        .collection('product_notes')
        .doc(note.productId.toString())
        .set(note.toJson())
        .timeout(const Duration(seconds: 8));
  }
}
