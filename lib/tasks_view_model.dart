import 'package:flutter/material.dart';
import 'package:to_do_app/task.dart';

class Tasks with ChangeNotifier {
  //All about tasks
  final List<Task> _tasks = [];
  List<Task> _filteredList = [];
  int _latestTaskIndex = 0;

  List<Task> get tasks => _tasks.toList();

  Task getTaskDetails(String taskId) {
    return _tasks.singleWhere((element) => element.taskId == taskId);
  }

  List<Task> filteredTasks() {
    _filteredList = _tasks.toList();
    return _filteredList.toList();
  } //initially

  getLatestTask() => _tasks[_latestTaskIndex];

  addTask(Task task) {
    _tasks.insert(0, task);
    _latestTaskIndex = _tasks.indexOf(task);

    // debugPrint(task.taskId +
    //     " " +
    //     task.description +
    //     " " +
    //     task.taskTitle +
    //     " " +
    //     task.status +
    //     " " +
    //     task.relationship.toString());
    notifyListeners();
  }

  applyFilter(String filter) {
    if (filter != 'all') {
      return _tasks.where((x) => x.status.contains(filter)).toList();
    } else {
      return _tasks.toList();
    }
  }

  updateSelectedTask(String selectedTaskId, String selectedStatus) {
    _latestTaskIndex =
        _tasks.indexWhere((element) => element.taskId == selectedTaskId);
    _tasks[_latestTaskIndex].status = selectedStatus;
    _tasks[_latestTaskIndex].lastUpdate = DateTime.now();
    _tasks.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    notifyListeners();
  }

  deleteTask(int index) {
    _tasks.removeAt(index);
  }

  bool visibility = false;

  toggleAddTaskLinkForm() {
    visibility = !visibility;
    notifyListeners();
  }

  //Dropdown Menu Task Ids to link tasks
  List<DropdownMenuItem<String>> taskIdDropdownMenuItems = [];

  List<DropdownMenuItem<String>> getTaskIdDropdownMenuItems() {
    taskIdDropdownMenuItems = _tasks
        .map((e) => e.taskId)
        .toList()
        .map((taskIdMenuItem) => DropdownMenuItem(
            value: taskIdMenuItem, child: Text(taskIdMenuItem)))
        .toList();
    return taskIdDropdownMenuItems;
  }

  deleteTaskIdFromTaskIdDropdown(String taskId) {
    taskIdDropdownMenuItems
        .removeWhere((element) => taskId == element.value.toString());
    notifyListeners();
  }

  //Linked Tasks to show linked tasks
  Map<String, String> linkedTasks = {};

  addLinkedTask(String key, String value) {
    linkedTasks[key] = value;
    notifyListeners();
  }

  removeLinkedTask(String taskId) {
    linkedTasks.remove(taskId);
    notifyListeners();
  }

  clearLinkedTasks() {
    linkedTasks.clear();
    notifyListeners();
  }
}
