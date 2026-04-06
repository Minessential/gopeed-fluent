import 'dart:io';

import 'package:badges/badges.dart' as badges;
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/views/fluent/universal_list_item.dart';
import 'package:gopeed/app/views/responsive_builder.dart';
import 'package:gopeed/theme/theme.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../../../../api/api.dart';
import '../../../../database/database.dart';
import '../../../../util/util.dart';
import '../controllers/extension_controller.dart';

class ExtensionCard extends StatelessWidget {
  ExtensionCard({
    super.key,
    required this.item,
    required this.busy,
    required this.canUpdate,
    this.onTap,
    this.onToggle,
    this.onOpenSetting,
    this.onUpdate,
    this.onDelete,
    this.onInstall,
  });

  final ExtensionListItem item;
  final bool busy;
  final bool canUpdate;
  final VoidCallback? onTap;
  final Future<void> Function(bool value)? onToggle;
  final VoidCallback? onOpenSetting;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;
  final VoidCallback? onInstall;

  final menuController = FlyoutController();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final subTitleStyle = theme.typography.caption;

    final installed = item.installed;
    final store = item.store;
    final installedFlag = item.isInstalled;

    return UniversalListItem(
      onPressed: onTap,
      backgroundColor: getCardBackgroundColor(FluentTheme.of(context)),
      leading: Padding(padding: const EdgeInsets.fromLTRB(0, 16, 12, 16), child: _buildCardIcon(item)),
      title: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 12, 16),
        child: Column(
          spacing: 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: item.title, style: theme.typography.body),
                  WidgetSpan(child: buildChip(item.author)),
                  WidgetSpan(child: buildChip('v${item.version}')),
                ],
              ),
            ),
            ResponsiveBuilder.isNarrow(context)
                ? Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: subTitleStyle)
                : Text(item.description, style: subTitleStyle),
            if (store != null)
              Row(
                spacing: 12,
                children: [
                  _metricItem(context, FluentIcons.star_20_regular, item.stars.toString()),
                  _metricItem(context, FluentIcons.arrow_download_20_regular, item.installCount.toString()),
                ],
              ),
          ],
        ),
      ),
      trailing: Row(
        spacing: 12.0,
        children: [
          if (installed != null)
            ToggleSwitch(
              checked: !installed.disabled,
              leadingContent: true,
              content: Text(installed.disabled ? 'disable'.tr : 'enable'.tr),
              onChanged: busy || onToggle == null ? null : (value) async => await onToggle!(value),
            ),
          if (!installedFlag && store != null)
            Tooltip(
              message: 'extensionInstall'.tr,
              child: IconButton(
                onPressed: busy ? null : onInstall,
                icon: busy
                    ? const SizedBox(width: 14, height: 14, child: ProgressRing(strokeWidth: 2))
                    : const Icon(FluentIcons.arrow_download_24_regular, size: 24.0),
              ),
            ),
          Builder(
            builder: (context) {
              final moreIconButton = IconButton(
                icon: const Icon(FluentIcons.more_horizontal_24_regular, size: 24.0),
                onPressed: () {
                  menuController.showFlyout(
                    autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.bottomCenter),
                    barrierDismissible: true,
                    dismissOnPointerMoveAway: false,
                    dismissWithEsc: true,
                    navigatorKey: Get.key.currentState,
                    builder: (ctx) {
                      return MenuFlyout(
                        items: [
                          MenuFlyoutItem(
                            leading: badges.Badge(
                              showBadge: installed != null && canUpdate,
                              badgeStyle: const badges.BadgeStyle(padding: EdgeInsets.all(4.0)),
                              position: badges.BadgePosition.topEnd(),
                              child: const Icon(FluentIcons.arrow_sync_16_regular, size: 16.0),
                            ),
                            text: Text('newVersionUpdate'.tr),
                            onPressed: busy || onUpdate == null
                                ? null
                                : () {
                                    if (ctx.mounted) Flyout.of(ctx).close();
                                    onUpdate?.call();
                                  },
                          ),
                          const MenuFlyoutSeparator(),
                          if ((item.homepage ?? '').isNotEmpty)
                            MenuFlyoutItem(
                              leading: const Icon(FluentIcons.home_16_regular, size: 16.0),
                              text: Text('homepage'.tr),
                              onPressed: () => launchUrl(Uri.parse(item.homepage!)),
                            ),
                          if ((item.repoUrl ?? '').isNotEmpty)
                            MenuFlyoutItem(
                              leading: const Icon(FluentIcons.code_16_regular, size: 16.0),
                              text: Text('repository'.tr),
                              onPressed: () => launchUrl(Uri.parse(item.repoUrl!)),
                            ),
                          if (((item.homepage ?? '').isNotEmpty || (item.repoUrl ?? '').isNotEmpty) &&
                              ((installed != null && installed.settings?.isNotEmpty == true) || installed != null))
                            const MenuFlyoutSeparator(),
                          if (installed != null && installed.settings?.isNotEmpty == true)
                            MenuFlyoutItem(
                              leading: const Icon(FluentIcons.settings_16_regular, size: 16.0),
                              text: Text('setting'.tr),
                              onPressed: busy
                                  ? null
                                  : () {
                                      if (ctx.mounted) Flyout.of(ctx).close();
                                      onOpenSetting?.call();
                                    },
                            ),
                          if (installed != null)
                            MenuFlyoutItem(
                              leading: const Icon(FluentIcons.delete_16_regular, size: 16.0),
                              text: Text('delete'.tr),
                              onPressed: busy
                                  ? null
                                  : () {
                                      if (ctx.mounted) Flyout.of(ctx).close();
                                      onDelete?.call();
                                    },
                            ),
                        ],
                      );
                    },
                  );
                },
              );

              return FlyoutTarget(
                controller: menuController,
                child: installed != null && canUpdate
                    ? badges.Badge(position: badges.BadgePosition.topEnd(top: 1, end: 1), child: moreIconButton)
                    : moreIconButton,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardIcon(ExtensionListItem item) {
    final storeIcon = item.icon;
    if (storeIcon != null && storeIcon.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          storeIcon,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset('assets/extension/default_icon.png', width: 48, height: 48),
        ),
      );
    }

    final extension = item.installed;
    if (extension == null) {
      return Image.asset('assets/extension/default_icon.png', width: 48, height: 48);
    }

    final image = extension.icon.isEmpty
        ? Image.asset('assets/extension/default_icon.png', width: 48, height: 48)
        : Util.isWeb()
        ? Image.network(
            join('/fs/extensions/${extension.identity}/${extension.icon}'),
            width: 48,
            height: 48,
            headers: {'Authorization': 'Bearer ${Database.instance.getWebToken()}'},
            errorBuilder: (_, __, ___) => Image.asset('assets/extension/default_icon.png', width: 48, height: 48),
          )
        : Image.file(
            extension.devMode
                ? File(path.join(extension.devPath, extension.icon))
                : File(path.join(Util.getStorageDir(), 'extensions', extension.identity, extension.icon)),
            width: 48,
            height: 48,
            errorBuilder: (_, __, ___) => Image.asset('assets/extension/default_icon.png', width: 48, height: 48),
          );

    return ClipRRect(borderRadius: BorderRadius.circular(8), child: image);
  }

  Widget buildChip(String text, {bool dev = false}) {
    return Builder(
      builder: (context) {
        final theme = FluentTheme.of(context);
        final textColor = dev ? theme.accentColor : null;
        final bgColor = dev ? theme.accentColor.withValues(alpha: 0.2) : theme.resources.subtleFillColorSecondary;
        return Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: bgColor),
          child: Text(text, style: TextStyle(fontSize: 12, color: textColor)),
        );
      },
    );
  }

  Widget _metricItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(icon, size: 12, color: FluentTheme.of(context).accentColor),
        Text(text, style: FluentTheme.of(context).typography.caption),
      ],
    );
  }
}
