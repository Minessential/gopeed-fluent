import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:gopeed/api/model/request.dart';

import '../../app/controllers/app_controller.dart';

class CreateController extends GetxController with GetSingleTickerProviderStateMixin {
  final RxList fileInfos = [].obs;
  final RxList openedFolders = [].obs;
  final selectedIndexes = <int>[].obs;
  final isConfirming = false.obs;
  final showAdvanced = false.obs;
  final directDownload = false.obs;
  final proxyConfig = Rx<RequestProxy?>(null);
  final advancedTabIndex = 0.obs;
  final oldUrl = "".obs;
  final fileDataUri = "".obs;

  @override
  void onInit() {
    super.onInit();
    directDownload.value = Get.find<AppController>().downloaderConfig.value.extra.defaultDirectDownload;
  }

  void updateAdvancedTabIndex(int index){
    advancedTabIndex.value = index;
  }

  void setFileDataUri(Uint8List bytes) {
    fileDataUri.value = "data:application/x-bittorrent;base64,${base64.encode(bytes)}";
  }

  void clearFileDataUri() {
    fileDataUri.value = "";
  }
}
