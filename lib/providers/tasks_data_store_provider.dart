import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:floor/floor.dart';
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

import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDataStoreProvider with ChangeNotifier {
  final TaskDataStore personalDataStore;
  final TaskDataStore sharedDataStore;
  List<Task>? tasks;

  //single responsibility : fetch data to provide to listeners
  TaskDataStoreProvider({
    required TaskDataStore firestoreDataStore,
    required TaskDataStore floorDataStore,
  })  : personalDataStore = floorDataStore,
        sharedDataStore = firestoreDataStore;

  void fetchAllTasksForUser(int ownerId) async {
    //no await here to kickoff simultaneously
    final futurePersonalTasks = personalDataStore.getTasksForUser(ownerId);
    final futureSharedTasks = sharedDataStore.getTasksForUser(ownerId);

    final List<Task> combined = [];
    combined.addAll(await futurePersonalTasks);
    combined.addAll(await futureSharedTasks);
    tasks = combined;
    notifyListeners();
  }

  bool get checkLinksEnablementAddForm => tasks!.isNotEmpty;
  bool get checkLinksEnablementEditForm => tasks!.length > 1;
}

//abstract no resp
abstract class TaskDataStore extends ChangeNotifier {
  List<TaskLink?> get linkedTasks => linkedTasks;

//use case – get all of inventory items belonging to a particular user
  Future<List<Task>> getTasksForUser(int ownerId);

  List<DropdownMenuItem<int>>? getTaskIdDropdownMenuItems(int taskId);

  getTaskDetails(int taskId);

  void addTask(Task task, List<TaskLink?> linkedTasks);

  void removeLinkedTask(int linkedTaskId, int primaryTaskId);

  void addLinkedTask(int primaryTaskId, int linkedTaskId, String relation);
}

//single resp : translate use cases t firestore interactions
//// does not provide data, rednerring, or representation hierarchy..
///it only cares about this specific use case – how it gets implemente wrt firestore
class FirestoreTaskDataStore extends TaskDataStore {
//to mock a database here //we have flexibility
  final FirebaseFirestore _firestore;
  FirestoreTaskDataStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  @override
  Future<List<Task>> getTasksForUser(int ownerId) async {
    final tasks = await FirebaseFirestore.instance
        .collection('task')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return tasks.docs.map((doc) => Task.fromJson(doc)).toList();

//it returns docs which are map of string dynamic. .it returns snapshot of data() because there is a metadata inside .doc
//exists is useful with query by id and returns if it found something or not
//idea is to make db readonly
//firebasefirestore.instance is a singleton object and for sqlite it’s a local object
  }

  @override
  List<DropdownMenuItem<int>>? getTaskIdDropdownMenuItems(int taskId) {
    return null;
  }

  @override
  getTaskDetails(int taskId) {
    // TODO: implement getTaskDetails
    throw UnimplementedError();
  }

  @override
  void addTask(Task task, List<TaskLink?> linkedTasks) {
    // TODO: implement addTask
  }

  @override
  List<TaskLink?> linkedTasks = [];

  @override
  void removeLinkedTask(int linkedTaskId, int primaryTaskId) {
    // TODO: implement removeLinkedTask
  }

  @override
  void addLinkedTask(int primaryTaskId, int linkedTaskId, String relation) {
    // TODO: implement addLinkedTask
  }
}

//single responsibility: Translate use cases to SQflite as a local datastore
class FloorSqfliteTaskDataStore extends TaskDataStore {
  final AppDatabase _database;

  FloorSqfliteTaskDataStore(AppDatabase database)
      : _database = database; // this is dependency injection
  //All about tasks
  List<Task>? personalTasks;

  // List<Task> get tasks => _tasks!.toList();
  // bool created = true;
  @override
  Future<List<Task>> getTasksForUser(int ownerId) async {
    // if (created == true) {
    //   created = false;
    //   for (var index = 0; index < 4; index++) {
    //     await addTask(
    //         Task(
    //             ownerId: 0,
    //             taskTitle: "Dummy Title $index",
    //             description: "Dummy Description $index",
    //             status: index == 0 ? "open" : "in progress",
    //             lastUpdate: DateTime.now().toString()),
    //         []);
    //   }
    // }
    final tasks = await _database.taskDao.getTasksByOwnerId(ownerId);
    tasks.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    if (tasks.isNotEmpty) personalTasks = tasks;
    return tasks;
  }

  @override
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
    getTasksForUser(task.ownerId);
    clearLinkedTasks();
    notifyListeners();
  }

  //Dropdown Menu Task Ids to link tasks
  List<int?> allTaskIdDropdownMenuItems = [];

  List<DropdownMenuItem<int>> taskIdDropdownMenuItems = [];
  List<int> linkedTaskIds = [];
  List<TaskLink?> currentlyLinkedTasks = [];
  @override
  List<TaskLink?> linkedTasks = [];

  @override
  List<DropdownMenuItem<int>> getTaskIdDropdownMenuItems(int taskId) {
    linkedTaskIds.clear();
    allTaskIdDropdownMenuItems = personalTasks!.map((e) => e.id).toList();
    var task = personalTasks!.where((element) => element.id == taskId).toList();
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

  @override
  Task? getTaskDetails(int? taskId) {
    if (taskId.toString().isNotEmpty && taskId != 0) {
      return personalTasks!.where((element) => taskId == element.id).first;
    } else {
      return null;
    }
  }

  //all about linked tasks in task_form.dart
  @override
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
      // getTasksForUser(); ???? why do I need it?
    } else {
      linkedTasks.add(TaskLink(
          taskId: 9999,
          relation: relation,
          linkedTaskId: linkedTaskId,
          lastUpdate: DateTime.now().toString()));
    }
    notifyListeners();
  }

  @override
  removeLinkedTask(int linkedTaskId, int primaryTaskId) async {
    bool isNewTask = checkIsNewTask(primaryTaskId);
    if (!isNewTask) {
      //delete linked task from linked tasks table
      await _database.taskLinkDao.deleteLinkedTask(linkedTaskId, primaryTaskId);
      //update date/time in main task table
      await _database.taskDao
          .updateTaskWithCurrentTime(primaryTaskId, DateTime.now().toString());
      // getAllTasks(); ???? why do I need this?
      linkedTaskIds.remove(linkedTaskId);
      getCurrentlyLinkedTasks(primaryTaskId);
    } else {
      linkedTasks
          .removeWhere((element) => element!.linkedTaskId == linkedTaskId);
      linkedTaskIds.remove(linkedTaskId);
    }
    notifyListeners();
  }

  clearLinkedTasks() {
    linkedTasks.clear();
    notifyListeners();
  }

  bool checkIsNewTask(int taskId) {
    bool isNewTask;
    var task = personalTasks!.where((element) => element.id == taskId).toList();
    if (task.isNotEmpty) {
      isNewTask = false;
    } else {
      isNewTask = true;
    }
    return isNewTask;
  }

  void getCurrentlyLinkedTasks(int taskId) async {
    currentlyLinkedTasks =
        await _database.taskLinkDao.getExistingTaskLinksByTaskId(taskId);
    currentlyLinkedTasks.sort((a, b) => b!.lastUpdate.compareTo(a!.lastUpdate));
    notifyListeners();
  }
}
/*
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
    //notifyListeners();
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
    //notifyListeners();
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
    //notifyListeners();
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
    //notifyListeners();
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
      getCurrentlyLinkedTasks(primaryTaskId);
    } else {
      linkedTasks
          .removeWhere((element) => element!.linkedTaskId == linkedTaskId);
      linkedTaskIds.remove(linkedTaskId);
    }
    //notifyListeners();
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
    //notifyListeners();
  }

  updateSelectedTask(int selectedTaskId, String selectedStatus) async {
    await _database.taskDao.updateTaskStatusAndTime(
        selectedTaskId, selectedStatus, DateTime.now().toString());
    getAllTasks();
    //notifyListeners();
  }

  bool get checkLinksEnablementAddForm => _tasks!.isNotEmpty;
  bool get checkLinksEnablementEditForm => _tasks!.length > 1;

  clearLinkedTasks() {
    linkedTasks.clear();
    //notifyListeners();
  }

  clearLinkedTaskIds() {
    linkedTaskIds.clear();
    //notifyListeners();
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
    //notifyListeners();
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
      //notifyListeners();
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
    //notifyListeners();
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
}*/

/*
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
    //notifyListeners();
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
    //notifyListeners();
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
    //notifyListeners();
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
    //notifyListeners();
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
      getCurrentlyLinkedTasks(primaryTaskId);
    } else {
      linkedTasks
          .removeWhere((element) => element!.linkedTaskId == linkedTaskId);
      linkedTaskIds.remove(linkedTaskId);
    }
    //notifyListeners();
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
    //notifyListeners();
  }

  updateSelectedTask(int selectedTaskId, String selectedStatus) async {
    await _database.taskDao.updateTaskStatusAndTime(
        selectedTaskId, selectedStatus, DateTime.now().toString());
    getAllTasks();
    //notifyListeners();
  }

  bool get checkLinksEnablementAddForm => _tasks!.isNotEmpty;
  bool get checkLinksEnablementEditForm => _tasks!.length > 1;

  clearLinkedTasks() {
    linkedTasks.clear();
    //notifyListeners();
  }

  clearLinkedTaskIds() {
    linkedTaskIds.clear();
    //notifyListeners();
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
    //notifyListeners();
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
      //notifyListeners();
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
    //notifyListeners();
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
}*/
