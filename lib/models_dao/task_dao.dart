import 'package:floor/floor.dart';
import 'package:to_do_app/models/task.dart';

@dao
abstract class TaskDao {
  @Query("SELECT * FROM task WHERE ownerId = :ownerId")
  Future<List<Task>> getTasksByOwnerId(int ownerId);

  @Query("SELECT * FROM task ")
  Future<List<Task>?> getAllTasks();

  @Query("delete from task where id = :taskId")
  Future<void> deleteTask(int taskId);

  @Query("update task set lastUpdate = :lastUpdateTime where id = :taskId")
  Future<void> updateTaskWithCurrentTime(int taskId, String lastUpdateTime);

  @Query(
      "select id from task where id = (select max(id) from task) and ownerId = :ownerId")
  Future<int?> findLatestTaskIdByOwner(int ownerId);

  @Query("SELECT * FROM task WHERE id = :taskId ")
  Future<Task?> getTaskDetailsbyTaskId(int taskId);

  @Query(
      "SELECT * FROM task WHERE taskId not in (select linkedTaskId from task_link where taskId = :taskId "
      " union select id from task where id = :taskId)")
  Future<List<Task>?> getAvailableTaskLinksByTaskId(int taskId);

  @insert
  Future<void> insertTask(Task task);

  @Query(
      "update task set status= :status, lastUpdate = :lastUpdate WHERE id = :taskId")
  Future<void> updateTaskStatusAndTime(
      int taskId, String status, String lastUpdate);
}
