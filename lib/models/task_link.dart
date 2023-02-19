import 'package:floor/floor.dart';
import 'package:to_do_app/models/task.dart';

@Entity(tableName: 'task_link', foreignKeys: [
  ForeignKey(
      childColumns: ['linkedTaskId'], parentColumns: ['id'], entity: Task),
])
class TaskLink {
  @PrimaryKey(autoGenerate: true)
  int? id;
  int taskId;
  String relation;
  int linkedTaskId;
  String lastUpdate;

  TaskLink({
    this.id,
    required this.taskId,
    required this.relation,
    required this.linkedTaskId,
    required this.lastUpdate,
  });
}
