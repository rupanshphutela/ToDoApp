import 'package:go_router/go_router.dart';
import 'package:to_do_app/task_details.dart';
import 'package:to_do_app/task_form.dart';
import 'package:to_do_app/task_list.dart';
import 'package:to_do_app/utils/qr_code_scanner.dart';

final routes = [
  GoRoute(
    path: '/tasks',
    builder: (context, state) =>
        TaskList(title: 'Tasks', state: state.queryParams['state'].toString()),
  ),
  GoRoute(
    path: '/task',
    builder: (context, state) => TaskForm(title: 'Task Form'),
    // builder: (context, state) {
    //   final title = state.params['id1']!;
    //   final int taskId = int.parse(state.params['id2']!);
    //   return TaskDetails(selectedTaskIndex: taskId, title: title);
    // },
  ),
  GoRoute(
      path: '/taskdetail',
      builder: (context, state) {
        final int taskId = int.parse(state.queryParams['task_id'].toString());
        return TaskDetails(selectedTaskId: taskId, title: 'Task Details');
      }),
  GoRoute(
      path: '/qr_scanner',
      builder: (context, state) {
        return const QRScannerWidget();
      })
];
