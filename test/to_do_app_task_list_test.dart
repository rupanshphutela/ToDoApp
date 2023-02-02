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
  pumpWithRouter() async => pumpWidget(ChangeNotifierProvider<Tasks>(
      create: (context) => provider,
      child: MaterialApp.router(
          routerConfig: GoRouter(initialLocation: '/tasks', routes: [
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
      ]))));
}

void main() {
  group('The widget that lists all the tasks:', () {
    testWidgets('starts out with no tasks listed', (tester) async {
      //pump change notifier provider and Material app router
      await tester.pumpWithRouter();
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
    });

    testWidgets(
        'has a button that when clicked tells the navigator/router to go to the widget for creating a new task*',
        (tester) async {
      //pump change notifier provider and Material app router
      await tester.pumpWithRouter();
      await tester.pumpAndSettle();
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

    testWidgets(
        'shows a separate widget for each task when there are tasks to list',
        (tester) async {
      //pump change notifier provider and Material app router
      await tester.pumpWithRouter();
      await tester.pumpAndSettle();

      //Create 2 provider tasks with different status
      for (var index = 0; index < 2; index++) {
        provider.addTask(Task(
            taskId: UniqueKey().hashCode.toString(),
            taskTitle: "Dummy Title $index",
            description: "Dummy Description $index",
            status: index == 0 ? "open" : "in progress",
            lastUpdate: DateTime.now(),
            relationship: {}));
      }
      //wait for tasks to create
      await tester.pump();
      //finder for number of list tiles
      final findListTile = find.byType(ListTile);
      //matcher to validate number of created tiles
      expect(findListTile, findsNWidgets(2));
    });
    testWidgets('shows only some of the tasks when a filter is applied.',
        (tester) async {
      //pump change notifier provider and Material app router
      await tester.pumpWithRouter();
      await tester.pumpAndSettle();

      final findFilterText = find.text('all');
      final findListTile = find.byType(ListTile);

      //Create 2 provider tasks with different status
      for (var index = 0; index < 2; index++) {
        provider.addTask(Task(
            taskId: UniqueKey().hashCode.toString(),
            taskTitle: "Dummy Title $index",
            description: "Dummy Description $index",
            status: index == 0 ? "open" : "in progress",
            lastUpdate: DateTime.now(),
            relationship: {}));
      }
      //wait for tasks to create
      await tester.pump();

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
  });

  group('Each task listed in the widget that lists all the tasks:', () {
    testWidgets('Indicates the name of the task', (tester) async {
      //pump change notifier provider and Material app router
      await tester.pumpWithRouter();
      await tester.pumpAndSettle();

      //Create 2 provider tasks with different status
      for (var index = 0; index < 2; index++) {
        provider.addTask(Task(
            taskId: UniqueKey().hashCode.toString(),
            taskTitle: "Dummy Title $index",
            description: "Dummy Description $index",
            status: index == 0 ? "open" : "in progress",
            lastUpdate: DateTime.now(),
            relationship: {}));
      }

      //wait for tasks to create
      await tester.pumpAndSettle();

      final findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      for (var index = 0; index < findListTileLength; index++) {
        expect(find.text('Dummy Title $index'), findsOneWidget);
      }
    });

    testWidgets(
        'has a button that when clicked tells the navigator/router to go to the widget for editing an existing task',
        (tester) async {
      await tester.pumpWithRouter();
      await tester.pumpAndSettle();

      //Create 2 provider tasks with different status
      for (var index = 0; index < 2; index++) {
        provider.addTask(Task(
            taskId: UniqueKey().hashCode.toString(),
            taskTitle: "Dummy Title $index",
            description: "Dummy Description $index",
            status: index == 0 ? "open" : "in progress",
            lastUpdate: DateTime.now(),
            relationship: {}));
      }

      //wait for tasks to create
      await tester.pumpAndSettle();

      final findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      for (var index = findListTileLength - 1; index <= 0; index--) {
        final findEditTaskButton = find.byKey(ValueKey("editTaskButton$index"));
        await tester.tap(findEditTaskButton);
        await tester.pumpAndSettle();
        //matcher
        expect(find.text('Dummy Title $index'), findsOneWidget);
        //goback on tapping back
        await tester.tap(find.byTooltip('Back'));
        //wait for operation to finish
        await tester.pumpAndSettle();
        //find element on previous page
        final findListView = find.byType(ListView);
        //matcher for validating that back worked
        expect(findListView, findsOneWidget);
      }
    });
  });
}
