import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

class TaskDetails extends StatelessWidget {
  TaskDetails(
      {super.key,
      required this.selectedTaskId,
      required this.title,
      required this.type});
  final int selectedTaskId;
  final String title;
  final String type;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _statusController = TextEditingController();

  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _taskIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    int ownerId = 0; //???? dont you hardcode ownerId
    final provider = Provider.of<TaskDataStoreProvider>(context);
    List<DropdownMenuItem<int>>? taskIdDropdownMenuItems =
        provider.getTaskIdDropdownMenuItems(selectedTaskId, type);

    final selectedTask = provider.getTaskDetails(selectedTaskId, type);
    _statusController.text = selectedTask.status;
    List<TaskLink?> currentlyLinkedTasks = provider.currentlyLinkedTasks(type);
    final size = MediaQuery.of(context).size;

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
                var json = provider.serializeTaskObject(selectedTask);
                var qrPainterImage = provider.generateQRCode(json);
                provider.saveQrCodetoAppDirectory(
                    ownerId, selectedTaskId, qrPainterImage, type);
              },
              child: Row(
                children: [
                  const Icon(Icons.qr_code),
                  SizedBox(width: (MediaQuery.of(context).size.width) * 0.02),
                  const Text('Export Task')
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
            if (provider.cards(type).isNotEmpty)
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
                        cards: provider.cards(type),
                        padding: const EdgeInsets.all(24.0),
                      ),
                    ),
                  ],
                ),
              ),
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
                      onChanged: (value) async {
                        _statusController.text = value as String;

                        var selectedStatus = _statusController.text.isNotEmpty
                            ? _statusController.text
                            : selectedTask.status.toString();
                        if (_formKey.currentState!.validate()) {
                          await provider
                              .updateSelectedTask(
                                  ownerId, selectedTaskId, selectedStatus, type)
                              .then((value) => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          'TaskId "${selectedTask.id}" with title "${selectedTask.taskTitle}" status updated to $selectedStatus'))));
                        }
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
                        'Task ID: ${selectedTask.id}, \nTask Type: $type\nLast updated: ${selectedTask.lastUpdate.toString().substring(0, 19)}',
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
                                onPressed: () async {
                                  provider.clearCurrentlyLinkedImages(type);
                                  await provider.uploadPictureViaCamera(
                                      ownerId, selectedTaskId, type);
                                },
                                child: const Text('Take photo'),
                              ),
                            ),
                            SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width) * 0.02),
                            Flexible(
                              child: ElevatedButton(
                                onPressed: () async {
                                  provider.clearCurrentlyLinkedImages(type);
                                  await provider.uploadPictureViaStorage(
                                      ownerId, selectedTaskId, type);
                                },
                                child: const Text('Upload photo'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (context
                        .read<TaskDataStoreProvider>()
                        .checkLinksEnablementEditForm)
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
                                    key: ValueKey("linkedTaskLink$index"),
                                    backgroundColor: Colors.brown,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        provider.clearLinkedTaskIds(type);
                                        provider.clearLinkedTasks(type);
                                        provider
                                            .clearCurrentlyLinkedTasks(type);
                                        provider
                                            .clearCurrentlyLinkedImages(type);

                                        await provider
                                            .getTaskImageStack(
                                                linkedTaskId, ownerId, type)
                                            .then((value) async => provider
                                                .getCurrentlyLinkedTasks(
                                                    linkedTaskId, type))
                                            .then((value) => context.push(
                                                '/taskdetail?taskId=$linkedTaskId&type=$type')); // ???? move this to tasks details page
                                      },
                                    ),
                                  ),
                                  CircleAvatar(
                                    key: ValueKey('deleteLinkedTask$index'),
                                    backgroundColor: Colors.brown,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        await provider
                                            .removeLinkedTask(
                                                ownerId,
                                                linkedTaskId,
                                                selectedTaskId,
                                                type)
                                            .then((value) => ScaffoldMessenger
                                                    .of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Link to taskId "$linkedTaskId" with title "$taskTitle" removed'))));
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
                      visible: context
                          .read<TaskDataStoreProvider>()
                          .checkLinksEnablementEditForm,
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
                                            await provider
                                                .addLinkedTask(
                                                    ownerId,
                                                    selectedTaskId,
                                                    taskIdControllerInt,
                                                    _labelController.text,
                                                    type)
                                                .then((value) async =>
                                                    await provider
                                                        .getCurrentlyLinkedTasks(
                                                            selectedTaskId,
                                                            type))
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
                                        if (!currentlyLinkedTasks.any(
                                            (element) =>
                                                element!.relation ==
                                                labels[0])) {
                                          await provider
                                              .addLinkedTask(
                                                  ownerId,
                                                  selectedTaskId,
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
          ],
        ),
      ),
    );
  }
}
