import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/models/task_link.dart';
import 'package:to_do_app/providers/tasks_data_store_provider.dart';

const List<String> statuses = ['open', 'in progress', 'complete'];
const List<String> labels = [
  'is subtask of',
  'is blocked by',
  'is supertask of',
  'blocks',
  'is run after'
];

class TaskForm extends StatelessWidget {
  TaskForm({super.key, required this.title, required this.type});
  final String title;
  final String type;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _taskIdController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    int ownerId = 0; //???? dont you hardcode ownerId
    int taskId = 0; //???? dont you hardcode taskId
    bool addLink = false;
    bool isDeleteLink = false;
    final provider = Provider.of<TaskDataStoreProvider>(context);
    List<DropdownMenuItem<int>>? taskIdDropdownMenuItems =
        provider.getTaskIdDropdownMenuItems(taskId, type);

    List<DropdownMenuItem<String>>? userGroupDropdownMenuItems =
        provider.getUserGroupDropdownMenuItems(ownerId);
    List<String>? userGroupNames = provider.userGroupNames();
    List<TaskLink?> linkedTasks = provider.linkedTasks(type);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
          ],
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
                    Visibility(
                      visible: context
                          .read<TaskDataStoreProvider>()
                          .checkLinksEnablementAddForm,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              Flexible(
                                child: DropdownButtonFormField(
                                  value: type,
                                  validator: (value) {
                                    if (value == null) {
                                      return 'No value selected';
                                    }
                                    return null;
                                  },
                                  onChanged: null,
                                  isExpanded: true,
                                  items: [type]
                                      .map(((typeValue) => DropdownMenuItem(
                                            value: typeValue,
                                            child: Text(typeValue,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          )))
                                      .toList(),
                                ),
                              ),
                              SizedBox(
                                  width: (MediaQuery.of(context).size.width) *
                                      0.02),
                              if (provider.enableGroupsinTasksForm)
                                Flexible(
                                  child: DropdownButtonFormField(
                                    value: _groupController.text.isNotEmpty
                                        ? _groupController.text
                                        : null,
                                    isExpanded: true,
                                    items: userGroupDropdownMenuItems,
                                    onChanged: (groupValue) {
                                      _groupController.text =
                                          groupValue.toString();
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Group mandatory for shared tasks';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                            ],
                          ),
                          if (context
                              .read<TaskDataStoreProvider>()
                              .checkLinksEnablementAddForm)
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
                                  int linkedTaskId =
                                      linkedTasks[index]!.linkedTaskId;
                                  String taskTitle = provider
                                      .getTaskDetails(linkedTaskId, type)!
                                      .taskTitle;
                                  return ListTile(
                                    isThreeLine: true,
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.indigo,
                                      child: Icon(Icons.circle),
                                    ),
                                    subtitle: InkWell(
                                      child: Text(
                                        '$linkedTaskId: $taskTitle',
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
                                            onPressed: () async {
                                              provider.clearLinkedTaskIds(type);
                                              provider.clearLinkedTasks(type);
                                              provider
                                                  .clearCurrentlyLinkedTasks(
                                                      type);
                                              provider
                                                  .clearCurrentlyLinkedImages(
                                                      type);
                                              await provider
                                                  .getTaskImageStack(
                                                      linkedTaskId,
                                                      ownerId,
                                                      type)
                                                  .then((value) async => provider
                                                      .getCurrentlyLinkedTasks(
                                                          linkedTaskId, type))
                                                  .then((value) => context.push(
                                                      '/taskdetail?taskId=$linkedTaskId&type=$type')); // ???? move this to tasks details page
                                              ;
                                            },
                                          ),
                                        ),
                                        CircleAvatar(
                                          backgroundColor: Colors.brown,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              isDeleteLink = true;

                                              provider.removeLinkedTask(ownerId,
                                                  linkedTaskId, taskId, type);
                                              if (isDeleteLink) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            'Link to taskId "$linkedTaskId" with title "$taskTitle" removed')));
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      linkedTasks[index]!.relation,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
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
                                      ? int.parse(_taskIdController.text)
                                      : null,
                                  isExpanded: true,
                                  items: taskIdDropdownMenuItems,
                                  onChanged: (taskIdValue) {
                                    _taskIdController.text =
                                        taskIdValue.toString();
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
                                    onPressed: () async {
                                      int taskIdControllerInt = 0;
                                      try {
                                        taskIdControllerInt =
                                            int.parse(_taskIdController.text);
                                      } catch (exception) {
                                        Exception(
                                            "Convert task id controller string to int error: $exception");
                                      }
                                      if (taskIdControllerInt != 0 &&
                                          _labelController.text.isNotEmpty) {
                                        if (!linkedTasks.any((element) =>
                                            element!.relation ==
                                            _labelController.text)) {
                                          if (linkedTasks.any((element) =>
                                              element!.linkedTaskId ==
                                              taskIdControllerInt)) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Task ID "$taskIdControllerInt" already linked to this task. Please remove and retry')));
                                          } else {
                                            addLink = true;
                                            await provider
                                                .addLinkedTask(
                                                    ownerId,
                                                    taskId,
                                                    taskIdControllerInt,
                                                    _labelController.text,
                                                    type)
                                                .then((value) => ScaffoldMessenger
                                                        .of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            'Relation "${_labelController.text.isNotEmpty ? _labelController.text : labels[0]}" for taskId "$taskIdControllerInt" with title "${provider.getTaskDetails(taskIdControllerInt, type)!.taskTitle}" added'))));
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Relation "${_labelController.text}" already present for another task. Please remove and retry')));
                                        }
                                      } else if (_taskIdController
                                              .text.isNotEmpty &&
                                          (_labelController.text == "" ||
                                              _labelController.text.isEmpty)) {
                                        if (!linkedTasks.any((element) =>
                                            element!.relation == labels[0])) {
                                          addLink = true;
                                          await provider
                                              .addLinkedTask(
                                                  ownerId,
                                                  taskId,
                                                  taskIdControllerInt,
                                                  labels[0],
                                                  type)
                                              .then((value) => ScaffoldMessenger
                                                      .of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          'Relation "${_labelController.text.isNotEmpty ? _labelController.text : labels[0]}" for taskId "$taskIdControllerInt" with title "${provider.getTaskDetails(taskIdControllerInt, type)!.taskTitle}" added'))));
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Relation "${labels[0]}" already present for another task. Please remove and retry')));
                                        }
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
                    const Padding(
                      padding: EdgeInsets.only(bottom: 50),
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
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await provider.addTask(
                            Task(
                                ownerId: ownerId,
                                taskTitle: _titleController.text,
                                description: _descriptionController.text,
                                status: _statusController.text.isNotEmpty
                                    ? _statusController.text
                                    : statuses[0],
                                lastUpdate: DateTime.now().toString(),
                                group: type == 'shared'
                                    ? _groupController.text.isEmpty
                                        ? userGroupNames!.isNotEmpty
                                            ? userGroupNames[0]
                                            : "N/A"
                                        : _groupController.text
                                    : "",
                                type: type),
                            linkedTasks);
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
