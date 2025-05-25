import 'package:get/get.dart';

import '../controllers/task_downloaded_controller.dart';

class TaskDoneBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskDownloadedController>(
      () => TaskDownloadedController(),
    );
  }
}
