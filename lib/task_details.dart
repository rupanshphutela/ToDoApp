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
    bool? isNewTask;
    if (selectedTaskId.isNotEmpty) {
      isNewTask = false;
    }
    bool addLink = false;
    bool isDeleteLink = false;
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
        title: Text(title),
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
                                'Task "${selectedTask.taskTitle}" status updated to $selectedStatus')));
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
                                    isDeleteLink = true;
                                    context.read<Tasks>().removeLinkedTask(
                                        isNewTask!, key, selectedTaskId);
                                    if (isDeleteLink) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Link to task $key removed')));
                                    }
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
                                child: CircleAvatar(
                                  backgroundColor: Colors.brown,
                                  child: IconButton(
                                    icon: const Icon(CupertinoIcons.add),
                                    onPressed: () {
                                      if (_taskIdController.text.isNotEmpty &&
                                          _labelController.text.isNotEmpty) {
                                        if (currentlyLinkedTasks[
                                                _taskIdController.text] !=
                                            _labelController.text) {
                                          addLink = true;
                                          context.read<Tasks>().addLinkedTask(
                                              isNewTask!,
                                              selectedTaskId,
                                              _taskIdController.text,
                                              _labelController.text);
                                          String selectedDropdownMenuItem =
                                              _taskIdController.text;
                                          context
                                              .read<Tasks>()
                                              .deleteTaskIdFromTaskIdDropdown(
                                                  selectedDropdownMenuItem);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Relation "${currentlyLinkedTasks[_taskIdController.text]}" already present for task - ${_taskIdController.text}')));
                                        }
                                      } else if (_taskIdController
                                              .text.isNotEmpty &&
                                          (_labelController.text == "" ||
                                              _labelController.text.isEmpty)) {
                                        if (currentlyLinkedTasks[
                                                _taskIdController.text] !=
                                            labels[0]) {
                                          addLink = true;
                                          context.read<Tasks>().addLinkedTask(
                                              isNewTask!,
                                              selectedTaskId,
                                              _taskIdController.text,
                                              labels[0]);

                                          String selectedDropdownMenuItem =
                                              _taskIdController.text;
                                          context
                                              .read<Tasks>()
                                              .deleteTaskIdFromTaskIdDropdown(
                                                  selectedDropdownMenuItem);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Relation "${currentlyLinkedTasks[_taskIdController.text]}" already present for task ${_taskIdController.text}')));
                                        }
                                      }
                                      if (addLink) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Relation "${_labelController.text.isNotEmpty ? _labelController.text : labels[0]}" for task "${_taskIdController.text}" added')));
                                      }
                                    },
                                  ),
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
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 8.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceAround,
            //     children: [
            //       ElevatedButton(
            //         onPressed: () {
            //           context.pop();
            //         },
            //         child: const Text('BACK'),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
