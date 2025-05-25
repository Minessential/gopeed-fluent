import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/modules/task/controllers/task_downloading_controller.dart';
import 'package:gopeed/app/views/buid_task_list_view.dart';
import 'package:gopeed/app/views/fluent/base_pane_body.dart';

import '../../../routes/app_pages.dart';

class TaskView extends GetView<TaskDownloadingController> {
  const TaskView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePaneBody(
      title: 'task'.tr,
      titleActions: [
        Tooltip(
          message: 'create'.tr,
          child: IconButton(
            icon: const Icon(FluentIcons.add_24_regular, size: 24.0),
            onPressed: () => Get.rootDelegate.toNamed(Routes.CREATE),
          ),
        ),
      ],
      body: BuildTaskListView(tasks: controller.tasks, status: TaskListStatus.downloading),
    );
  }
}


