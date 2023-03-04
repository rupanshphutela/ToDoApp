import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

import 'package:floor/floor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:to_do_app/models_dao/app_database.dart';
import 'package:to_do_app/providers/tasks_data_store_provider.dart';

import 'package:to_do_app/utils/routes.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    print('Initializing SQLite database');
  }

  //firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);

  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    debugPrint(
        "Signed into the app with a Firebase anonymous auth temporary account\n$userCredential");
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case "operation-not-allowed":
        debugPrint("Anonymous auth hasn't been enabled for this project.");
        break;
      default:
        debugPrint("Unknown error.");
    }
  }

  //Floor sqlite
  await initializeDatabase();
  if (kDebugMode) {
    print('Loading SQLite database');
  }

  final AppDatabase database =
      await $FloorAppDatabase.databaseBuilder('the_to_do_app.sqlite').build();

  if (kDebugMode) {
    print('SQLite database is up and running');
  }
  runApp(MyApp(database));
}

Future<void> initializeDatabase() async {
  final databaseFilename =
      await sqfliteDatabaseFactory.getDatabasePath('the_to_do_app.sqlite');

  if (!(await databaseExists(databaseFilename))) {
    try {
      await Directory(dirname(databaseFilename)).create(recursive: true);
    } catch (_) {}
    ByteData data =
        await rootBundle.load(join('assets', 'the_to_do_app.sqlite'));
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(databaseFilename).writeAsBytes(bytes, flush: true);
  }
}

final _router = GoRouter(
  initialLocation: '/tasks',
  routes: routes,
);

class MyApp extends StatelessWidget {
  final AppDatabase _database;

  const MyApp(this._database, {super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreDataStore =
        FirestoreTaskDataStore(firestore: FirebaseFirestore.instance);
    final floorDataStore = FloorSqfliteTaskDataStore(_database);
    final provider = TaskDataStoreProvider(
      firestoreDataStore: firestoreDataStore,
      floorDataStore: floorDataStore,
    );
    return ChangeNotifierProvider(
      create: (context) => provider,
      child: MaterialApp.router(
        // routeInformationProvider: myGoRouter.routeInformationProvider,
        // routeInformationParser: myGoRouter.routeInformationParser,
        // routerDelegate: myGoRouter.routerDelegate,
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        routerConfig: _router,
      ),
    );
  }
}
