import 'dart:async';
import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import 'log_util.dart';
import 'package_info.dart';

const modRespository = 'https://github.com/Minessential/gopeed-fluent';

class VersionInfo {
  final String version;
  final String changeLog;

  VersionInfo(this.version, this.changeLog);
}

Future<VersionInfo?> checkUpdate() async {
  String? releaseDataStr;
  try {
    releaseDataStr = (await proxyRequest(
      "https://api.github.com/repos/Minessential/gopeed-fluent/releases/latest",
    )).data;
  } catch (e) {
    logger.e("Failed to fetch latest release data", e);
    return null;
  }
  if (releaseDataStr == null) {
    return null;
  }
  final releaseData = jsonDecode(releaseDataStr);
  final tagName = releaseData["tag_name"];
  if (tagName == null) {
    return null;
  }
  final latestVersion = releaseData["tag_name"].substring(1);

  // compare version x.y.z to x.y.z
  final currentVersion = packageInfo.version;
  var isNewVersion = false;
  if (latestVersion != currentVersion) {
    final currentVersionList = currentVersion.split(".");
    final latestVersionList = latestVersion.split(".");
    for (var i = 0; i < currentVersionList.length; i++) {
      if (int.parse(latestVersionList[i]) > int.parse(currentVersionList[i])) {
        isNewVersion = true;
        break;
      }
    }
  }

  if (!isNewVersion) {
    return null;
  }

  return VersionInfo(latestVersion, releaseData["body"]);
}

Future<void> showUpdateDialog(BuildContext context, VersionInfo versionInfo) async {
  final fullChangeLog = versionInfo.changeLog;
  final isZh = Get.locale?.languageCode == "zh";
  final changeLogRegex = isZh
      ? RegExp(r"(#\s+更新日志.*)", multiLine: true, dotAll: true)
      : RegExp(r"(# Release notes.*)#\s+更新日志", multiLine: true, dotAll: true);
  final changeLog = changeLogRegex.firstMatch(fullChangeLog)?.group(1) ?? "";
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return ContentDialog(
        title: Text('newVersionTitle'.trParams({'version': versionInfo.version})),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
                child: Builder(
                  builder: (context) {
                    final controller = ScrollController();
                    return Scrollbar(
                      controller: controller,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: controller,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _parseMarkdown(changeLog, context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              launchUrl(Uri.parse('$modRespository/releases'), mode: LaunchMode.externalApplication);
              Get.back();
            },
            child: Text('newVersionUpdate'.tr),
          ),
          Button(onPressed: () => Get.back(), child: Text('newVersionLater'.tr)),
        ],
      );
    },
  );
}

List<Widget> _parseMarkdown(String markdown, BuildContext context) {
  final List<Widget> widgets = [];
  final lines = markdown.split('\n');

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    if (line.startsWith('# ')) {
      // H1 header
      widgets.add(Text(line.substring(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
    } else if (line.startsWith('## ')) {
      // H2 header
      widgets.add(Text(line.substring(3), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
    } else if (line.trim().startsWith('- ')) {
      // List item
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  line
                      .substring(line.indexOf('-') + 1)
                      .trim()
                      .replaceFirst(RegExp(r'@[^\s]*\s\(#\d+\)'), ''), // Remove contributor and pr number
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Normal text
      widgets.add(Text(line, style: const TextStyle(fontSize: 14)));
    }

    // Add spacing between elements
    widgets.add(const SizedBox(height: 8));
  }

  return widgets;
}
