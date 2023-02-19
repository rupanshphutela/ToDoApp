import 'package:floor/floor.dart';
import 'package:to_do_app/models/task_link.dart';

@dao
abstract class TaskLinkDao {
  @Query("delete from task_link where linkedTaskId = :taskId")
  Future<void> deleteLinkedTasksForDeletedTask(int taskId);

  @Query(
      "delete from task_link where linkedTaskId = :linkedTaskId and taskId = :taskId")
  Future<void> deleteLinkedTask(int linkedTaskId, int taskId);

  @Query("SELECT * FROM task_link WHERE taskId = :taskId ")
  Future<List<TaskLink?>> getExistingTaskLinksByTaskId(int taskId);

  @insert
  Future<void> insertTaskLink(TaskLink tasklink);
}
