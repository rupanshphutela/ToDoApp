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
    List<DropdownMenuItem<String>>? taskIdDropdownMenuItems =
        context.read<Tasks>().getTaskIdDropdownMenuItems(selectedTaskId);

    bool addLink = false;
    bool isDeleteLink = false;
    final taskList = context.watch<Tasks>().tasks;
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
                    if (context.read<Tasks>().checkLinksEnablementEditForm)
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
                                child: Icon(Icons.circle),
                              ),
                              subtitle: InkWell(
                                key: ValueKey("linkedTaskLink$index"),
                                child: Text(
                                  '$key - $taskTitle',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                                onTap: () {
                                  context.read<Tasks>().clearLinkedTaskIds();
                                  context.push('/taskdetail?task_id=$key');
                                },
                              ),
                              trailing: CircleAvatar(
                                key: ValueKey('deleteLinkedTask$index'),
                                backgroundColor: Colors.brown,
                                child: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    isDeleteLink = true;
                                    context
                                        .read<Tasks>()
                                        .removeLinkedTask(key, selectedTaskId);
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
                    Visibility(
                      visible:
                          context.read<Tasks>().checkLinksEnablementEditForm,
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
                                  key: const ValueKey("taskIdDropdown"),

                                  value: _taskIdController.text.isNotEmpty
                                      ? _taskIdController.text
                                      : null,
                                  isExpanded: true,
                                  items: taskIdDropdownMenuItems,
                                  onChanged: (String? taskIdValue) {
                                    _taskIdController.text = taskIdValue!;
                                  },
                                  // validator: (value) {
                                  //   if (value == null) {
                                  //     return 'No value selected';
                                  //   }
                                  //   return null;
                                  // },
                                ),
                              ),
                              SizedBox(
                                  width: (MediaQuery.of(context).size.width) *
                                      0.02),
                              Flexible(
                                key: const ValueKey("addLinkedTaskButton"),
                                flex: 0,
                                child: CircleAvatar(
                                  backgroundColor: Colors.brown,
                                  child: IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      if (_taskIdController.text.isNotEmpty &&
                                          _labelController.text.isNotEmpty) {
                                        if (currentlyLinkedTasks[
                                                _taskIdController.text] !=
                                            _labelController.text) {
                                          addLink = true;
                                          context.read<Tasks>().addLinkedTask(
                                              selectedTaskId,
                                              _taskIdController.text,
                                              _labelController.text);
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
                                              selectedTaskId,
                                              _taskIdController.text,
                                              labels[0]);
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
