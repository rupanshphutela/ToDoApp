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
    bool addLink = false;
    bool isDeleteLink = false;
    String taskId = UniqueKey().hashCode.toString();
    List<DropdownMenuItem<String>>? taskIdDropdownMenuItems =
        context.read<Tasks>().getTaskIdDropdownMenuItems(taskId);
    Map<String, String> linkedTasks = context.watch<Tasks>().linkedTasks;
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
                      key: const ValueKey("taskTitleInput"),
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
                      key: const ValueKey("taskDescriptionInput"),
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
                    if (context.read<Tasks>().checkLinksEnablementAddForm)
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
                                child: Icon(Icons.circle),
                              ),
                              subtitle: InkWell(
                                child: Text(
                                  taskTitle,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              trailing: Wrap(
                                spacing: 12,
                                children: <Widget>[
                                  CircleAvatar(
                                    backgroundColor: Colors.brown,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        context
                                            .read<Tasks>()
                                            .clearLinkedTaskIds();
                                        context
                                            .push('/taskdetail?task_id=$key');
                                      },
                                    ),
                                  ),
                                  CircleAvatar(
                                    backgroundColor: Colors.brown,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        isDeleteLink = true;

                                        context
                                            .read<Tasks>()
                                            .removeLinkedTask(key, taskId);
                                        if (isDeleteLink) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Link to taskId "$key" with title "$taskTitle" removed')));
                                        }
                                      },
                                    ),
                                  ),
                                ],
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
                    Visibility(
                      visible:
                          context.read<Tasks>().checkLinksEnablementAddForm,
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
                                flex: 0,
                                child: CircleAvatar(
                                  backgroundColor: Colors.brown,
                                  child: IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      if (_taskIdController.text.isNotEmpty &&
                                          _labelController.text.isNotEmpty) {
                                        if (linkedTasks[
                                                _taskIdController.text] !=
                                            _labelController.text) {
                                          addLink = true;
                                          context.read<Tasks>().addLinkedTask(
                                              taskId,
                                              _taskIdController.text,
                                              _labelController.text);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Relation "${linkedTasks[_taskIdController.text]}" already present for taskId "${_taskIdController.text}" with title "${context.read<Tasks>().getTaskDetails(_taskIdController.text).taskTitle}"')));
                                        }
                                      } else if (_taskIdController
                                              .text.isNotEmpty &&
                                          (_labelController.text == "" ||
                                              _labelController.text.isEmpty)) {
                                        if (linkedTasks[
                                                _taskIdController.text] !=
                                            labels[0]) {
                                          addLink = true;
                                          context.read<Tasks>().addLinkedTask(
                                              taskId,
                                              _taskIdController.text,
                                              labels[0]);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Relation "${linkedTasks[_taskIdController.text]}" already present for taskId "${_taskIdController.text}" with title "${context.read<Tasks>().getTaskDetails(_taskIdController.text).taskTitle}"')));
                                        }
                                      }
                                      if (addLink) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Relation "${_labelController.text.isNotEmpty ? _labelController.text : labels[0]}" for taskId "${_taskIdController.text}" with title "${context.read<Tasks>().getTaskDetails(_taskIdController.text).taskTitle}" added')));
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
            Padding(
              padding: EdgeInsets.all(
                  (MediaQuery.of(context).size.width).toDouble() * 0.07),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    key: const ValueKey("addTaskSubmitForm"),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
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
                                .addLinkedTask(taskId, key, value);
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
