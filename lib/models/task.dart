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

  Task({
    this.id,
    required this.ownerId,
    required this.taskTitle,
    required this.description,
    required this.status,
    required this.lastUpdate,
  });

  static Task fromJson(QueryDocumentSnapshot data) {
    return Task(
      id: data['id'],
      taskTitle: data['taskTitle'],
      description: data['description'],
      status: data['status'],
      ownerId: data['ownerId'],
      lastUpdate: data['lastUpdate'],
    );
  }
}
