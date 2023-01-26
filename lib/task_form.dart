import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/task.dart';
import 'package:to_do_app/tasks_view_model.dart';

const List<String> statuses = ['open', 'in progress', 'complete'];
const List<String> labels = [
  'is subtask of',
  'is blocked by',
  'is supertask of',
  'blocks',
  'is run after'
];

class TaskForm extends StatelessWidget {
  TaskForm({super.key, required this.title});
  final String title;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _taskIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String taskId = UniqueKey().hashCode.toString();
    bool isNewTask = true;
    Map<String, String> linkedTasks = context.watch<Tasks>().linkedTasks;
    var existingTasks = context.watch<Tasks>().tasks.length;
    var visibility = context.watch<Tasks>().visibility;
    return Scaffold(
      appBar: AppBar(
        title: Text(title), //value from main widget
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
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
                      maxLines: 1,
                      maxLength: 20,
                      controller: _titleController,
                      inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      decoration: const InputDecoration(
                        hintText: 'Enter Task Title',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      maxLines: 4,
                      maxLength: 50,
                      controller: _descriptionController,
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                      decoration: const InputDecoration(
                        hintText: 'Enter Task Description',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField(
                      value: _statusController.text.isNotEmpty
                          ? _statusController.text
                          : statuses[0],
                      decoration: const InputDecoration(
                        hintText: 'Please select task status',
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'No value selected';
                        }
                        return null;
                      },
                      items: statuses
                          .map(((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              )))
                          .toList(),
                      onChanged: (value) {
                        _statusController.text = value as String;
                      },
                    ),
                    if (existingTasks > 0)
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
                          itemCount: linkedTasks.length,
                          itemBuilder: (context, index) {
                            String key = linkedTasks.keys.elementAt(index);
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
                                        isNewTask, key, taskId);
                                  },
                                ),
                              ),
                              title: Text(
                                linkedTasks[key]!,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (existingTasks > 0)
                      CupertinoButton(
                        onPressed: () {
                          context.read<Tasks>().toggleAddTaskLinkForm();
                        },
                        child: visibility
                            ? const Text('Hide Links?')
                            : const Text('Add Links?'),
                      ),
                    Visibility(
                      visible: visibility,
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
                                      .read<Tasks>()
                                      .getTaskIdDropdownMenuItems(taskId),
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
                                      if (linkedTasks[_taskIdController.text] !=
                                          _labelController.text) {
                                        context.read<Tasks>().addLinkedTask(
                                            isNewTask,
                                            taskId,
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
                                            "item ${linkedTasks[_taskIdController.text]} already there and its value is ${_labelController.text}");
                                      }
                                    } else if (_taskIdController
                                            .text.isNotEmpty &&
                                        (_labelController.text == "" ||
                                            _labelController.text.isEmpty)) {
                                      if (linkedTasks[_taskIdController.text] !=
                                          labels[0]) {
                                        context.read<Tasks>().addLinkedTask(
                                            isNewTask,
                                            taskId,
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
                                            "item ${linkedTasks[_taskIdController.text]} already there and its value is ${labels[0]}");
                                      }
                                    }
                                  },
                                  child: const Text('SAVE'),
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
              padding: EdgeInsets.all(
                  (MediaQuery.of(context).size.width).toDouble() * 0.07),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (visibility) {
                          context.read<Tasks>().toggleAddTaskLinkForm();
                        }
                        context.read<Tasks>().addTask(Task(
                            taskId: taskId,
                            taskTitle: _titleController.text,
                            description: _descriptionController.text,
                            status: _statusController.text.isNotEmpty
                                ? _statusController.text
                                : statuses[0],
                            relationship: {},
                            lastUpdate: DateTime.now()));
                        if (linkedTasks.isNotEmpty) {
                          linkedTasks.forEach((key, value) {
                            context
                                .read<Tasks>()
                                .addLinkedTask(false, taskId, key, value);
                          });
                        }
                        context.read<Tasks>().clearLinkedTasks();
                        context.pop();
                      }
                    },
                    child: const Text('SAVE'),
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
