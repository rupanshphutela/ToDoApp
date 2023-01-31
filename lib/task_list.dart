import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:to_do_app/routes.dart';
import 'package:to_do_app/task.dart';

import 'package:to_do_app/tasks_view_model.dart';

const List<String> status = <String>['all', 'open', 'in progress', 'complete'];
final ButtonStyle style =
    ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
List<Task> filteredTasks = [];
var taskTitle = "";
var filterDefaultState = "";
const taskDetailsIndex = 2;

// ignore: must_be_immutable
class TaskList extends StatelessWidget {
  TaskList(
      {super.key,
      required this.title,
      this.state = "all",
      this.filteredTasks = const []});
  final String title;
  final String state;
  List<Task> filteredTasks = const [];

  final TextEditingController _statusFilterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var viewModelObject = context.watch<Tasks>();
    var taskList = viewModelObject.tasks;
    if (state == 'all' || state == 'null') {
      filteredTasks = taskList.toList();
      filterDefaultState = "all";
    } else {
      filteredTasks = taskList.where((x) => x.status.contains(state)).toList();
      filterDefaultState = state;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('The To Do App - Tasks'),
      ),
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: _statusFilterController.text.isNotEmpty
                  ? _statusFilterController.text
                  : filterDefaultState,
              decoration: const InputDecoration(
                hintText: 'Please select task status',
              ),
              validator: (value) {
                if (value == null) {
                  return 'No value selected';
                }
                return null;
              },
              items: status
                  .map(((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      )))
                  .toList(),
              onChanged: (value) {
                _statusFilterController.text = value as String;

                context.push('/tasks?state=$value');
              },
            ),
            Center(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: const ValueKey("ListViewKey"),
                    onDismissed: (direction) {
                      taskTitle = filteredTasks[index].taskTitle;
                      var taskId = filteredTasks[index].taskId;
                      int modifiedIndex =
                          taskList.indexWhere((item) => item.taskId == taskId);
                      filteredTasks
                          .removeWhere((element) => element.taskId == taskId);
                      context.read<Tasks>().deleteTask(taskId);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Task "$taskTitle" removed')));
                    },
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xff764abc),
                      ),
                      title: Text(filteredTasks[index].taskTitle),
                      subtitle: Text(
                          'Updated:  ${filteredTasks[index].lastUpdate.toString().substring(0, 19)}'),
                      onTap: () {
                        var taskId = filteredTasks[index].taskId;
                        context.push('/taskdetail?task_id=$taskId');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home', tooltip: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add), label: 'Add Task', tooltip: 'Add Task'),
        ],
        onTap: (index) {
          var route = ModalRoute.of(context);
          if (route?.settings.name == '/tasks' && index == 0) {
          } else {
            context.push(routes[index].path);
          }
        },
      ),
    );
  }
}
