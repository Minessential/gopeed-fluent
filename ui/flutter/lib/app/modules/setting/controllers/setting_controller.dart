import 'package:get/get.dart';

import '../../../../util/updater.dart';

class SettingController extends GetxController {
  final advance = false.obs;
  final latestVersion = Rxn<VersionInfo>();

  @override
  void onInit() {
    super.onInit();
    fetchLatestVersion();
  }

  void toggleAdvance(bool value) => advance.value = value;

  // fetch latest version
  void fetchLatestVersion() async {
    latestVersion.value = await checkUpdate();
  }
}
