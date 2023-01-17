import 'package:flutter/material.dart';
import 'package:to_do_app/task.dart';
import 'package:to_do_app/task_details.dart';
import 'package:to_do_app/task_form.dart';

const List<String> status = <String>['all', 'open', 'in progress', 'complete'];
final ButtonStyle style =
    ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
List<Task> filteredTasks = [];
var modifiedTitle = "";

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, this.tasks = const [], required this.title});
  final String title;
  final List<Task> tasks;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TextEditingController _statusFilterController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _statusFilterController.dispose();
  }

  @override
  void initState() {
    super.initState();
    filteredTasks = widget.tasks;
    _statusFilterController.text = status.first;
  }

  // DateTime _last_time_update = DateTime.now();

  _addTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              TaskForm(tasks: widget.tasks, title: widget.title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(widget.tasks.toList());
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - Tasks'), //value from main widget
      ),
      body: Column(
        children: [
          DropdownButtonFormField(
            // value: _statusFilterController.text.isNotEmpty
            //     ? _statusFilterController.text
            //     : null,
            value: _statusFilterController.text,
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
              setState(() {
                _statusFilterController.text = value as String;
                if (value == 'all') {
                  filteredTasks = widget.tasks;
                } else {
                  filteredTasks = widget.tasks
                      .where((x) => x.status.contains(value))
                      .toList();
                }
              });
            },
          ),
          Center(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  // Step 1
                  key: UniqueKey(), //Key(widget.tasks[index].toString()),
                  onDismissed: (direction) {
                    // Step 2
                    setState(() {
                      modifiedTitle = filteredTasks[index].taskTitle;
                      var modifiedLastUpdate = filteredTasks[index].lastUpdate;
                      int modifiedIndex = widget.tasks.indexWhere((item) =>
                          item.taskTitle == modifiedTitle &&
                          item.lastUpdate == modifiedLastUpdate);

                      widget.tasks.removeAt(modifiedIndex);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Task "$modifiedTitle" removed')));
                  },
                  child: ListTile(
                    // return ListTile(
                    //visualDensity: VisualDensity(vertical: 4),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xff764abc),
                      // child:
                      //     Text(index.toString()), //widget.tasks[index].toString()
                    ),
                    title: Text(filteredTasks[index].taskTitle),
                    subtitle: Text(
                        'Updated:  ${filteredTasks[index].lastUpdate.toString().substring(0, 19)}'),
                    // trailing: const Icon(Icons.more_vert),
                    onTap: () {
                      var modifiedTitle = filteredTasks[index].taskTitle;
                      var modifiedLastUpdate = filteredTasks[index].lastUpdate;
                      int modifiedIndex = widget.tasks.indexWhere((item) =>
                          item.taskTitle == modifiedTitle &&
                          item.lastUpdate == modifiedLastUpdate);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetails(
                              tasks: widget.tasks,
                              selectedTaskIndex: modifiedIndex,
                              title: widget.title),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Task',
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
