import 'package:floor/floor.dart';
import 'package:to_do_app/models/task_image.dart';

@dao
abstract class TaskImageDao {
  @Query("delete from task_image where taskId = :taskId")
  Future<void> deleteLinkedImagesForDeletedTask(int taskId);

  @Query("delete from task_image where id = :taskImageId and taskId = :taskId")
  Future<void> deleteTaskImage(int taskImageId, int taskId);

  @Query("SELECT * FROM task_image WHERE taskId = :taskId ")
  Future<List<TaskImage>> getExistingTaskImagesByTaskId(int taskId);

  @insert
  Future<void> insertTaskImage(TaskImage taskImage);
}
