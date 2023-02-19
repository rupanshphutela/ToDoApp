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
}
