library to_do_app.models;

import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/models/task_image.dart';
import 'package:to_do_app/models/user_group.dart';
import 'package:to_do_app/models_dao/task_dao.dart';
import 'package:to_do_app/models/task_link.dart';
import 'package:to_do_app/models_dao/task_image_dao.dart';
import 'package:to_do_app/models_dao/task_link_dao.dart';
import 'package:to_do_app/models_dao/user_group_dao.dart';

part 'app_database.g.dart'; // the generated code will be here

@Database(version: 1, entities: [Task, TaskLink, TaskImage, UserGroup])
abstract class AppDatabase extends FloorDatabase {
  TaskDao get taskDao;
  TaskLinkDao get taskLinkDao;
  TaskImageDao get taskImageDao;
  UserGroupDao get userGroupDao;
}
