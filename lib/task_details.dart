import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:to_do_app/models/task_link.dart';
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
  final int selectedTaskId;
  final String title;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _statusController = TextEditingController();

  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _taskIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    int ownerId = context.read<Tasks>().ownerId;
    context.read<Tasks>().updateCurrentTaskId(selectedTaskId);
    List<DropdownMenuItem<int>>? taskIdDropdownMenuItems =
        context.watch<Tasks>().getTaskIdDropdownMenuItems(selectedTaskId);
    context.read<Tasks>().getTaskImageStack(selectedTaskId);

    bool addLink = false;
    bool isDeleteLink = false;
    final taskList = context.watch<Tasks>().tasks;
    final selectedTaskList =
        taskList.where((element) => element.id == selectedTaskId);
    final selectedTask = selectedTaskList.first;
    _statusController.text = selectedTask.status;
    context.watch<Tasks>().getCurrentlyLinkedTasks(selectedTaskId);
    List<TaskLink?> currentlyLinkedTasks =
        context.watch<Tasks>().currentlyLinkedTasks;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              title,
            ),
            SizedBox(width: (MediaQuery.of(context).size.width) * 0.02),
            CircleAvatar(
              backgroundColor: const Color(0xff764abc),
              child: IconButton(
                icon: const Icon(
                  Icons.qr_code,
                ),
                tooltip: 'Export Task',
                onPressed: () {
                  var json =
                      context.read<Tasks>().serializeTaskObject(selectedTask);
                  var qrPainterImage =
                      context.read<Tasks>().generateQRCode(json);
                  context
                      .read<Tasks>()
                      .saveQrCodetoAppDirectory(selectedTaskId, qrPainterImage);
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Column(
          children: [
            /** ???? Image Stack */
            if (context.watch<Tasks>().cards.isNotEmpty)
              SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(0),
                      margin: const EdgeInsets.all(0),
                      decoration: const BoxDecoration(color: Colors.grey),
                      height: 400,
                      width: size.width,
                      child: CardSwiper(
                        scale: 0.0001,
                        cards: context.watch<Tasks>().cards,
                        padding: const EdgeInsets.all(24.0),
                      ),
                    ),
                  ],
                ),
              ),
            /** ???? Image Stack */
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
                              selectedTaskId, selectedStatus);
                          context.read<Tasks>().clearLinkedTasks();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'TaskId "${selectedTask.id}" with title "${selectedTask.taskTitle}" status updated to $selectedStatus')));
                      },
                      items: statuses.map((statusValue) {
                        return DropdownMenuItem(
                          value: statusValue,
                          child: Text(statusValue),
                        );
                      }).toList(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        'Task ID: ${selectedTask.id}, \nLast updated: ${selectedTask.lastUpdate.toString().substring(0, 19)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: Text(
                        'Add Images?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Flexible(
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<Tasks>().requestCameraPermission(
                                      ownerId, selectedTaskId);
                                },
                                child: const Text('Take photo'),
                              ),
                            ),
                            SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width) * 0.02),
                            Flexible(
                              child: ElevatedButton(
                                onPressed: () {
                                  context
                                      .read<Tasks>()
                                      .requestStoragePermission(
                                          ownerId, selectedTaskId);
                                },
                                child: const Text('Upload photo'),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                            int linkedTaskId =
                                currentlyLinkedTasks[index]!.linkedTaskId;
                            String taskTitle = context
                                .read<Tasks>()
                                .getTaskDetails(linkedTaskId)
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
                                    key: ValueKey("linkedTaskLink$index"),
                                    backgroundColor: Colors.brown,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        context
                                            .read<Tasks>()
                                            .clearLinkedTaskIds();
                                        context.push(
                                            '/taskdetail?task_id=$linkedTaskId');
                                      },
                                    ),
                                  ),
                                  CircleAvatar(
                                    key: ValueKey('deleteLinkedTask$index'),
                                    backgroundColor: Colors.brown,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        isDeleteLink = true;
                                        context.read<Tasks>().removeLinkedTask(
                                            linkedTaskId, selectedTaskId);
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
                                currentlyLinkedTasks[index]!.relation,
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
                                key: const ValueKey("addLinkedTaskButton"),
                                flex: 0,
                                child: CircleAvatar(
                                  backgroundColor: Colors.brown,
                                  child: IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
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
                                        if (!currentlyLinkedTasks.any(
                                            (element) =>
                                                element!.relation ==
                                                _labelController.text)) {
                                          if (currentlyLinkedTasks.any(
                                              (element) =>
                                                  element!.linkedTaskId ==
                                                  taskIdControllerInt)) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Task ID "$taskIdControllerInt" already linked to this task. Please remove and retry')));
                                          } else {
                                            addLink = true;
                                            context.read<Tasks>().addLinkedTask(
                                                selectedTaskId,
                                                taskIdControllerInt,
                                                _labelController.text);
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
                                        if (!currentlyLinkedTasks.any(
                                            (element) =>
                                                element!.relation ==
                                                labels[0])) {
                                          addLink = true;
                                          context.read<Tasks>().addLinkedTask(
                                              selectedTaskId,
                                              taskIdControllerInt,
                                              labels[0]);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Relation "${labels[0]}" already present for another task. Please remove and retry')));
                                        }
                                      }
                                      if (addLink) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    'Relation "${_labelController.text.isNotEmpty ? _labelController.text : labels[0]}" for taskId "$taskIdControllerInt" with title "${context.read<Tasks>().getTaskDetails(taskIdControllerInt).taskTitle}" added')));
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
                      padding: EdgeInsets.only(top: 15),
                      child: Text(
                        'Export Task?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
