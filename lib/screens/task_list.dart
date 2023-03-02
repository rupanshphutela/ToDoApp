import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:to_do_app/utils/routes.dart';
import 'package:to_do_app/models/task.dart';

import 'package:to_do_app/providers/tasks_data_store_provider.dart';

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
    int ownerId = 0; //???? dont you hardcode ownerId
    final provider = Provider.of<TaskDataStoreProvider>(context);
    List<Task>? tasks = provider.tasks;

    if (tasks != null && tasks.isNotEmpty) {
      if (state == 'all' || state == 'null') {
        filteredTasks = tasks.toList();
        filterDefaultState = "all";
      } else {
        filteredTasks = tasks.where((x) => x.status.contains(state)).toList();
        filterDefaultState = state;
      }

      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
              ),
              SizedBox(width: (MediaQuery.of(context).size.width) * 0.02),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(const Color(0xff764abc))),
                onPressed: () {
                  context.push('/qr_scanner');
                },
                child: Row(
                  children: [
                    const Icon(Icons.qr_code),
                    SizedBox(width: (MediaQuery.of(context).size.width) * 0.02),
                    const Text('Import Task')
                  ],
                ),
              ),
            ],
          ),
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

                  context.push(
                    '/tasks?state=$value',
                  );
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
                        provider.deleteTask(
                            ownerId, taskId!, filteredTasks[index].type);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Task "$taskTitle" removed')));
                      },
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xff764abc),
                        ),
                        title: Text(
                          filteredTasks[index].taskTitle,
                          key: ValueKey("ListTile $index Title"),
                          style: const TextStyle(fontSize: 20),
                        ),
                        subtitle: Text(
                            'Type: ${filteredTasks[index].type}${(filteredTasks[index].type == "shared" ? ", Group: ${filteredTasks[index].group}" : "")} \nUpdated:  ${filteredTasks[index].lastUpdate.toString().substring(0, 19)}'),
                        trailing: CircleAvatar(
                          backgroundColor: Colors.brown,
                          child: IconButton(
                            key: ValueKey("editTaskButton$index"),
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              var taskId = int.parse(
                                  (filteredTasks[index].id).toString());
                              provider.getCurrentlyLinkedTasks(
                                  taskId,
                                  filteredTasks[index]
                                      .type); // ???? move this to tasks edit page
                              context.push(
                                  '/taskdetail?taskId=$taskId&type=${filteredTasks[index].type}');
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
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home', tooltip: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: 'Personal Task',
                tooltip: 'Personal Task'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: 'Shared Task',
                tooltip: 'Shared Task'),
            BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Shared Groups',
                tooltip: 'Shared Groups'),
          ],
          onTap: (index) {
            var route = ModalRoute.of(context);
            if (route?.settings.name == '/tasks' && index == 0) {
            } else if (index == 1) {
              provider.disableGroupsDropdown();
              provider.getUserGroups(ownerId);
              context.push('/task?type=personal');
            } else if (index == 2) {
              provider.enableGroupsDropdown();
              provider.getUserGroups(ownerId);
              context.push('/task?type=shared');
            } else if (index == 3) {
              provider.getAllGroups();
              context.push('/groups?ownerId=$ownerId');
            }
          },
        ),
      );
    } else {
      provider.fetchAllTasksForUser(0); //???? dont you hardcode user
      provider.getAllGroups();
      provider.getUserGroups(ownerId);
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
              ),
              SizedBox(width: (MediaQuery.of(context).size.width) * 0.02),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(const Color(0xff764abc))),
                onPressed: () {
                  context.push('/qr_scanner');
                },
                child: Row(
                  children: [
                    const Icon(Icons.qr_code),
                    SizedBox(width: (MediaQuery.of(context).size.width) * 0.02),
                    const Text('Import Task')
                  ],
                ),
              ),
            ],
          ),
        ),
        body: const SafeArea(
          child: Center(
            child: Text(
              "Nothing here!!\n\nPress Add Task button\nbelow to create a task",
              style: TextStyle(color: Colors.black, fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home', tooltip: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: 'Personal Task',
                tooltip: 'Personal Task'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: 'Shared Task',
                tooltip: 'Shared Task'),
            BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Shared Groups',
                tooltip: 'Shared Groups'),
          ],
          onTap: (index) {
            var route = ModalRoute.of(context);
            if (route?.settings.name == '/tasks' && index == 0) {
            } else if (index == 1) {
              provider.disableGroupsDropdown();
              provider.getUserGroups(ownerId);
              context.push('/task?type=personal');
            } else if (index == 2) {
              provider.disableGroupsDropdown();
              provider.getUserGroups(ownerId);
              context.push('/task?type=shared');
            } else if (index == 3) {
              provider.getAllGroups();
              context.push('/groups?ownerId=$ownerId');
            }
          },
        ),
      );
    }
  }
}
