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

  toJson(TaskImage taskImage) {
    return {
      "id": taskImage.id,
      "taskId": taskImage.taskId,
      "ownerId": taskImage.ownerId,
      "imagePath": taskImage.imagePath,
      "uploadDate": taskImage.uploadDate,
    };
  }

  static TaskImage fromJsonMap(Map data) {
    return TaskImage(
      id: data['id'],
      taskId: data['taskId'],
      ownerId: data['ownerId'],
      imagePath: data['imagePath'],
      uploadDate: data['uploadDate'],
    );
  }
}
