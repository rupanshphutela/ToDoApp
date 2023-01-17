import 'package:flutter/material.dart';
// import 'package:to_do_app/task.dart';
import 'package:to_do_app/tasks_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // List<Task> task = [
  //   Task(
  //       task_title: 'First',
  //       description: 'Testing First Task',
  //       status: 'In progress')
  // ];

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasks by Rupansh',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const TasksPage(
        title: 'Rupansh To Do',
        // tasks: task,
      ),
    );
  }
}
