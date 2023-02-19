// GENERATED CODE - DO NOT MODIFY BY HAND

part of to_do_app.models;

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  TaskDao? _taskDaoInstance;

  TaskLinkDao? _taskLinkDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `task` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `ownerId` INTEGER NOT NULL, `taskTitle` TEXT NOT NULL, `description` TEXT NOT NULL, `status` TEXT NOT NULL, `lastUpdate` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `task_link` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `taskId` INTEGER NOT NULL, `relation` TEXT NOT NULL, `linkedTaskId` INTEGER NOT NULL, `lastUpdate` TEXT NOT NULL, FOREIGN KEY (`linkedTaskId`) REFERENCES `task` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  TaskDao get taskDao {
    return _taskDaoInstance ??= _$TaskDao(database, changeListener);
  }

  @override
  TaskLinkDao get taskLinkDao {
    return _taskLinkDaoInstance ??= _$TaskLinkDao(database, changeListener);
  }
}

class _$TaskDao extends TaskDao {
  _$TaskDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _taskInsertionAdapter = InsertionAdapter(
            database,
            'task',
            (Task item) => <String, Object?>{
                  'id': item.id,
                  'ownerId': item.ownerId,
                  'taskTitle': item.taskTitle,
                  'description': item.description,
                  'status': item.status,
                  'lastUpdate': item.lastUpdate
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Task> _taskInsertionAdapter;

  @override
  Future<List<Task>> getTasksByOwnerId(int ownerId) async {
    return _queryAdapter.queryList('SELECT * FROM task WHERE ownerId = ?1',
        mapper: (Map<String, Object?> row) => Task(
            id: row['id'] as int?,
            ownerId: row['ownerId'] as int,
            taskTitle: row['taskTitle'] as String,
            description: row['description'] as String,
            status: row['status'] as String,
            lastUpdate: row['lastUpdate'] as String),
        arguments: [ownerId]);
  }

  @override
  Future<List<Task>> getAllTasks() async {
    return _queryAdapter.queryList('SELECT * FROM task',
        mapper: (Map<String, Object?> row) => Task(
            id: row['id'] as int?,
            ownerId: row['ownerId'] as int,
            taskTitle: row['taskTitle'] as String,
            description: row['description'] as String,
            status: row['status'] as String,
            lastUpdate: row['lastUpdate'] as String));
  }

  @override
  Future<void> deleteTask(int taskId) async {
    await _queryAdapter
        .queryNoReturn('delete from task where id = ?1', arguments: [taskId]);
  }

  @override
  Future<void> updateTaskWithCurrentTime(
    int taskId,
    String lastUpdateTime,
  ) async {
    await _queryAdapter.queryNoReturn(
        'update task set lastUpdate = ?2 where id = ?1',
        arguments: [taskId, lastUpdateTime]);
  }

  @override
  Future<int?> findLatestTaskIdByOwner(int ownerId) async {
    return _queryAdapter.query(
        'select id from task where id = (select max(id) from task) and ownerId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [ownerId]);
  }

  @override
  Future<Task?> getTaskDetailsbyTaskId(int taskId) async {
    return _queryAdapter.query('SELECT * FROM task WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Task(
            id: row['id'] as int?,
            ownerId: row['ownerId'] as int,
            taskTitle: row['taskTitle'] as String,
            description: row['description'] as String,
            status: row['status'] as String,
            lastUpdate: row['lastUpdate'] as String),
        arguments: [taskId]);
  }

  @override
  Future<List<Task>?> getAvailableTaskLinksByTaskId(int taskId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM task WHERE taskId not in (select linkedTaskId from task_link where taskId = ?1  union select id from task where id = ?1)',
        mapper: (Map<String, Object?> row) => Task(id: row['id'] as int?, ownerId: row['ownerId'] as int, taskTitle: row['taskTitle'] as String, description: row['description'] as String, status: row['status'] as String, lastUpdate: row['lastUpdate'] as String),
        arguments: [taskId]);
  }

  @override
  Future<List<Task>?> getTaskDetailsByTaskId(int taskId) async {
    return _queryAdapter.queryList('SELECT * FROM task WHERE taskId = ?1)',
        mapper: (Map<String, Object?> row) => Task(
            id: row['id'] as int?,
            ownerId: row['ownerId'] as int,
            taskTitle: row['taskTitle'] as String,
            description: row['description'] as String,
            status: row['status'] as String,
            lastUpdate: row['lastUpdate'] as String),
        arguments: [taskId]);
  }

  @override
  Future<void> updateTaskStatusAndTime(
    int taskId,
    String status,
    String lastUpdate,
  ) async {
    await _queryAdapter.queryNoReturn(
        'update task set status= ?2, lastUpdate = ?3 WHERE id = ?1',
        arguments: [taskId, status, lastUpdate]);
  }

  @override
  Future<void> insertTask(Task task) async {
    await _taskInsertionAdapter.insert(task, OnConflictStrategy.abort);
  }
}

class _$TaskLinkDao extends TaskLinkDao {
  _$TaskLinkDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _taskLinkInsertionAdapter = InsertionAdapter(
            database,
            'task_link',
            (TaskLink item) => <String, Object?>{
                  'id': item.id,
                  'taskId': item.taskId,
                  'relation': item.relation,
                  'linkedTaskId': item.linkedTaskId,
                  'lastUpdate': item.lastUpdate
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TaskLink> _taskLinkInsertionAdapter;

  @override
  Future<void> deleteLinkedTasksForDeletedTask(int taskId) async {
    await _queryAdapter.queryNoReturn(
        'delete from task_link where linkedTaskId = ?1',
        arguments: [taskId]);
  }

  @override
  Future<void> deleteLinkedTask(
    int linkedTaskId,
    int taskId,
  ) async {
    await _queryAdapter.queryNoReturn(
        'delete from task_link where linkedTaskId = ?1 and taskId = ?2',
        arguments: [linkedTaskId, taskId]);
  }

  @override
  Future<List<TaskLink?>> getExistingTaskLinksByTaskId(int taskId) async {
    return _queryAdapter.queryList('SELECT * FROM task_link WHERE taskId = ?1',
        mapper: (Map<String, Object?> row) => TaskLink(
            id: row['id'] as int?,
            taskId: row['taskId'] as int,
            relation: row['relation'] as String,
            linkedTaskId: row['linkedTaskId'] as int,
            lastUpdate: row['lastUpdate'] as String),
        arguments: [taskId]);
  }

  @override
  Future<void> insertTaskLink(TaskLink tasklink) async {
    await _taskLinkInsertionAdapter.insert(tasklink, OnConflictStrategy.abort);
  }
}
