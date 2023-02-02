import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/task.dart';
import 'package:to_do_app/task_details.dart';
import 'package:to_do_app/task_form.dart';
import 'package:to_do_app/task_list.dart';
import 'package:to_do_app/tasks_view_model.dart';

const title = 'The To Do App';
final provider = Tasks();

extension WithScaffold on WidgetTester {
  pumpWithRouter(GoRouter router) async =>
      pumpWidget(ChangeNotifierProvider<Tasks>(
          create: (context) => provider,
          child: MaterialApp.router(routerConfig: router)));
}

void main() {
  testWidgets(
      'The widget that lists all the tasks - starts out with no tasks listed',
      (tester) async {
    final router = GoRouter(initialLocation: '/tasks', routes: [
      GoRoute(
        path: '/tasks',
        builder: (context, state) => TaskList(
          title: '$title - Tasks',
          state: state.queryParams['state'].toString(),
        ),
      ),
      GoRoute(
        path: '/task',
        builder: (context, state) => TaskForm(
          title: '$title - Task Form',
        ),
      ),
      GoRoute(
          path: '/taskdetail',
          builder: (context, state) {
            final String taskId = state.queryParams['task_id'].toString();
            return TaskDetails(
                selectedTaskId: taskId, title: '$title - Task Details');
          }),
    ]);

    //pump change notifier provider and Material app router
    await tester.pumpWithRouter(router);
    await tester.pumpAndSettle();

    final findListView = find.byType(ListView);
    final findListViewInitLength = tester
        .widgetList<ListView>(find.byKey(const ValueKey("ListViewKey")))
        .length;
    final findFilterText = find.text('all');

    //matcher to validate listview, its length and filter text
    expect(findListView, findsOneWidget);
    expect(findListViewInitLength, 0);
    expect(findFilterText, findsOneWidget);

    //find add task button
    final findAddTaskButton = find.byTooltip('Add Task');

    //matcher
    expect(findAddTaskButton, findsOneWidget);

    //tap the Add Task button
    await tester.tap(findAddTaskButton);
    await tester.pumpAndSettle();

    final findTextFormFields = find.byType(TextFormField);

    //matcher
    expect(findTextFormFields, findsNWidgets(2));

    //goback on tapping back
    await tester.tap(find.byTooltip('Back'));
    //wait for operation to finish
    await tester.pumpAndSettle();
    //matcher for validating that back worked
    expect(findListView, findsOneWidget);

    //Create 2 provider tasks with different status
    for (var index = 1; index <= 2; index++) {
      provider.addTask(Task(
          taskId: UniqueKey().hashCode.toString(),
          taskTitle: "Dummy Title $index",
          description: "Dummy Description $index",
          status: index == 1 ? "open" : "in progress",
          lastUpdate: DateTime.now(),
          relationship: {}));
    }
    //wait for tasks to create
    await tester.pump();
    //finder for number of list tiles
    final findListTile = find.byType(ListTile);
    //matcher to validate number of created tiles
    expect(findListTile, findsNWidgets(2));

    //tap the dropdown
    await tester.tap(findFilterText);
    //wait for operation to finish
    await tester.pumpAndSettle();
    //find the open text in dropdown and tap it
    await tester.tap(find.text('open').last);
    //wait for operation to finish
    await tester.pumpAndSettle();
    //Matcher to validate finding one ListTile
    expect(findListTile, findsNWidgets(1));
  });
}
