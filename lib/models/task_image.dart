import 'package:floor/floor.dart';
import 'package:to_do_app/models/task.dart';

@Entity(tableName: 'task_image', foreignKeys: [
  ForeignKey(childColumns: ['taskId'], parentColumns: ['id'], entity: Task),
])
class TaskImage {
  @PrimaryKey(autoGenerate: true)
  int? id;
  int taskId;
  int ownerId;
  String imagePath;
  String uploadDate;

  TaskImage({
    this.id,
    required this.taskId,
    required this.ownerId,
    required this.imagePath,
    required this.uploadDate,
  });
}
