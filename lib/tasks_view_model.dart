import 'package:flutter/material.dart';
import 'package:to_do_app/task.dart';

class Tasks with ChangeNotifier {
  //All about tasks
  final List<Task> _tasks = [];
  List<Task> _filteredList = [];
  int _thisTaskIndex = 0;

  List<Task> get tasks => _tasks.toList();

  Task getTaskDetails(String taskId) {
    return _tasks.singleWhere((element) => element.taskId == taskId);
  }

  List<Task> filteredTasks() {
    _filteredList = _tasks.toList();
    return _filteredList.toList();
  }

  getLatestTask() => _tasks[_thisTaskIndex];

  addTask(Task task) {
    _tasks.insert(0, task);
    _thisTaskIndex = _tasks.indexOf(task);
    notifyListeners();
  }

  applyFilter(String filter) {
    if (filter != 'all') {
      return _tasks.where((x) => x.status.contains(filter)).toList();
    } else {
      return _tasks.toList();
    }
  }

  updateSelectedTask(String selectedTaskId, String selectedStatus,
      Map<String, String> currentlyLinkedTasks) {
    _thisTaskIndex =
        _tasks.indexWhere((element) => element.taskId == selectedTaskId);
    _tasks[_thisTaskIndex].status = selectedStatus;
    _tasks[_thisTaskIndex].lastUpdate = DateTime.now();
    _tasks[_thisTaskIndex].relationship = currentlyLinkedTasks;
    _tasks.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    notifyListeners();
  }

  deleteTask(String taskId) {
    for (var element in _tasks) {
      element.relationship.removeWhere((key, value) => key == taskId);
    }
    _tasks.removeWhere((element) => element.taskId == taskId);
    notifyListeners();
  }

  bool visibility = false;

  toggleAddTaskLinkForm() {
    visibility = !visibility;
    notifyListeners();
  }

  //Dropdown Menu Task Ids to link tasks
  List<String> allTaskIdDropdownMenuItems = [];
  List<DropdownMenuItem<String>> taskIdDropdownMenuItems = [];

  List<DropdownMenuItem<String>> getTaskIdDropdownMenuItems(taskId) {
    allTaskIdDropdownMenuItems = _tasks.map((e) => e.taskId).toList();
    allTaskIdDropdownMenuItems.remove(taskId);
    taskIdDropdownMenuItems = allTaskIdDropdownMenuItems
        .map((taskIdMenuItem) => DropdownMenuItem(
            value: taskIdMenuItem, child: Text(taskIdMenuItem)))
        .toList();
    return taskIdDropdownMenuItems;
  }

  deleteTaskIdFromTaskIdDropdown(String taskId) {
    taskIdDropdownMenuItems
        .removeWhere((element) => taskId == element.toString());
    notifyListeners();
  }

  //Linked Tasks to show linked tasks
  Map<String, String> linkedTasks = {};
  Map<String, String> currentlyLinkedTasks = {};

  Map<String, String> getCurrentlyLinkedTasks(String taskId) {
    Map<String, String> task =
        _tasks.singleWhere((element) => element.taskId == taskId).relationship;
    return task;
  }

  addLinkedTask(bool isNewTask, String taskId, String key, String value) {
    if (!isNewTask) {
      Task task = _tasks.singleWhere((element) => element.taskId == taskId);
      int index = _tasks.indexOf(task);
      _tasks[index].relationship[key] = value;
      _tasks[index].lastUpdate = DateTime.now();
      _tasks.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    } else {
      linkedTasks[key] = value;
    }
    notifyListeners();
  }

  removeLinkedTask(bool isNewTask, String key, String taskId) {
    if (!isNewTask) {
      Task task = _tasks.singleWhere((element) => element.taskId == taskId);
      int index = _tasks.indexOf(task);
      _tasks[index].relationship.remove(key);
      _tasks[index].lastUpdate = DateTime.now();
      _tasks.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    } else {
      linkedTasks.remove(key);
    }
    notifyListeners();
  }

  clearLinkedTasks() {
    linkedTasks.clear();
    currentlyLinkedTasks.clear();
    notifyListeners();
  }
}
