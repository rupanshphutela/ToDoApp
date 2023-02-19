import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:to_do_app/routes.dart';
import 'package:to_do_app/models/task.dart';

import 'package:to_do_app/tasks_view_model.dart';

const List<String> status = <String>['all', 'open', 'in progress', 'complete'];
final ButtonStyle style =
    ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
List<Task> filteredTasks = [];
var taskTitle = "";
var filterDefaultState = "";
const taskDetailsIndex = 2;

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
    List<Task> tasks = context.watch<Tasks>().tasks;

    if (tasks.isNotEmpty) {
      if (state == 'all' || state == 'null') {
        filteredTasks = tasks.toList();
        filterDefaultState = "all";
      } else {
        filteredTasks = tasks.where((x) => x.status.contains(state)).toList();
        filterDefaultState = state;
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('The To-Do App - Tasks'),
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
                  _statusFilterController.text = value.toString();

                  context.push('/tasks?state=$value');
                },
              ),
              Center(
                child: ListView.builder(
                  key: const ValueKey("ListViewKey"),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        taskTitle = filteredTasks[index].taskTitle;
                        var taskId = filteredTasks[index].id;
                        filteredTasks
                            .removeWhere((element) => element.id == taskId);
                        context.read<Tasks>().deleteTask(taskId!);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Task "$taskTitle" removed')));
                      },
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xff764abc),
                        ),
                        title: Text(filteredTasks[index].taskTitle,
                            key: ValueKey("ListTile $index Title")),
                        subtitle: Text(
                            'Task ID: ${filteredTasks[index].id}, \nLast Updated:  ${filteredTasks[index].lastUpdate.toString().substring(0, 19)}'),
                        trailing: CircleAvatar(
                          key: ValueKey("editTaskButton$index"),
                          backgroundColor: Colors.brown,
                          child: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              var taskId = filteredTasks[index].id;
                              context.push('/taskdetail?task_id=$taskId');
                            },
                          ),
                        ),
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
    } else {
      context.watch<Tasks>().getAllTasks();
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Icon(Icons.task),
        ),
        body: const SafeArea(
          child: Center(
            child: Text(
              "No tasks found.\nPlease create one to see something in this space",
              style: TextStyle(color: Colors.black, fontSize: 24),
            ),
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
}
