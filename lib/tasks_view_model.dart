import 'package:flutter/material.dart';
import 'package:to_do_app/task.dart';
import 'package:to_do_app/task_list.dart';

class Tasks with ChangeNotifier {
  final List<Task> _tasks = [];
  List<Task> _filteredList = [];

  int _latestTaskIndex = 0;

  List<Task> get tasks => _tasks.toList();
  List<Task> filteredTasks() {
    _filteredList = _tasks.toList();
    return _filteredList.toList();
  } //initially

  getLatestTask() => _tasks[_latestTaskIndex];

  addTask(Task task) {
    _tasks.insert(0, task);
    _latestTaskIndex = _tasks.indexOf(task);
    notifyListeners();
  }

  applyFilter(String filter) {
    if (filter != 'all') {
      return _tasks.where((x) => x.status.contains(filter)).toList();
      // notifyListeners();
      // return _filteredList;
    } else {
      return _tasks;
    }
  }

  updateSelectedTask(int selectedTaskIndex, String selectedStatus) {
    _latestTaskIndex = selectedTaskIndex;
    _tasks[selectedTaskIndex].status = selectedStatus;
    _tasks[selectedTaskIndex].lastUpdate = DateTime.now();
    _tasks.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    notifyListeners();
  }

  deleteTask(int index) {
    _tasks.removeAt(index);
  }
}
