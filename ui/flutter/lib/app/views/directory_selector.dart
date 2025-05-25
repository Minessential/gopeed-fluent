import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons, ToggleSwitch;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../util/message.dart';
import '../../util/util.dart';

final deviceInfo = DeviceInfoPlugin();

class DirectorySelector extends StatefulWidget {
  final TextEditingController controller;
  final bool showLabel;
  final bool showAndoirdToggle;

  const DirectorySelector({Key? key, required this.controller, this.showLabel = true, this.showAndoirdToggle = false})
    : super(key: key);

  @override
  State<DirectorySelector> createState() => _DirectorySelectorState();
}

class _DirectorySelectorState extends State<DirectorySelector> {
  @override
  Widget build(BuildContext context) {
    Widget? buildSelectWidget() {
      if (Util.isDesktop()) {
        return Column(
          children: [
            const SizedBox(height: 18),
            IconButton(
              icon: const Icon(FluentIcons.folder_open_20_regular, size: 20),
              onPressed: () async {
                var dir = await FilePicker.platform.getDirectoryPath();
                if (dir != null) widget.controller.text = dir;
              },
            ),
          ],
        );
      }
      // After Android 11, access to external storage is increasingly restricted, so it no longer supports selecting the download directory. However, if you do not download in external storage, all downloaded files will be deleted after the application is uninstalled.
      // Fortunately, so far, most Android devices can still access the system download directory.
      // For the sake of user experience, it is decided to only support selecting the application's internal directory and the system download directory. Also, a test for file write permission is performed when selecting the system download directory. If it cannot be written, selection is not allowed.
      if (Util.isAndroid() && widget.showAndoirdToggle) {
        final isSwitchToDownloadDir = widget.controller.text.endsWith('/Gopeed');

        return ToggleSwitch(
          initialLabelIndex: isSwitchToDownloadDir ? 1 : 0,
          totalSwitches: 2,
          icons: const [FluentIcons.home_20_regular, FluentIcons.arrow_download_20_regular],
          customWidths: const [50, 50],
          onToggle: (index) async {
            if (index == 0) {
              widget.controller.text =
                  (await getExternalStorageDirectory())?.path ?? (await getApplicationDocumentsDirectory()).path;
            } else {
              widget.controller.text = '${(await DownloadsPath.downloadsDirectory())!.path}/Gopeed';
            }
          },
          cancelToggle: (index) async {
            if (index == 0) {
              return false;
            }

            final downloadDir = (await DownloadsPath.downloadsDirectory())?.path;
            if (downloadDir == null) {
              return true;
            }

            // Check and request external storage permission when sdk version < 30 (android 11)
            if ((await deviceInfo.androidInfo).version.sdkInt < 30) {
              var status = await Permission.storage.status;
              if (!status.isGranted) {
                status = await Permission.storage.request();
                if (!status.isGranted) {
                  if (context.mounted) showErrorMessage(context, 'noStoragePermission'.tr);
                  return true;
                }
              }
            }

            // Check write permission
            final fileRandomeName = "test_${DateTime.now().millisecondsSinceEpoch}.tmp";
            final testFile = File('$downloadDir/Gopeed/$fileRandomeName');
            try {
              await testFile.create(recursive: true);
              await testFile.writeAsString('test');
              await testFile.delete();
              return false;
            } catch (e) {
              if (context.mounted) showErrorMessage(context, e);
              return true;
            }
          },
        ).marginOnly(left: 10);
      }
      return null;
    }

    final textFormBox = TextFormBox(
      readOnly: Util.isWeb() ? false : true,
      controller: widget.controller,
      validator: (v) {
        return v!.trim().isNotEmpty ? null : 'downloadDirValid'.tr;
      },
    );
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: widget.showLabel ? InfoLabel(label: 'downloadDir'.tr, child: textFormBox) : textFormBox,
        ),
        ?buildSelectWidget(),
      ],
    );
  }
}
