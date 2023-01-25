import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:to_do_app/tasks_view_model.dart';

const List<String> status = ['open', 'in progress', 'complete'];

class TaskDetails extends StatelessWidget {
  TaskDetails({super.key, required this.selectedTaskId, required this.title});
  final String selectedTaskId;
  final String title;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _statusController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final taskList = context.watch<Tasks>().tasks;
    final selectedTask =
        taskList.singleWhere((element) => element.taskId == selectedTaskId);
    return Scaffold(
      appBar: AppBar(
        title: Text(title), //value from main widget
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      initialValue: selectedTask.taskTitle,
                      readOnly: true,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    TextFormField(
                      initialValue: selectedTask.description,
                      readOnly: true,
                      maxLines: null,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    DropdownButtonFormField(
                      isExpanded: true,
                      autofocus: true,
                      value: _statusController.text.isNotEmpty
                          ? _statusController.text
                          : selectedTask.status,
                      isDense: false,
                      onChanged: (value) {
                        _statusController.text = value as String;
                      },
                      items: status.map((statusValue) {
                        return DropdownMenuItem(
                          value: statusValue,
                          child: Text(statusValue),
                        );
                      }).toList(),
                    ),
                    Text(
                      'Last updated: ${selectedTask.lastUpdate.toString().substring(0, 19)}',
                    ),
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    var selectedStatus = _statusController.text.isNotEmpty
                        ? _statusController.text
                        : selectedTask.status.toString();
                    context
                        .read<Tasks>()
                        .updateSelectedTask(selectedTaskId, selectedStatus);
                    context.pop();
                  },
                  child: const Text('SAVE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
