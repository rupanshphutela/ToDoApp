import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/task.dart';
import 'package:to_do_app/task_list.dart';
import 'package:to_do_app/tasks_view_model.dart';

GoRouter router = GoRouter(initialLocation: '/tasks', routes: [
  GoRoute(
    path: '/tasks',
    builder: (context, state) => TaskList(
        title: 'The To Do App Test - Tasks',
        state: state.queryParams['state'].toString()),
  ),
]);

void main() {
  testWidgets(
      'The widget that lists all the tasks - starts out with no tasks listed',
      (tester) async {
    final provider = Tasks();
    const title = 'The To Do App';
    //pump change notifier provider and Material app router
    await tester.pumpWidget(ChangeNotifierProvider<Tasks>(
      create: (context) => provider,
      child: MaterialApp.router(
        title: title,
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        routerConfig: router,
      ),
    ));

    // Create the Finders for ListView and its length, additional finder for filter
    final findListView = find.byType(ListView);
    final findListViewInitLength = tester
        .widgetList<ListView>(find.byKey(const ValueKey("ListViewKey")))
        .length;
    final findFilterText = find.text('all');

    //matcher to validate listview, its length and filter text
    expect(findListView, findsOneWidget);
    expect(findListViewInitLength, 0);
    expect(findFilterText, findsOneWidget);
  });

  // await provider.addTask(Task(
  //     taskId: '12345',
  //     taskTitle: 'Test task',
  //     description: 'YTest description',
  //     status: 'open',
  //     lastUpdate: DateTime.now(),
  //     relationship: {}));
  // await tester.pump();

  // await tester.pumpWidget(TaskList(title: "Testing"));
}
