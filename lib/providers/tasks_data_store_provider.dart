import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';
import 'package:to_do_app/models/group.dart';

import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/models/task_image.dart';
import 'package:to_do_app/models/task_link.dart';
import 'package:to_do_app/models/user_group.dart';
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

  Future<void> fetchAllTasksForUser(int ownerId) async {
    //no await here to kickoff simultaneously
    final futurePersonalTasks = personalDataStore.getTasksForUser(ownerId);
    final futureSharedTasks = sharedDataStore.getTasksForUser(ownerId);

    final List<Task> combined = [];
    combined.addAll(await futurePersonalTasks);
    combined.addAll(await futureSharedTasks);
    tasks = combined;
    tasks!.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    notifyListeners();
  }

  bool get checkLinksEnablementAddForm {
    if (tasks != null && tasks!.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  bool get checkLinksEnablementEditForm {
    if (tasks != null && tasks!.isNotEmpty && tasks!.length > 1) {
      return true;
    } else {
      return false;
    }
  }

  void addTask(Task task, List<TaskLink?> linkedTasks) {
    if (task.type == "personal") {
      personalDataStore.addTask(task, linkedTasks);
    } else {
      sharedDataStore.addTask(task, linkedTasks);
    }
    fetchAllTasksForUser(task.ownerId);
    notifyListeners();
  }

  bool enableGroupsinTasksForm = false;

  enableGroupsDropdown() {
    enableGroupsinTasksForm = true;
    notifyListeners();
  }

  disableGroupsDropdown() {
    enableGroupsinTasksForm = false;
    notifyListeners();
  }

  void getAllGroups() {
    sharedDataStore.getAllGroups();
  }

  void getUserGroups(int ownerId) async {
    await personalDataStore.getUserGroups(ownerId);
  }

  void addGroup(Group group) async {
    await sharedDataStore.addGroup(group);
    await sharedDataStore.getAllGroups();
    notifyListeners();
  }

  void addGroupToUserGroups(UserGroup userGroup) async {
    await personalDataStore.addGroupToUserGroups(userGroup);
    await personalDataStore.getUserGroups(userGroup.userId);
    await sharedDataStore.getAllGroups();
    notifyListeners();
  }

  void removeGroupFromUserGroups(int id, int userId) async {
    await personalDataStore.removeGroupFromUserGroups(id, userId);
    await personalDataStore.getUserGroups(userId);
    await sharedDataStore.getAllGroups();
    notifyListeners();
  }

  Future<void> addLinkedTask(int ownerId, int primaryTaskId, int linkedTaskId,
      String relation, String type) async {
    if (type == 'personal') {
      await personalDataStore.addLinkedTask(
          ownerId, primaryTaskId, linkedTaskId, relation);
    } else if (type == 'shared') {
      await sharedDataStore.addLinkedTask(
          ownerId, primaryTaskId, linkedTaskId, relation);
    } else {
      Exception('Unconfigured task type');
    }
    await fetchAllTasksForUser(ownerId);
    notifyListeners();
  }

  List<DropdownMenuItem<int>>? getTaskIdDropdownMenuItems(
      int taskId, String type) {
    if (type == 'personal') {
      return personalDataStore.getTaskIdDropdownMenuItems(taskId);
    } else if (type == 'shared') {
      return sharedDataStore.getTaskIdDropdownMenuItems(taskId);
    } else {
      return [];
    }
  }

  Future<void> getTaskImageStack(
      int selectedTaskId, int ownerId, String type) async {
    if (type == 'personal') {
      await personalDataStore.getTaskImageStack(selectedTaskId, ownerId);
    } else if (type == 'shared') {
      await sharedDataStore.getTaskImageStack(selectedTaskId, ownerId);
    }
    fetchAllTasksForUser(ownerId);
  }

  getTaskDetails(int taskId, String type) {
    if (type == 'personal') {
      return personalDataStore.getTaskDetails(taskId);
    } else if (type == 'shared') {
      return sharedDataStore.getTaskDetails(taskId);
    } else {
      return null;
    }
  }

  List<TaskLink?> currentlyLinkedTasks(type) {
    if (type == 'personal') {
      return personalDataStore.currentlyLinkedTasks;
    } else if (type == 'shared') {
      return sharedDataStore.currentlyLinkedTasks;
    } else {
      return [];
    }
  }

  String serializeTaskObject(Task task) {
    Map<String, dynamic> toMap() {
      return {
        'taskTitle': task.taskTitle,
        'description': task.description,
        'ownerId': task.ownerId,
        'status': task.status,
        'lastUpdate': task.lastUpdate,
        'type': task.type,
        'group': task.group,
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

  saveQrCodetoAppDirectory(
      int ownerId, int taskId, QrPainter image, String type) async {
    //save to file
    final qrCode = await image.toImageData(2000);
    final bytes = Uint8List.view(qrCode!.buffer);
    final directory = await getApplicationDocumentsDirectory();
    var imageName = '${ownerId}_${taskId}_${type}_QrImage.jpg';
    final newImage = File('${directory.path}/$imageName');
    await newImage.writeAsBytes(bytes);

    Share.shareFiles([newImage.path], text: imageName);
  }

  cards(type) {
    if (type == 'personal') {
      return personalDataStore.cards;
    } else if (type == 'shared') {
      return sharedDataStore.cards;
    } else {
      return [];
    }
  }

  Future<void> updateSelectedTask(int ownerId, int selectedTaskId,
      String selectedStatus, String type) async {
    if (type == 'personal') {
      await personalDataStore.updateSelectedTask(
          ownerId, selectedTaskId, selectedStatus);
    } else if (type == 'shared') {
      await sharedDataStore.updateSelectedTask(
          ownerId, selectedTaskId, selectedStatus);
    }
    fetchAllTasksForUser(ownerId);
  }

  Future<void> uploadPictureViaCamera(
      int selectedTaskOwnerId, int selectedTaskId, String type) async {
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
          '${selectedTaskOwnerId}_${selectedTaskId}_${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newImage = File('${directory.path}/$imageName');
      await pickedFile.saveTo(newImage.path);

      // //save to gallery
      // final extDirectory = await getExternalStorageDirectory();
      // final galleryDirectory = '${extDirectory!.path}/DCIM';
      // final originalFile = File(pickedFile.path);
      // final newFile = await originalFile.copy('$galleryDirectory/$imageName');
      // await pickedFile.saveTo(newFile.path);

      TaskImage taskImage = TaskImage(
          taskId: selectedTaskId,
          ownerId: selectedTaskOwnerId,
          imagePath: newImage.path,
          uploadDate: DateTime.now().toString());

      if (type == 'personal') {
        await personalDataStore.saveImagePathtoDataStore(taskImage);
      } else if (type == 'shared') {
        await sharedDataStore.saveImagePathtoDataStore(taskImage);
      }
      getTaskImageStack(selectedTaskId, selectedTaskOwnerId, type);
      fetchAllTasksForUser(selectedTaskOwnerId);
    }
  }

  Future<void> uploadPictureViaStorage(
      int selectedTaskOwnerId, int selectedTaskId, String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    var imageName =
        '${selectedTaskOwnerId}_${selectedTaskId}_${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newImage = File('${directory.path}/$imageName');
    await pickedFile.saveTo(newImage.path);

    TaskImage taskImage = TaskImage(
        taskId: selectedTaskId,
        ownerId: selectedTaskOwnerId,
        imagePath: newImage.path,
        uploadDate: DateTime.now().toString());

    if (type == 'personal') {
      await personalDataStore.saveImagePathtoDataStore(taskImage);
    } else if (type == 'shared') {
      await sharedDataStore.saveImagePathtoDataStore(taskImage);
    }
    getTaskImageStack(selectedTaskId, selectedTaskOwnerId, type);
    fetchAllTasksForUser(selectedTaskOwnerId);
  }

  void clearLinkedTaskIds(String type) {
    if (type == 'personal') {
      personalDataStore.clearLinkedTaskIds();
    } else if (type == 'shared') {
      sharedDataStore.clearLinkedTaskIds();
    }
  }

  Future<void> getCurrentlyLinkedTasks(int linkedTaskId, String type) async {
    if (type == 'personal') {
      await personalDataStore.getCurrentlyLinkedTasks(linkedTaskId);
    } else if (type == 'shared') {
      await sharedDataStore.getCurrentlyLinkedTasks(linkedTaskId);
    }
  }

  Future<void> removeLinkedTask(
      int ownerId, int linkedTaskId, int selectedTaskId, String type) async {
    if (type == 'personal') {
      await personalDataStore.removeLinkedTask(
          ownerId, linkedTaskId, selectedTaskId);
    } else if (type == 'shared') {
      await sharedDataStore.removeLinkedTask(
          ownerId, linkedTaskId, selectedTaskId);
    }
    fetchAllTasksForUser(ownerId);
  }

  List<Group> groups() {
    return sharedDataStore.groups;
  }

  List<String>? userGroupNames() {
    return personalDataStore.userGroupNames;
  }

  void deleteTask(int ownerId, int taskId, String type) async {
    if (type == 'personal') {
      await personalDataStore.deleteTask(ownerId, taskId);
    } else if (type == 'shared') {
      await sharedDataStore.deleteTask(ownerId, taskId);
    }
    tasks!.removeWhere((element) => element.id == taskId);
    fetchAllTasksForUser(ownerId);
  }

  List<DropdownMenuItem<String>>? getUserGroupDropdownMenuItems(int ownerId) {
    return personalDataStore.getUserGroupDropdownMenuItems(ownerId);
  }

  List<TaskLink?> linkedTasks(String type) {
    if (type == 'personal') {
      return personalDataStore.linkedTasks;
    } else if (type == 'shared') {
      return sharedDataStore.linkedTasks;
    } else {
      return [];
    }
  }

  void clearCurrentlyLinkedTasks(String type) {
    if (type == 'personal') {
      personalDataStore.clearCurrentlyLinkedTasks();
    } else if (type == 'shared') {
      sharedDataStore.clearCurrentlyLinkedTasks();
    }
  }

  void clearLinkedTasks(String type) {
    if (type == 'personal') {
      personalDataStore.clearLinkedTasks();
    } else if (type == 'shared') {
      sharedDataStore.clearLinkedTasks();
    }
  }

  void clearCurrentlyLinkedImages(String type) {
    if (type == 'personal') {
      personalDataStore.clearCurrentlyLinkedImages();
    } else if (type == 'shared') {
      sharedDataStore.clearCurrentlyLinkedImages();
    }
  }
}

//abstract no resp
abstract class TaskDataStore {
  List<TaskLink?> get linkedTasks => linkedTasks;

  List<TaskLink?> get currentlyLinkedTasks => currentlyLinkedTasks;

  get cards => cards;

  List<String> get userGroupNames => userGroupNames;

  List<Group> get groups => groups;

//use case – get all of inventory items belonging to a particular user
  Future<List<Task>> getTasksForUser(int ownerId);

  List<DropdownMenuItem<int>>? getTaskIdDropdownMenuItems(int taskId);

  getTaskDetails(int taskId);

  void addTask(Task task, List<TaskLink?> linkedTasks);

  Future<void> deleteTask(int ownerId, int taskId);

  Future<void> removeLinkedTask(
      int ownerId, int linkedTaskId, int primaryTaskId);

  Future<void> addLinkedTask(
      int ownerId, int primaryTaskId, int linkedTaskId, String relation);

  Future<void> getTaskImageStack(int selectedTaskId, int ownerId);

  Future<void> updateSelectedTask(
      int ownerId, int selectedTaskId, String selectedStatus);

  void clearLinkedTasks();

  void clearLinkedTaskIds();

  Future<void> getCurrentlyLinkedTasks(int taskId);

  List<DropdownMenuItem<String>>? getUserGroupDropdownMenuItems(int ownerId);

  Future<void> getUserGroups(int ownerId);

  Future<void> getAllGroups();

  Future<void> addGroupToUserGroups(UserGroup userGroup);

  Future<void> removeGroupFromUserGroups(int id, int userId);

  Future<void> addGroup(Group groupObject);

  Future<void> saveImagePathtoDataStore(TaskImage taskImage);

  void clearCurrentlyLinkedTasks();

  void clearCurrentlyLinkedImages();
}

//single resp : translate use cases t firestore interactions
//// does not provide data, rednerring, or representation hierarchy..
///it only cares about this specific use case – how it gets implemente wrt firestore
class FirestoreTaskDataStore extends TaskDataStore {
//to mock a database here //we have flexibility
  final FirebaseFirestore _firestore;
  FirestoreTaskDataStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  List<Task>? sharedTasks;

  @override
  Future<List<Task>> getTasksForUser(int ownerId) async {
    final tasks = await FirebaseFirestore.instance
        .collection('task')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    var sharedTasksList = tasks.docs.map((doc) => Task.fromJson(doc)).toList();
    if (sharedTasksList.isNotEmpty) sharedTasks = sharedTasksList;
    return sharedTasksList;

//it returns docs which are map of string dynamic. .it returns snapshot of data() because there is a metadata inside .doc
//exists is useful with query by id and returns if it found something or not
//idea is to make db readonly
//firebasefirestore.instance is a singleton object and for sqlite it’s a local object
  }

  List<Group> _groups = [];

  @override
  List<Group> get groups => _groups.toList();

  List<int?> allTaskIdDropdownMenuItems = [];

  List<DropdownMenuItem<int>> taskIdDropdownMenuItems = [];
  List<int> linkedTaskIds = [];

  @override
  List<DropdownMenuItem<int>>? getTaskIdDropdownMenuItems(int taskId) {
    linkedTaskIds.clear();
    if (sharedTasks != null) {
      allTaskIdDropdownMenuItems = sharedTasks!.map((e) => e.id).toList();
      var task = sharedTasks!.where((element) => element.id == taskId).toList();
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
                  "$taskIdMenuItem: ${getTaskDetails(taskIdMenuItem!)!.taskTitle}",
                  style: TextStyle(
                    color: allTaskIdDropdownMenuItems
                            .where(
                                (element) => !linkedTaskIds.contains(element))
                            .toList()
                            .contains(taskIdMenuItem)
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
              ))
          .toList();
    }
    return taskIdDropdownMenuItems;
  }

  @override
  getTaskDetails(int taskId) {
    if (taskId.toString().isNotEmpty && taskId != 0) {
      return sharedTasks!.where((element) => taskId == element.id).first;
    } else {
      return null;
    }
  }

  @override
  addTask(Task task, List<TaskLink?> linkedTasks) async {
    int taskId = task.id ?? UniqueKey().hashCode;
    Task taskObject = Task(
      id: taskId,
      ownerId: task.ownerId,
      taskTitle: task.taskTitle,
      description: task.description,
      status: task.status,
      lastUpdate: task.lastUpdate,
      type: task.type,
      group: task.group,
      taskLinks: [],
      taskImages: [],
    );

    Map<String, dynamic> dataToSave = taskObject.toJson(taskObject);

    await FirebaseFirestore.instance.collection("task").add(dataToSave);

    if (linkedTasks.isNotEmpty) {
      for (var element in linkedTasks) {
        await addLinkedTask(
            task.ownerId, taskId, element!.linkedTaskId, element.relation);
      }
    }
    clearLinkedTasks();
  }

  @override
  List<TaskLink?> linkedTasks = [];

  @override
  List<TaskLink?> currentlyLinkedTasks = [];

  @override
  Future<void> removeLinkedTask(
      int ownerId, int linkedTaskId, int primaryTaskId) async {
    bool isNewTask = checkIsNewTask(primaryTaskId);
    if (!isNewTask) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('task')
          .where('id', isEqualTo: primaryTaskId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id;

        final DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('task')
            .doc(docId)
            .get();

        final taskLinksMap = snapshot.get('taskLinks');

        final taskLinkToRemove = taskLinksMap
            .where((taskLink) => taskLink['linkedTaskId'] == linkedTaskId)
            .toList();

        final DocumentReference documentReference =
            FirebaseFirestore.instance.collection('task').doc(docId);
        await documentReference.update({
          'taskLinks': FieldValue.arrayRemove([
            taskLinkToRemove.first,
          ])
        }).then((value) {
          debugPrint('Update successful');
        }).catchError((error) {
          debugPrint('Update failed: $error');
        });
      }

      linkedTaskIds.remove(linkedTaskId);
      clearCurrentlyLinkedTasks();
      await getCurrentlyLinkedTasks(primaryTaskId);
    } else {
      linkedTasks
          .removeWhere((element) => element!.linkedTaskId == linkedTaskId);
      linkedTaskIds.remove(linkedTaskId);
    }
  }

  bool checkIsNewTask(int taskId) {
    bool isNewTask;
    var task = sharedTasks!.where((element) => element.id == taskId).toList();
    if (task.isNotEmpty) {
      isNewTask = false;
    } else {
      isNewTask = true;
    }
    return isNewTask;
  }

  @override
  Future<void> addLinkedTask(
      int ownerId, int primaryTaskId, int linkedTaskId, String relation) async {
    bool isNewTask = checkIsNewTask(primaryTaskId);
    if (!isNewTask) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('task')
          .where('id', isEqualTo: primaryTaskId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id;
        DocumentReference documentReference =
            FirebaseFirestore.instance.collection('task').doc(docId);

        //update linked task
        await documentReference.update({
          'taskLinks': FieldValue.arrayUnion([
            {
              'id': UniqueKey().hashCode,
              'relation': relation,
              'taskId': primaryTaskId,
              'linkedTaskId': linkedTaskId,
              'lastUpdate': DateTime.now().toString(),
            }
          ]),
          'lastUpdate': DateTime.now().toString(),
        }).then((value) {
          debugPrint('Update successful');
        }).catchError((error) {
          debugPrint('Update failed: $error');
        });
      }
      clearCurrentlyLinkedTasks();
      await getCurrentlyLinkedTasks(primaryTaskId);
    } else {
      linkedTasks.add(TaskLink(
          taskId: 9999,
          relation: relation,
          linkedTaskId: linkedTaskId,
          lastUpdate: DateTime.now().toString()));
    }
  }

  @override
  Future<void> getCurrentlyLinkedTasks(int taskId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('task')
        .where('id', isEqualTo: taskId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String docId = querySnapshot.docs.first.id;

      final DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('task').doc(docId).get();

      final taskLinksMap = snapshot.get('taskLinks');

      if (taskLinksMap != null && taskLinksMap.isNotEmpty) {
        List<dynamic> taskLinks =
            taskLinksMap.map((doc) => TaskLink.fromJsonMap(doc)).toList();
        taskLinks.forEach((element) {
          currentlyLinkedTasks.add(element);
        });
        currentlyLinkedTasks
            .sort((a, b) => b!.lastUpdate.compareTo(a!.lastUpdate));
      }
    }
  }

  List<TaskImage> taskImages = [];

  List<TaskImageStack> _cards = [];

  @override
  List<TaskImageStack> get cards => _cards.toList();

  @override
  Future<void> getTaskImageStack(int selectedTaskId, int ownerId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('task')
        .where('id', isEqualTo: selectedTaskId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String docId = querySnapshot.docs.first.id;

      final DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('task').doc(docId).get();

      final taskImagesMap = snapshot.get('taskImages');

      if (taskImagesMap != null && taskImagesMap.isNotEmpty) {
        List<dynamic> taskImageList =
            taskImagesMap.map((doc) => TaskImage.fromJsonMap(doc)).toList();
        for (var element in taskImageList) {
          taskImages.add(element);
        }
        taskImageList.clear();

        _cards = taskImages
            .map((image) => TaskImageStack(
                  taskImage: image,
                ))
            .toList();
      }
    }
  }

  @override
  Future<void> updateSelectedTask(
      int ownerId, int selectedTaskId, String selectedStatus) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('task')
        .where('id', isEqualTo: selectedTaskId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String docId = querySnapshot.docs.first.id;
      DocumentReference documentReference =
          FirebaseFirestore.instance.collection('task').doc(docId);

      //update linked task
      await documentReference.update({
        'status': selectedStatus,
        'lastUpdate': DateTime.now().toString(),
      }).then((value) {
        debugPrint('Update successful');
      }).catchError((error) {
        debugPrint('Update failed: $error');
      });
    }
    clearLinkedTasks();
  }

  @override
  void clearLinkedTasks() {
    linkedTasks.clear();
  }

  @override
  void clearLinkedTaskIds() {
    // TODO: implement clearLinkedTaskIds
  }

  @override
  Future<void> deleteTask(int ownerId, int taskId) async {
    // TODO: implement deleteTask
    // throw UnimplementedError();
  }

  @override
  Future<void> getAllGroups() async {
    var groupDocs = await FirebaseFirestore.instance.collection('group').get();
    _groups = groupDocs.docs.map((doc) => Group.fromJson(doc)).toList();
  }

  @override
  Future<void> getUserGroups(int ownerId) async {
    // TODO: implement getUserGroups
    throw UnimplementedError();
  }

  @override
  Future<void> addGroupToUserGroups(UserGroup userGroup) async {
    // TODO: implement addGroupToUserGroups
    throw UnimplementedError();
  }

  @override
  Future<void> removeGroupFromUserGroups(int id, int userId) async {
    // TODO: implement removeGroupFromUserGroups
    throw UnimplementedError();
  }

  @override
  List<DropdownMenuItem<String>>? getUserGroupDropdownMenuItems(int ownerId) {
    // TODO: implement getUserGroupDropdownMenuItems
    throw UnimplementedError();
  }

  @override
  Future<void> addGroup(Group groupObject) async {
    Group group = Group(
        id: groupObject.id,
        groupName: groupObject.groupName,
        creatorId: groupObject.creatorId);

    Map<String, dynamic> dataToSave = group.toJson(group);

    await FirebaseFirestore.instance.collection("group").add(dataToSave);
  }

  @override
  Future<void> saveImagePathtoDataStore(TaskImage taskImage) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('task')
        .where('id', isEqualTo: taskImage.taskId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String docId = querySnapshot.docs.first.id;
      DocumentReference documentReference =
          FirebaseFirestore.instance.collection('task').doc(docId);

      //update linked task
      await documentReference.update({
        'taskImages': FieldValue.arrayUnion([
          {
            'id': UniqueKey().hashCode,
            'taskId': taskImage.taskId,
            'ownerId': taskImage.ownerId,
            'imagePath': taskImage.imagePath,
            'uploadDate': DateTime.now().toString(),
          }
        ]),
        'lastUpdate': DateTime.now().toString(),
      }).then((value) {
        debugPrint('Update successful');
      }).catchError((error) {
        debugPrint('Update failed: $error');
      });
    }
  }

  @override
  void clearCurrentlyLinkedTasks() {
    currentlyLinkedTasks.clear();
  }

  @override
  void clearCurrentlyLinkedImages() {
    taskImages.clear();
    _cards.clear();
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
    clearLinkedTasks();
  }

  @override
  Future<void> deleteTask(int ownerId, int taskId) async {
    personalTasks!.removeWhere((element) => element.id == taskId);
    await _database.taskImageDao.deleteLinkedImagesForDeletedTask(taskId);
    await _database.taskLinkDao.deleteLinkedTasksForDeletedTask(taskId);
    await _database.taskDao.deleteTask(taskId);
    getCurrentlyLinkedTasks(taskId);
  }

  //Dropdown Menu Task Ids to link tasks
  List<int?> allTaskIdDropdownMenuItems = [];

  List<DropdownMenuItem<int>> taskIdDropdownMenuItems = [];
  List<int> linkedTaskIds = [];

  @override
  List<TaskLink?> currentlyLinkedTasks = [];
  @override
  List<TaskLink?> linkedTasks = [];

  @override
  List<DropdownMenuItem<int>>? getTaskIdDropdownMenuItems(int taskId) {
    linkedTaskIds.clear();
    if (personalTasks != null) {
      allTaskIdDropdownMenuItems = personalTasks!.map((e) => e.id).toList();
      var task =
          personalTasks!.where((element) => element.id == taskId).toList();
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
                            .where(
                                (element) => !linkedTaskIds.contains(element))
                            .toList()
                            .contains(taskIdMenuItem)
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
              ))
          .toList();
    }
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
  Future<void> addLinkedTask(
      int ownerId, int primaryTaskId, int linkedTaskId, String relation) async {
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
    } else {
      linkedTasks.add(TaskLink(
          taskId: 9999,
          relation: relation,
          linkedTaskId: linkedTaskId,
          lastUpdate: DateTime.now().toString()));
    }
  }

  @override
  Future<void> removeLinkedTask(
      int ownerId, int linkedTaskId, int primaryTaskId) async {
    bool isNewTask = checkIsNewTask(primaryTaskId);
    if (!isNewTask) {
      //delete linked task from linked tasks table
      await _database.taskLinkDao.deleteLinkedTask(linkedTaskId, primaryTaskId);
      //update date/time in main task table
      await _database.taskDao
          .updateTaskWithCurrentTime(primaryTaskId, DateTime.now().toString());
      linkedTaskIds.remove(linkedTaskId);
      getCurrentlyLinkedTasks(primaryTaskId);
    } else {
      linkedTasks
          .removeWhere((element) => element!.linkedTaskId == linkedTaskId);
      linkedTaskIds.remove(linkedTaskId);
    }
    // notifyListeners();
  }

  @override
  clearLinkedTasks() {
    linkedTasks.clear();
  }

  @override
  clearLinkedTaskIds() {
    linkedTaskIds.clear();
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

  @override
  Future<void> getCurrentlyLinkedTasks(int taskId) async {
    currentlyLinkedTasks =
        await _database.taskLinkDao.getExistingTaskLinksByTaskId(taskId);
    currentlyLinkedTasks.sort((a, b) => b!.lastUpdate.compareTo(a!.lastUpdate));
  }

  @override
  Future<void> updateSelectedTask(
      int ownerId, int selectedTaskId, String selectedStatus) async {
    await _database.taskDao.updateTaskStatusAndTime(
        selectedTaskId, selectedStatus, DateTime.now().toString());
    clearLinkedTasks();
  }

  /// Task Image Cards on tasks

  List<TaskImage> taskImages = [];

  List<TaskImageStack> _cards = [];

  @override
  List<TaskImageStack> get cards => _cards.toList();

  @override
  Future<void> getTaskImageStack(int selectedTaskId, int ownerId) async {
    taskImages = await _database.taskImageDao
        .getExistingTaskImagesByTaskId(selectedTaskId);
    _cards = taskImages
        .map((image) => TaskImageStack(
              taskImage: image,
            ))
        .toList();
  }

  @override
  Future<void> saveImagePathtoDataStore(TaskImage taskImage) async {
    await _database.taskImageDao.insertTaskImage(taskImage);
    await _database.taskDao
        .updateTaskWithCurrentTime(taskImage.taskId, DateTime.now().toString());
  }

  List<String> _userGroupNames = [];

  @override
  List<String> get userGroupNames => _userGroupNames.toList();

  @override
  Future<void> getUserGroups(int ownerId) async {
    var userGroups =
        await _database.userGroupDao.getUserGroupsByUserId(ownerId);
    _userGroupNames = userGroups.map((e) => e.groupName).toList();
  }

  List<String?> allUserGroupDropdownMenuItems = [];

  List<DropdownMenuItem<String>> userGroupDropdownMenuItems = [];

  @override
  List<DropdownMenuItem<String>>? getUserGroupDropdownMenuItems(int ownerId) {
    userGroupDropdownMenuItems = _userGroupNames
        .map((groupNameItem) => DropdownMenuItem(
              enabled: _userGroupNames
                  .where((element) => _userGroupNames.contains(element))
                  .toList()
                  .contains(groupNameItem),
              value: groupNameItem,
              child: Text(
                groupNameItem,
              ),
            ))
        .toList();

    return userGroupDropdownMenuItems;
  }

  @override
  getAllGroups() {
    // TODO: implement getGroupsForUser
    throw UnimplementedError();
  }

  @override
  Future<void> addGroupToUserGroups(UserGroup userGroup) async {
    await _database.userGroupDao.insertUserGroup(userGroup);
    //notifyListeners();
  }

  @override
  Future<void> removeGroupFromUserGroups(int id, int userId) async {
    await _database.userGroupDao.deleteUserGroupbyUserId(userId, id);
    //notifyListeners();
  }

  @override
  Future<void> addGroup(Group groupObject) async {
    // TODO: implement addGroup
  }

  @override
  void clearCurrentlyLinkedTasks() {
    currentlyLinkedTasks.clear();
  }

  @override
  void clearCurrentlyLinkedImages() {
    taskImages.clear();
    _cards.clear();
  }
}
