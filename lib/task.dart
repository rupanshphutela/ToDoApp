class Task {
  int taskId;
  String taskTitle;
  String description;
  String status;
  DateTime lastUpdate;

  // This constructor has one positional parameter, which it stores
  // in the member variable named "prompt".
  Task(
      {required this.taskId,
      required this.taskTitle,
      required this.description,
      required this.status,
      required this.lastUpdate});
}