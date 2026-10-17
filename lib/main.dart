import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'local/app_database.dart';
import 'local/product_note_local_data_source.dart';
import 'remote/product_note_remote_data_source.dart';
import 'repositories/product_note_repository.dart';
import 'product_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final database = AppDatabase();
  final local = ProductNoteLocalDataSource(database);
  final remote = ProductNoteRemoteDataSource(
    FirebaseFirestore.instance,
  );

  final noteRepository = ProductNoteRepository(
    local: local,
    remote: remote,
  );

  runApp(MyApp(noteRepository: noteRepository));
}

class MyApp extends StatelessWidget {
  final ProductNoteRepository noteRepository;

  const MyApp({
    super.key,
    required this.noteRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vestidos de baño',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: ProductScreen(noteRepository: noteRepository),
    );
  }
}
