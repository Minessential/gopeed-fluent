import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/modules/task/controllers/task_downloaded_controller.dart';
import 'package:gopeed/app/views/buid_task_list_view.dart';
import 'package:gopeed/app/views/fluent/base_pane_body.dart';

class TaskDoneView extends GetView<TaskDownloadedController> {
  const TaskDoneView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePaneBody(
      title: 'taskDone'.tr,
      body: BuildTaskListView(tasks: controller.tasks, status: TaskListStatus.downloaded),
    );
  }
}
