import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:to_do_app/tasks_view_model.dart';

const List<String> statuses = ['open', 'in progress', 'complete'];
const List<String> labels = [
  'is subtask of',
  'is blocked by',
  'is supertask of',
  'blocks',
  'is run after'
];

class TaskDetails extends StatelessWidget {
  TaskDetails({super.key, required this.selectedTaskId, required this.title});
  final String selectedTaskId;
  final String title;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _statusController = TextEditingController();

  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _taskIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final taskList = context.watch<Tasks>().tasks;
    var existingTasks = context.watch<Tasks>().tasks.length;
    var visibility = context.watch<Tasks>().visibility;
    final selectedTask =
        taskList.singleWhere((element) => element.taskId == selectedTaskId);
    _statusController.text = selectedTask.status;
    Map<String, String> currentlyLinkedTasks =
        context.watch<Tasks>().getCurrentlyLinkedTasks(selectedTaskId);
    return Scaffold(
      appBar: AppBar(
        title: Text(title), //value from main widget
      ),
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Column(
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
                      // isExpanded: true,
                      // autofocus: true,
                      value: _statusController.text.isNotEmpty
                          ? _statusController.text
                          : selectedTask.status,
                      // isDense: false,
                      decoration: const InputDecoration(
                        hintText: 'Please select task status',
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'No value selected';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _statusController.text = value as String;

                        var selectedStatus = _statusController.text.isNotEmpty
                            ? _statusController.text
                            : selectedTask.status.toString();
                        if (_formKey.currentState!.validate()) {
                          if (visibility) {
                            context.read<Tasks>().toggleAddTaskLinkForm();
                          }
                          context.read<Tasks>().updateSelectedTask(
                              selectedTaskId,
                              selectedStatus,
                              currentlyLinkedTasks);
                          context.read<Tasks>().clearLinkedTasks();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Task "${selectedTask.taskTitle}" updated')));
                      },
                      items: statuses.map((statusValue) {
                        return DropdownMenuItem(
                          value: statusValue,
                          child: Text(statusValue),
                        );
                      }).toList(),
                    ),
                    Text(
                      'Last updated: ${selectedTask.lastUpdate.toString().substring(0, 19)}',
                    ),
                    if (existingTasks > 1)
                      const Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: Text(
                          'Links',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SingleChildScrollView(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          backgroundBlendMode: BlendMode.overlay,
                          color: Colors.white38,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentlyLinkedTasks.length,
                          itemBuilder: (context, index) {
                            String key =
                                currentlyLinkedTasks.keys.elementAt(index);
                            String taskTitle = context
                                .watch<Tasks>()
                                .getTaskDetails(key)
                                .taskTitle;
                            return ListTile(
                              isThreeLine: true,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.indigo,
                                child: Icon(CupertinoIcons.link_circle),
                              ),
                              subtitle: InkWell(
                                child: Text(
                                  '$key - $taskTitle',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                                onTap: () {
                                  context.push('/taskdetail?task_id=$key');
                                },
                              ),
                              trailing: CircleAvatar(
                                backgroundColor: Colors.brown,
                                child: IconButton(
                                  icon: const Icon(CupertinoIcons.delete),
                                  onPressed: () {
                                    context.read<Tasks>().removeLinkedTask(
                                        false, key, selectedTaskId);
                                  },
                                ),
                              ),
                              title: Text(
                                currentlyLinkedTasks[key]!,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (existingTasks > 1)
                      CupertinoButton(
                        onPressed: () {
                          context.read<Tasks>().toggleAddTaskLinkForm();
                        },
                        child: visibility
                            ? const Text('Hide Links?')
                            : const Text('Add Links?'),
                      ),
                    Visibility(
                      visible: context.watch<Tasks>().visibility,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Flexible(
                                child: DropdownButtonFormField(
                                  value: _labelController.text.isNotEmpty
                                      ? _labelController.text
                                      : labels[0],
                                  validator: (value) {
                                    if (value == null) {
                                      return 'No value selected';
                                    }
                                    return null;
                                  },
                                  onChanged: (labelValue) {
                                    _labelController.text =
                                        labelValue as String;
                                  },
                                  isExpanded: true,
                                  items: labels
                                      .map(((relationshipValue) =>
                                          DropdownMenuItem(
                                            value: relationshipValue,
                                            child: Text(relationshipValue,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          )))
                                      .toList(),
                                ),
                              ),
                              SizedBox(
                                  width: (MediaQuery.of(context).size.width) *
                                      0.02),
                              Flexible(
                                child: DropdownButtonFormField(
                                  value: _taskIdController.text.isNotEmpty
                                      ? _taskIdController.text
                                      : null,
                                  onChanged: (taskIdValue) {
                                    _taskIdController.text =
                                        taskIdValue as String;
                                    // taskIdValue = "";
                                  },
                                  // validator: (value) {
                                  //   if (value == null) {
                                  //     return 'No value selected';
                                  //   }
                                  //   return null;
                                  // },
                                  isExpanded: true,
                                  items: context
                                      .watch<Tasks>()
                                      .getTaskIdDropdownMenuItems(
                                          selectedTaskId),
                                ),
                              ),
                              SizedBox(
                                  width: (MediaQuery.of(context).size.width) *
                                      0.02),
                              Flexible(
                                flex: 0,
                                child: ElevatedButton(
                                  style: const ButtonStyle(
                                      backgroundColor:
                                          MaterialStatePropertyAll<Color>(
                                              Colors.lightBlueAccent)),
                                  onPressed: () {
                                    if (_taskIdController.text.isNotEmpty &&
                                        _labelController.text.isNotEmpty) {
                                      if (currentlyLinkedTasks[
                                              _taskIdController.text] !=
                                          _labelController.text) {
                                        context.read<Tasks>().addLinkedTask(
                                            false,
                                            selectedTaskId,
                                            _taskIdController.text,
                                            _labelController.text);
                                        String selectedDropdownMenuItem =
                                            _taskIdController.text;
                                        context
                                            .read<Tasks>()
                                            .deleteTaskIdFromTaskIdDropdown(
                                                selectedDropdownMenuItem);
                                        _taskIdController.clear();
                                        _labelController.clear();
                                      } else {
                                        debugPrint(
                                            "item ${currentlyLinkedTasks[_taskIdController.text]} already there and its value is ${_labelController.text}");
                                      }
                                    } else if (_taskIdController
                                            .text.isNotEmpty &&
                                        (_labelController.text == "" ||
                                            _labelController.text.isEmpty)) {
                                      if (currentlyLinkedTasks[
                                              _taskIdController.text] !=
                                          labels[0]) {
                                        context.read<Tasks>().addLinkedTask(
                                            false,
                                            selectedTaskId,
                                            _taskIdController.text,
                                            labels[0]);

                                        String selectedDropdownMenuItem =
                                            _taskIdController.text;
                                        context
                                            .read<Tasks>()
                                            .deleteTaskIdFromTaskIdDropdown(
                                                selectedDropdownMenuItem);
                                        _taskIdController.clear();
                                        _labelController.clear();
                                      } else {
                                        debugPrint(
                                            "item ${currentlyLinkedTasks[_taskIdController.text]} already there and its value is ${labels[0]}");
                                      }
                                    }
                                  },
                                  child: const Text('ADD'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text('BACK'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
