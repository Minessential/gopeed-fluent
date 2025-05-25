import 'package:get/get.dart';

import '../controllers/task_downloading_controller.dart';

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskDownloadingController>(
      () => TaskDownloadingController(),
    );
  }
}
