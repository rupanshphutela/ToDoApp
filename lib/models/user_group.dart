import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floor/floor.dart';

@Entity(tableName: 'user_group')
class UserGroup {
  @PrimaryKey(autoGenerate: true)
  int? id;
  int userId;
  int groupId;
  String groupName;

  UserGroup({
    this.id,
    required this.userId,
    required this.groupId,
    required this.groupName,
  });
}
