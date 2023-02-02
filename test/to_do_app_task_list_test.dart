/**Does not find ListView or a thing 
 * https://guillaume.bernos.dev/testing-go-router/
*/
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  });
}
