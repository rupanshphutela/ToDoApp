import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';

import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/models/task_image.dart';
import 'package:to_do_app/models/task_link.dart';
import 'package:to_do_app/models_dao/app_database.dart';
import 'package:to_do_app/utils/task_image_stack.dart';

class Tasks with ChangeNotifier {
  final AppDatabase _database;

  Tasks(this._database);
  //All about tasks
  List<Task>? _tasks = [];

  List<Task> get tasks => _tasks!.toList();
  // bool created = true;

  void getAllTasks() async {
    // if (created == true) {
    // created = false;
    // for (var index = 0; index < 4; index++) {
    //   await addTask(
    //       Task(
    //           ownerId: 0,
    //           taskTitle: "Dummy Title $index",
    //           description: "Dummy Description $index",
    //           status: index == 0 ? "open" : "in progress",
    //           lastUpdate: DateTime.now().toString()),
    //       linkedTasks);
    // }
    // }
    _tasks = await _database.taskDao.getAllTasks();
    _tasks!.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    notifyListeners();
  }

  //???? Hard codes for now
  int ownerId = 0;
  int taskId = 999999;

  updateCurrentTaskId(int currentTaskId) {
    taskId = currentTaskId;
  }

  applyFilter(String filter) {
    if (filter != 'all') {
      return _tasks!.where((x) => x.status.contains(filter)).toList();
    } else {
      return _tasks!.toList();
    }
  }

  deleteTask(int taskId) async {
    _tasks!.removeWhere((element) => element.id == taskId);
    await _database.taskLinkDao.deleteLinkedTasksForDeletedTask(taskId);
    await _database.taskDao.deleteTask(taskId);
    getAllTasks();
    getCurrentlyLinkedTasks(taskId);
    notifyListeners();
  }

  addTask(Task task, List<TaskLink?> linkedTasks) async {
    await _database.taskDao.insertTask(task);
    if (linkedTasks.isNotEmpty) {
      int? latestTaskId =
          await _database.taskDao.findLatestTaskIdByOwner(task.ownerId);
      for (var element in linkedTasks) {
        await _database.taskLinkDao.insertTaskLink(TaskLink(
            taskId: latestTaskId!,
            relation: element!.relation,
            linkedTaskId: element.linkedTaskId,
            lastUpdate: DateTime.now().toString()));
      }
    }
    getAllTasks();
    clearLinkedTasks();
    notifyListeners();
  }

  //Linked Tasks to show linked tasks
  List<TaskLink?> linkedTasks = [];

  bool checkIsNewTask(int taskId) {
    bool isNewTask;
    var task = _tasks!.where((element) => element.id == taskId).toList();
    if (task.isNotEmpty) {
      isNewTask = false;
    } else {
      isNewTask = true;
    }
    return isNewTask;
  }

  addLinkedTask(int primaryTaskId, int linkedTaskId, String relation) async {
    bool isNewTask = checkIsNewTask(primaryTaskId);
    if (!isNewTask) {
      //create linked task with new time
      await _database.taskLinkDao.insertTaskLink(TaskLink(
          taskId: primaryTaskId,
          relation: relation,
          linkedTaskId: linkedTaskId,
          lastUpdate: DateTime.now().toString()));
      //Update main task with current time
      await _database.taskDao
          .updateTaskWithCurrentTime(primaryTaskId, DateTime.now().toString());
      getCurrentlyLinkedTasks(primaryTaskId);
      getAllTasks();
    } else {
      linkedTasks.add(TaskLink(
          taskId: 9999,
          relation: relation,
          linkedTaskId: linkedTaskId,
          lastUpdate: DateTime.now().toString()));
    }
    notifyListeners();
  }

  removeLinkedTask(int linkedTaskId, int primaryTaskId) async {
    bool isNewTask = checkIsNewTask(primaryTaskId);
    if (!isNewTask) {
      //delete linked task from linked tasks table
      await _database.taskLinkDao.deleteLinkedTask(linkedTaskId, primaryTaskId);
      //update date/time in main task table
      await _database.taskDao
          .updateTaskWithCurrentTime(primaryTaskId, DateTime.now().toString());
      getAllTasks();
      linkedTaskIds.remove(linkedTaskId);
    } else {
      linkedTasks
          .removeWhere((element) => element!.linkedTaskId == linkedTaskId);
      linkedTaskIds.remove(linkedTaskId);
    }
    notifyListeners();
  }

  Task? getTaskDetails(int? taskId) {
    if (taskId.toString().isNotEmpty && taskId != 0) {
      return _tasks!.where((element) => taskId == element.id).first;
    } else {
      return null;
    }
  }

  //Dropdown Menu Task Ids to link tasks
  List<int?> allTaskIdDropdownMenuItems = [];

  List<DropdownMenuItem<int>> taskIdDropdownMenuItems = [];
  List<int> linkedTaskIds = [];

  List<DropdownMenuItem<int>> getTaskIdDropdownMenuItems(int taskId) {
    linkedTaskIds.clear();
    allTaskIdDropdownMenuItems = _tasks!.map((e) => e.id).toList();
    var task = _tasks!.where((element) => element.id == taskId).toList();
    if (task.isNotEmpty && currentlyLinkedTasks.isNotEmpty) {
      linkedTaskIds
          .addAll(currentlyLinkedTasks.map((task) => task!.linkedTaskId));
    } else if (task.isEmpty && linkedTasks.isNotEmpty) {
      for (var linkedTask in linkedTasks) {
        linkedTaskIds.add(linkedTask!.linkedTaskId);
      }
    }

    allTaskIdDropdownMenuItems.remove(taskId);
    taskIdDropdownMenuItems = allTaskIdDropdownMenuItems
        .map((taskIdMenuItem) => DropdownMenuItem(
              enabled: allTaskIdDropdownMenuItems
                  .where((element) => !linkedTaskIds.contains(element))
                  .toList()
                  .contains(taskIdMenuItem),
              value: taskIdMenuItem,
              child: Text(
                "$taskIdMenuItem: ${getTaskDetails(taskIdMenuItem)!.taskTitle}",
                style: TextStyle(
                  color: allTaskIdDropdownMenuItems
                          .where((element) => !linkedTaskIds.contains(element))
                          .toList()
                          .contains(taskIdMenuItem)
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
            ))
        .toList();
    return taskIdDropdownMenuItems;
  }

  List<TaskLink?> currentlyLinkedTasks = [];

  void getCurrentlyLinkedTasks(int taskId) async {
    currentlyLinkedTasks =
        await _database.taskLinkDao.getExistingTaskLinksByTaskId(taskId);
    currentlyLinkedTasks.sort((a, b) => b!.lastUpdate.compareTo(a!.lastUpdate));
    notifyListeners();
  }

  updateSelectedTask(int selectedTaskId, String selectedStatus) async {
    await _database.taskDao.updateTaskStatusAndTime(
        selectedTaskId, selectedStatus, DateTime.now().toString());
    getAllTasks();
    notifyListeners();
  }

  bool get checkLinksEnablementAddForm => _tasks!.isNotEmpty;
  bool get checkLinksEnablementEditForm => _tasks!.length > 1;

  clearLinkedTasks() {
    linkedTasks.clear();
    notifyListeners();
  }

  clearLinkedTaskIds() {
    linkedTaskIds.clear();
    notifyListeners();
  }

  /// Task Image Cards on tasks

  List<TaskImage> _taskImages = [];

  List<TaskImageStack> _cards = [];

  List<TaskImageStack> get cards {
    return _cards.toList();
  }

  getTaskImageStack(int selectedTaskId) async {
    _taskImages = await _database.taskImageDao
        .getExistingTaskImagesByTaskId(selectedTaskId);
    _cards = _taskImages
        .map((image) => TaskImageStack(
              taskImage: image,
            ))
        .toList();
    notifyListeners();
  }

  Future<void> requestCameraPermission(
      int selectedTaskOwnerId, int selectedTaskId) async {
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus == PermissionStatus.granted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        return;
      }

      //save to file
      final directory = await getApplicationDocumentsDirectory();
      var imageName =
          '${ownerId}_${taskId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newImage = File('${directory.path}/$imageName');
      await pickedFile.saveTo(newImage.path);

      // //save to gallery
      // final extDirectory = await getExternalStorageDirectory();
      // final galleryDirectory = '${extDirectory!.path}/DCIM';
      // final originalFile = File(pickedFile.path);
      // final newFile = await originalFile.copy('$galleryDirectory/$imageName');
      // await pickedFile.saveTo(newFile.path);

      await _database.taskImageDao.insertTaskImage(TaskImage(
          taskId: selectedTaskId,
          ownerId: selectedTaskOwnerId,
          imagePath: newImage.path,
          uploadDate: DateTime.now().toString()));

      getTaskImageStack(selectedTaskId);
      notifyListeners();
    }
  }

  Future<void> requestStoragePermission(
      int selectedTaskOwnerId, int selectedTaskId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    var imageName =
        '${ownerId}_${taskId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newImage = File('${directory.path}/$imageName');
    await pickedFile.saveTo(newImage.path);
    await _database.taskImageDao.insertTaskImage(TaskImage(
        taskId: selectedTaskId,
        ownerId: selectedTaskOwnerId,
        imagePath: newImage.path,
        uploadDate: DateTime.now().toString()));

    getTaskImageStack(selectedTaskId);
    notifyListeners();
  }

  String serializeTaskObject(Task task) {
    Map<String, dynamic> toMap() {
      return {
        'taskTitle': task.taskTitle,
        'description': task.description,
        'ownerId': task.ownerId,
        'status': task.status,
        'lastUpdate': task.lastUpdate,
      };
    }

    String toJson() => json.encode(toMap());
    return toJson();
  }

  QrPainter generateQRCode(String json) {
    final qrCode = QrPainter(
      data: json,
      version: QrVersions.auto,
      color: Colors.white,
    );
    // sleep(Duration(seconds: 5));
    return qrCode;
  }

  saveQrCodetoAppDirectory(int taskId, QrPainter image) async {
    //save to file
    final qrCode = await image.toImageData(2000);
    final bytes = Uint8List.view(qrCode!.buffer);
    final directory = await getApplicationDocumentsDirectory();
    var imageName = '${ownerId}_${taskId}_QrImage.jpg';
    final newImage = File('${directory.path}/$imageName');
    await newImage.writeAsBytes(bytes);

    Share.shareFiles([newImage.path], text: imageName);
  }
}
