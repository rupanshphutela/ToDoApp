import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floor/floor.dart';

@Entity(tableName: 'task')
class Task {
  @PrimaryKey(autoGenerate: true)
  int? id;
  int ownerId;
  String taskTitle;
  String description;
  String status;
  String lastUpdate;
  String type;
  String? group;
  List<dynamic>? taskLinks;
  List<dynamic>? taskImages;

  Task({
    this.id,
    required this.ownerId,
    required this.taskTitle,
    required this.description,
    required this.status,
    required this.lastUpdate,
    required this.type,
    this.group,
    this.taskLinks,
    this.taskImages,
  });

  toJson(Task task) {
    return {
      "id": task.id,
      "ownerId": task.ownerId,
      "taskTitle": task.taskTitle,
      "description": task.description,
      "status": task.status,
      "lastUpdate": task.lastUpdate,
      "type": task.type,
      "group": task.group,
      "taskLinks": task.taskLinks,
      "taskImages": task.taskImages,
    };
  }

  static Task fromJson(QueryDocumentSnapshot data) {
    return Task(
      id: data['id'],
      taskTitle: data['taskTitle'],
      description: data['description'],
      status: data['status'],
      ownerId: data['ownerId'],
      lastUpdate: data['lastUpdate'],
      type: data['type'],
      group: data['group'],
      taskLinks: data['taskLinks'],
      taskImages: data['taskImages'],
    );
  }
}
