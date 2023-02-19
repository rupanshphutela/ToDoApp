import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

import 'package:floor/floor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:to_do_app/models_dao/app_database.dart';

import 'package:to_do_app/routes.dart';
import 'package:to_do_app/tasks_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    print('initializing database');
  }
  await initializeDatabase();
  if (kDebugMode) {
    print('loading database');
  }
  final AppDatabase database =
      await $FloorAppDatabase.databaseBuilder('the_to_do_app.sqlite').build();

  if (kDebugMode) {
    print('running app');
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
    return ChangeNotifierProvider(
      create: (context) => Tasks(_database),
      child: MaterialApp.router(
        title: title,
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
