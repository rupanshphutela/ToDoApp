import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:floor/floor.dart';

class Group {
  int id;
  String groupName;
  int creatorId;

  Group({
    required this.id,
    required this.groupName,
    required this.creatorId,
  });

  toJson(Group group) {
    return {
      "id": group.id,
      "groupName": group.groupName,
      "creatorId": group.creatorId,
    };
  }

  static Group fromJson(QueryDocumentSnapshot data) {
    return Group(
      id: data['id'],
      groupName: data['groupName'],
      creatorId: data['creatorId'],
    );
  }
}
