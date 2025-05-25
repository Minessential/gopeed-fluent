import 'package:get/get.dart';
import 'package:gopeed/api/api.dart';
import 'package:gopeed/api/model/task.dart';
import 'package:gopeed/app/modules/task/controllers/task_list_controller.dart';
import 'package:gopeed/util/notifications.dart';

class RootController extends TaskListController {
  RootController() : super([Status.error, Status.done], (a, b) => 1);

  bool init = true;

  @override
  getTasksState() async {
    final tasks = await getTasks(statuses);
    updateTaskState(tasks);
    this.tasks.value = tasks;
    if (init) init = false;
  }

  void updateTaskState(List<Task> newTasks) {
    if (init) return;
    final newTasksSet = newTasks.toSet();
    final tasksSet = tasks.toSet();
    final diff = newTasksSet.difference(tasksSet);
    if (diff.isEmpty) return;

    final doneNames = <String>[];
    final errorNames = <String>[];

    for (var task in diff) {
      if (task.status == Status.done) {
        doneNames.add(task.name);
      } else if (task.status == Status.error) {
        errorNames.add(task.name);
      }
    }
    if (doneNames.isNotEmpty) {
      showNotificationWithActions(
        'notificationDownloaded'.tr,
        '${doneNames.join(', ')} ${'notificationDownloaded'.tr}',
      );
    }
    if (errorNames.isNotEmpty) {
      showNotificationWithActions('notificationError'.tr, '${errorNames.join(', ')} ${'notificationError'.tr}');
    }
  }
}
