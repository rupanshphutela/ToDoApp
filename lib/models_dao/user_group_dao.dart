import 'package:floor/floor.dart';
import 'package:to_do_app/models/user_group.dart';

@dao
abstract class UserGroupDao {
  @Query("SELECT * FROM user_group WHERE userId = :userId")
  Future<List<UserGroup>> getUserGroupsByUserId(int userId);

  @insert
  Future<void> insertUserGroup(UserGroup userGroup);

  @Query("delete from user_group where id = :userGroupId")
  Future<void> deleteUserGroupbyUserGroupId(int userGroupId);

  @Query(
      "delete from user_group where userId = :userId and groupId = :userGroupId")
  Future<void> deleteUserGroupbyUserId(int userId, int userGroupId);
}
