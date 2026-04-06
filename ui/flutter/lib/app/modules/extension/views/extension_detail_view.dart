import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/views/fluent/base_dialog_page.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../../../../api/model/extension.dart';
import '../../../../api/model/store_extension.dart';
import '../../../../util/message.dart';
import '../../../../util/util.dart';
import '../controllers/extension_controller.dart';

class ExtensionDetailDrawer extends GetView<ExtensionController> {
  const ExtensionDetailDrawer({super.key, required this.extension, this.installed});

  final StoreExtension extension;
  final Extension? installed;

  @override
  Widget build(BuildContext context) {
    return BaseDialogPage(
      title: extension.title,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final localInstalled = installed ?? controller.findInstalled(extension);
                final canUpdate = controller.canUpdateFromStore(extension);
                final busy =
                    controller.busyExtensionIds.contains(extension.id) ||
                    (localInstalled != null && controller.busyExtensionIds.contains(localInstalled.identity));

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIcon(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${extension.author} • v${extension.version}'),
                              const SizedBox(height: 6),
                              Text(extension.description, style: FluentTheme.of(context).typography.bodyStrong),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (localInstalled == null)
                          FilledButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    try {
                                      await controller.installFromStore(extension);
                                      if (context.mounted) showMessage(context, 'tip'.tr, 'extensionInstallSuccess'.tr);
                                    } catch (e) {
                                      if (context.mounted) showErrorMessage(context, e);
                                    }
                                  },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                busy
                                    ? const SizedBox(width: 14, height: 14, child: ProgressRing(strokeWidth: 2))
                                    : const Icon(FluentIcons.arrow_download_16_regular),
                                Text('extensionInstall'.tr),
                              ],
                            ),
                          ),
                        if (localInstalled != null && canUpdate)
                          FilledButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    try {
                                      await controller.upgradeExtension(localInstalled);
                                      if (context.mounted) showMessage(context, 'tip'.tr, 'extensionUpdateSuccess'.tr);
                                    } catch (e) {
                                      if (context.mounted) showErrorMessage(context, e);
                                    }
                                  },

                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                busy
                                    ? const SizedBox(width: 14, height: 14, child: ProgressRing(strokeWidth: 2))
                                    : const Icon(FluentIcons.cloud_arrow_down_16_regular),
                                Text('newVersionUpdate'.tr),
                              ],
                            ),
                          ),
                        if ((extension.homepage ?? '').isNotEmpty)
                          Button(
                            onPressed: () => launchUrl(Uri.parse(extension.homepage!)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [const Icon(FluentIcons.home_16_regular, size: 16.0), Text('homepage'.tr)],
                            ),
                          ),
                        Button(
                          onPressed: () => launchUrl(Uri.parse(extension.repoUrl)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 8,
                            children: [Icon(FluentIcons.code_16_regular, size: 16.0), Text('GitHub')],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildReadme(context, localInstalled),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadme(BuildContext context, Extension? installed) {
    return FutureBuilder<_ReadmeInfo>(
      future: _loadReadme(installed),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final markdown = info?.content ?? extension.readme ?? '';
        if (markdown.trim().isEmpty) {
          return Text('No README', style: FluentTheme.of(context).typography.bodyStrong);
        }

        return MarkdownBody(
          data: markdown,
          selectable: true,
          onTapLink: (text, href, title) {
            if (href == null || href.isEmpty) return;
            final resolved = _resolvePath(href, info, forImage: false);
            if (resolved == null) return;
            launchUrl(Uri.parse(resolved), mode: LaunchMode.externalApplication);
          },
          imageBuilder: (uri, title, alt) {
            final resolved = _resolvePath(uri.toString(), info, forImage: true);
            if (resolved == null) return const SizedBox.shrink();
            if (resolved.startsWith('file://')) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.file(
                  File(Uri.parse(resolved).toFilePath()),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.network(
                resolved,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }

  Future<_ReadmeInfo> _loadReadme(Extension? installed) async {
    if (installed == null) {
      return _ReadmeInfo(content: extension.readme ?? '', mode: _ReadmeMode.remote, localReadmePath: null);
    }

    final rootDir = installed.devMode
        ? installed.devPath
        : path.join(Util.getStorageDir(), 'extensions', installed.identity);
    final candidates = [
      path.join(rootDir, 'README.md'),
      path.join(rootDir, 'readme.md'),
      path.join(rootDir, 'README.MD'),
    ];
    for (final filePath in candidates) {
      final file = File(filePath);
      if (await file.exists()) {
        return _ReadmeInfo(content: await file.readAsString(), mode: _ReadmeMode.local, localReadmePath: filePath);
      }
    }

    return _ReadmeInfo(content: extension.readme ?? '', mode: _ReadmeMode.remote, localReadmePath: null);
  }

  String? _resolvePath(String raw, _ReadmeInfo? info, {required bool forImage}) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return uri.toString();
    }

    if (info?.mode == _ReadmeMode.local && info?.localReadmePath != null && forImage) {
      final readmeDir = path.dirname(info!.localReadmePath!);
      final clean = value.split('#').first;
      final absolute = path.normalize(path.join(readmeDir, clean));
      return Uri.file(absolute).toString();
    }

    final ref = extension.commitSha?.isNotEmpty == true ? extension.commitSha! : 'HEAD';
    final dir = (extension.directory ?? '').trim();
    final baseSegments = [if (dir.isNotEmpty) ...dir.split('/').where((e) => e.isNotEmpty), ''];

    final base = forImage
        ? Uri.https('raw.githubusercontent.com', '/${extension.repoFullName}/$ref/${baseSegments.join('/')}')
        : Uri.https('github.com', '/${extension.repoFullName}/blob/$ref/${baseSegments.join('/')}');
    return base.resolve(value).toString();
  }

  Widget _buildIcon() {
    if ((extension.icon ?? '').isEmpty) {
      return Image.asset('assets/extension/default_icon.png', width: 56, height: 56);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        extension.icon!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset('assets/extension/default_icon.png', width: 56, height: 56);
        },
      ),
    );
  }
}

enum _ReadmeMode { remote, local }

class _ReadmeInfo {
  final String content;
  final _ReadmeMode mode;
  final String? localReadmePath;

  _ReadmeInfo({required this.content, required this.mode, required this.localReadmePath});
}
