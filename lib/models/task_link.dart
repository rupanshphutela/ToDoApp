import 'package:cloud_firestore/cloud_firestore.dart';
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

  toJson(TaskLink tasklink) {
    return {
      "id": tasklink.id,
      "taskId": tasklink.taskId,
      "relation": tasklink.relation,
      "linkedTaskId": tasklink.linkedTaskId,
      "lastUpdate": tasklink.lastUpdate,
    };
  }

  static TaskLink fromJson(QueryDocumentSnapshot data) {
    return TaskLink(
      id: data['id'],
      taskId: data['taskId'],
      relation: data['relation'],
      linkedTaskId: data['linkedTaskId'],
      lastUpdate: data['lastUpdate'],
    );
  }
}
