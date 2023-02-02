import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:to_do_app/routes.dart';
import 'package:to_do_app/tasks_view_model.dart';

final _router = GoRouter(initialLocation: '/tasks', routes: routes);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Tasks(),
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
