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

// Placeholder information for download directory
class PathPlaceholder {
  final String placeholder;
  final String description;
  final String example;

  const PathPlaceholder({required this.placeholder, required this.description, required this.example});
}

// Available placeholders for download directory
List<PathPlaceholder> getPathPlaceholders() {
  final now = DateTime.now();
  final year = now.year.toString();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');

  return [
    PathPlaceholder(placeholder: '%year%', description: 'placeholderYear'.tr, example: year),
    PathPlaceholder(placeholder: '%month%', description: 'placeholderMonth'.tr, example: month),
    PathPlaceholder(placeholder: '%day%', description: 'placeholderDay'.tr, example: day),
    PathPlaceholder(placeholder: '%date%', description: 'placeholderDate'.tr, example: '$year-$month-$day'),
  ];
}

// Render placeholders in a path with actual values
String renderPathPlaceholders(String path) {
  if (path.isEmpty) return path;

  final now = DateTime.now();
  final year = now.year.toString();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final date = '$year-$month-$day';

  return path
      .replaceAll('%year%', year)
      .replaceAll('%month%', month)
      .replaceAll('%day%', day)
      .replaceAll('%date%', date);
}

class DirectorySelector extends StatefulWidget {
  final TextEditingController controller;
  final bool showLabel;
  final bool showAndoirdToggle;
  final bool allowEdit;
  final bool showPlaceholderButton;
  final VoidCallback? onEditComplete;

  const DirectorySelector({
    Key? key,
    required this.controller,
    this.showLabel = true,
    this.showAndoirdToggle = false,
    this.allowEdit = false,
    this.showPlaceholderButton = false,
    this.onEditComplete,
  }) : super(key: key);

  @override
  State<DirectorySelector> createState() => _DirectorySelectorState();
}

class _DirectorySelectorState extends State<DirectorySelector> {
  final menuController = FlyoutController();

  @override
  void dispose() {
    menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? buildSelectWidget() {
      if (Util.isDesktop()) {
        return Column(
          children: [
            if (widget.showLabel) const SizedBox(height: 18),
            IconButton(
              icon: const Icon(FluentIcons.folder_open_20_regular, size: 20),
              onPressed: () async {
                var dir = await FilePicker.platform.getDirectoryPath();
                if (dir != null) {
                  widget.controller.text = dir;
                  widget.onEditComplete?.call();
                }
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
            widget.onEditComplete?.call();
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

    Widget? buildPlaceholderButton() {
      if (!widget.showPlaceholderButton) return null;

      void onPlaceholderItemTap(String placeholder) {
        final currentText = widget.controller.text;
        final selection = widget.controller.selection;
        final cursorPosition = selection.baseOffset >= 0 ? selection.baseOffset : currentText.length;

        final newText = currentText.substring(0, cursorPosition) + placeholder + currentText.substring(cursorPosition);
        widget.controller.text = newText;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPosition + placeholder.length),
        );
        widget.onEditComplete?.call();
      }

      return Column(
        children: [
          if (widget.showLabel) const SizedBox(height: 18),
          FlyoutTarget(
            controller: menuController,
            child: Tooltip(
              message: 'insertPlaceholder'.tr,
              child: IconButton(
                icon: const Icon(FluentIcons.code_20_regular, size: 20.0),
                onPressed: () {
                  menuController.showFlyout<String>(
                    navigatorKey: Get.key.currentState,
                    builder: (context) {
                      return MenuFlyout(
                        items: getPathPlaceholders().map((p) {
                          return MenuFlyoutItem(
                            text: Tooltip(
                              message: 'example'.trParams({'value': p.example}),
                              child: Text('${p.placeholder} - ${p.description}'),
                            ),
                            onPressed: () => onPlaceholderItemTap(p.placeholder),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    final textFormBox = ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        return TextFormBox(
          readOnly: widget.allowEdit ? false : (Util.isWeb() ? false : true),
          controller: widget.controller,
          validator: (v) {
            return v!.trim().isNotEmpty ? null : 'downloadDirValid'.tr;
          },
          onEditingComplete: widget.onEditComplete,
          onTapOutside: (event) {
            // Call onEditComplete when user taps outside the field
            widget.onEditComplete?.call();
          },
        );
      },
    );
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: widget.showLabel ? InfoLabel(label: 'downloadDir'.tr, child: textFormBox) : textFormBox,
        ),
        ?buildSelectWidget(),
        ?buildPlaceholderButton(),
      ],
    );
  }
}
