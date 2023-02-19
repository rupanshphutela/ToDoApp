import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/tasks_view_model.dart';
import 'package:to_do_app/routes.dart';

const title = 'The To-Do App';

extension WithScaffold on WidgetTester {
  pumpWithScaffold(provider) async =>
      await pumpWidget(ChangeNotifierProvider<Tasks>(
          create: (context) => provider,
          child: MaterialApp.router(
              routerConfig:
                  GoRouter(initialLocation: '/tasks', routes: routes))));
}

void main() {
  group('The widget that lists all the tasks:', () {
    testWidgets('starts out with no tasks listed', (tester) async {
      //pump change notifier provider and Material app router
      final provider = Tasks();

      await tester.pumpWithScaffold(provider);
      await tester.pumpAndSettle();

      final findListView = find.byType(ListView);
      final findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      final findFilterText = find.text('all');

      //matcher to validate listview, its length and filter text
      expect(findListView, findsOneWidget);
      expect(findListTileLength, 0);
      expect(findFilterText, findsOneWidget);
    });

    testWidgets(
        'has a button that when clicked tells the navigator/router to go to the widget for creating a new task',
        (tester) async {
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
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
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
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
      //finder for number of list tiles
      final findListTile = find.byType(ListTile);
      //matcher to validate number of created tiles
      expect(findListTile, findsNWidgets(2));
    });
    testWidgets('shows only some of the tasks when a filter is applied.',
        (tester) async {
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
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
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
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
      final provider = Tasks();

      await tester.pumpWithScaffold(provider);
      await tester.pumpAndSettle();

      //Create 2 provider tasks with different status
      for (var index = 1; index >= 0; index--) {
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

  group('The widget for creating a new task', () {
    testWidgets(
        'Produces a task whose title and description match the ones entered by the user, where "produces" means passes the task to a provided view model or to a parent widget via callback or navigation',
        (tester) async {
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
      await tester.pumpAndSettle();

      //find add task button
      final findAddTaskButton = find.byTooltip('Add Task');

      //matcher
      expect(findAddTaskButton, findsOneWidget);

      //tap the Add Task button
      await tester.tap(findAddTaskButton);
      await tester.pumpAndSettle();

      final findTaskTitleInputField =
          find.byKey(const ValueKey("taskTitleInput"));
      final findTaskDescriptionInputField =
          find.byKey(const ValueKey("taskDescriptionInput"));
      final findAddTaskSubmitForm =
          find.byKey(const ValueKey("addTaskSubmitForm"));

      expect(findTaskTitleInputField, findsOneWidget);
      expect(findTaskDescriptionInputField, findsOneWidget);
      expect(findAddTaskSubmitForm, findsOneWidget);

      const taskTitle = 'Dummy Title';
      const taskDescription = 'Dummy Description';

      await tester.enterText(findTaskTitleInputField, taskTitle);
      await tester.enterText(findTaskDescriptionInputField, taskDescription);

      await tester.tap(findAddTaskSubmitForm);
      await tester.pumpAndSettle();

      //Matcher to validate redirect to TaskLists page
      expect(findAddTaskButton, findsOneWidget);

      final findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      //matchers
      expect(findListTileLength, 1);
      expect(find.text('Dummy Title'), findsOneWidget);
    });
  });

  group('The widget for editing an existing task', () {
    testWidgets('Fills out the title and description of the existing task',
        (tester) async {
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
      await tester.pumpAndSettle();

      //find add task button
      final findAddTaskButton = find.byTooltip('Add Task');

      //matcher
      expect(findAddTaskButton, findsOneWidget);

      //tap the Add Task button
      await tester.tap(findAddTaskButton);
      await tester.pumpAndSettle();

      final findTaskTitleInputField =
          find.byKey(const ValueKey("taskTitleInput"));
      final findTaskDescriptionInputField =
          find.byKey(const ValueKey("taskDescriptionInput"));
      final findAddTaskSubmitForm =
          find.byKey(const ValueKey("addTaskSubmitForm"));

      expect(findTaskTitleInputField, findsOneWidget);
      expect(findTaskDescriptionInputField, findsOneWidget);
      expect(findAddTaskSubmitForm, findsOneWidget);

      const taskTitle = 'Dummy Title';
      const taskDescription = 'Dummy Description';

      await tester.enterText(findTaskTitleInputField, taskTitle);
      await tester.enterText(findTaskDescriptionInputField, taskDescription);

      await tester.tap(findAddTaskSubmitForm);
      await tester.pumpAndSettle();

      //Matcher to validate redirect to TaskLists page
      expect(findAddTaskButton, findsOneWidget);

      final findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      //matchers
      expect(findListTileLength, 1);
      expect(find.text('Dummy Title'), findsOneWidget);

      for (var index = findListTileLength - 1; index > 0; index--) {
        final findEditTaskButton = find.byKey(ValueKey("editTaskButton$index"));
        await tester.tap(findEditTaskButton);
        await tester.pumpAndSettle();
        //matcher
        expect(find.text(taskTitle), findsOneWidget);
        expect(find.text(taskDescription), findsOneWidget);
      }
    });

    testWidgets('Updates the existing task instead of creating a new task',
        (tester) async {
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
      await tester.pumpAndSettle();

      for (var index = 0; index < 1; index++) {
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

      //matchers
      expect(findListTileLength, 1);
      expect(find.text('Dummy Title 0'), findsOneWidget);

      for (var index = findListTileLength - 1; index > 0; index--) {
        final findEditTaskButton = find.byKey(ValueKey("editTaskButton$index"));
        await tester.tap(findEditTaskButton);
        await tester.pumpAndSettle();
        //matcher
        expect(find.text('Dummy Title $index'), findsOneWidget);
        expect(find.text('Dummy Description $index'), findsOneWidget);
      }

      final findStatusText = find.text('all');

      //tap the dropdown
      await tester.tap(findStatusText);
      //wait for operation to finish
      await tester.pumpAndSettle();
      //find the open text in dropdown and tap it
      await tester.tap(find.text('in progress').last);
      //wait for operation to finish
      await tester.pumpAndSettle();

      //goback on tapping back
      await tester.tap(find.byTooltip('Back'));
      //wait for operation to finish
      await tester.pumpAndSettle();
      //find element on previous page
      final findListTile = find.byType(ListTile);
      //matcher for validating that retunring back returns one task tile only
      expect(findListTile, findsNWidgets(1));
    });
  });

  group('Bonus Points - Links', () {
    testWidgets('Users can add links', (tester) async {
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
      await tester.pumpAndSettle();
      var taskId = "";
      //create two tasks with open and in progress status
      for (var index = 0; index < 2; index++) {
        taskId = UniqueKey().hashCode.toString();
        provider.addTask(Task(
            taskId: taskId,
            taskTitle: "Dummy Title $index",
            description: "Dummy Description $index",
            status: index == 0 ? "open" : "in progress",
            lastUpdate: DateTime.now(),
            relationship: {}));
      }

      //wait for tasks to create
      await tester.pumpAndSettle();

      final findEditTaskButton = find.byKey(const ValueKey("editTaskButton1"));
      await tester.tap(findEditTaskButton);
      await tester.pumpAndSettle();

      final findTaskIdDropdown = find.byKey(const ValueKey("taskIdDropdown"));
      await tester.tap(findTaskIdDropdown);
      await tester.pumpAndSettle();

      var findTaskIdValue = find.text('$taskId: Dummy Title 1').last;
      await tester.tap(findTaskIdValue);
      await tester.pumpAndSettle();

      var findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      expect(findListTileLength, 0);

      var findIconButton = find.byKey(const ValueKey("addLinkedTaskButton"));
      await tester.tap(findIconButton);
      await tester.pumpAndSettle();

      findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      expect(findListTileLength, 1);
    });

    testWidgets('Users can remove links', (tester) async {
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
      await tester.pumpAndSettle();
      var taskId = "";
      //create two tasks with open and in progress status
      for (var index = 0; index < 2; index++) {
        taskId = UniqueKey().hashCode.toString();
        provider.addTask(Task(
            taskId: taskId,
            taskTitle: "Dummy Title $index",
            description: "Dummy Description $index",
            status: index == 0 ? "open" : "in progress",
            lastUpdate: DateTime.now(),
            relationship: {}));
      }

      //wait for tasks to create
      await tester.pumpAndSettle();

      final findEditTaskButton = find.byKey(const ValueKey("editTaskButton1"));
      await tester.tap(findEditTaskButton);
      await tester.pumpAndSettle();

      final findTaskIdDropdown = find.byKey(const ValueKey("taskIdDropdown"));
      await tester.tap(findTaskIdDropdown);
      await tester.pumpAndSettle();

      var findTaskIdValue = find.text('$taskId: Dummy Title 1').last;
      await tester.tap(findTaskIdValue);
      await tester.pumpAndSettle();

      var findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      expect(findListTileLength, 0);

      var findAddLinkedTaskButton =
          find.byKey(const ValueKey("addLinkedTaskButton"));
      await tester.tap(findAddLinkedTaskButton);
      await tester.pumpAndSettle();

      findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      expect(findListTileLength, 1);

      final findDeleteLinkedTaskButton =
          find.byKey(const ValueKey('deleteLinkedTask0'));
      await tester.tap(findDeleteLinkedTaskButton);
      await tester.pumpAndSettle();

      findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      expect(findListTileLength, 0);
    });

    testWidgets('Users can use links between tasks', (tester) async {
      final provider = Tasks();

      //pump change notifier provider and Material app router
      await tester.pumpWithScaffold(provider);
      await tester.pumpAndSettle();
      var taskId = "";
      //create two tasks with open and in progress status
      for (var index = 0; index < 2; index++) {
        taskId = UniqueKey().hashCode.toString();
        provider.addTask(Task(
            taskId: taskId,
            taskTitle: "Dummy Title $index",
            description: "Dummy Description $index",
            status: index == 0 ? "open" : "in progress",
            lastUpdate: DateTime.now(),
            relationship: {}));
      }

      //wait for tasks to create
      await tester.pumpAndSettle();

      final findEditTaskButton = find.byKey(const ValueKey("editTaskButton1"));
      await tester.tap(findEditTaskButton);
      await tester.pumpAndSettle();

      final findTaskIdDropdown = find.byKey(const ValueKey("taskIdDropdown"));
      await tester.tap(findTaskIdDropdown);
      await tester.pumpAndSettle();

      var findTaskIdValue = find.text('$taskId: Dummy Title 1').last;
      await tester.tap(findTaskIdValue);
      await tester.pumpAndSettle();

      var expectedLinkedTaskTitle = provider.getTaskDetails(taskId).taskTitle;

      var findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      expect(findListTileLength, 0);

      var findAddLinkedTaskButton =
          find.byKey(const ValueKey("addLinkedTaskButton"));
      await tester.tap(findAddLinkedTaskButton);
      await tester.pumpAndSettle();

      findListTileLength =
          tester.widgetList<ListTile>(find.byType(ListTile)).length;

      expect(findListTileLength, 1);
      var findLinkedTaskLink = find.byKey(const ValueKey("linkedTaskLink0"));
      await tester.tap(findLinkedTaskLink);
      await tester.pumpAndSettle();

      expect(find.text(expectedLinkedTaskTitle), findsOneWidget);
    });
  });
}
