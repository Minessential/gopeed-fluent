import 'dart:io';

import 'package:badges/badges.dart' as badges;
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/views/filled_button_loading.dart';
import 'package:gopeed/app/views/fluent/base_pane_body.dart';
import 'package:gopeed/app/views/fluent/universal_list_item.dart';
import 'package:gopeed/app/views/fluent/universal_pane_child.dart';
import 'package:gopeed/theme/theme.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import '../../../../api/api.dart';
import '../../../../api/model/extension.dart';
import '../../../../api/model/install_extension.dart';
import '../../../../api/model/switch_extension.dart';
import '../../../../api/model/update_extension_settings.dart';
import '../../../../database/database.dart';
import '../../../../util/message.dart';
import '../../../../util/util.dart';
import '../../../views/icon_button_loading.dart';
import '../../../views/responsive_builder.dart';
import '../controllers/extension_controller.dart';

class ExtensionView extends GetView<ExtensionController> {
  ExtensionView({Key? key}) : super(key: key);

  final _installUrlController = TextEditingController();
  final _installBtnController = IconButtonLoadingController();

  @override
  Widget build(BuildContext context) {
    return BasePaneBody(
      title: 'extensions'.tr,
      titleActions: [
        Tooltip(
          message: 'extensionFind'.tr,
          child: IconButton(
            icon: const Icon(FluentIcons.apps_add_in_24_regular, size: 24.0),
            onPressed: () {
              launchUrl(Uri.parse('https://github.com/search?q=topic%3Agopeed-extension&type=repositories'));
            },
          ),
        ),
        const SizedBox(width: 16),
        Tooltip(
          message: 'extensionDevelop'.tr,
          child: IconButton(
            icon: const Icon(FluentIcons.window_dev_tools_24_regular, size: 24.0),
            onPressed: () => launchUrl(Uri.parse('https://docs.gopeed.com/dev-extension.html')),
          ),
        ),
      ],
      body: Column(
        children: [
          const SizedBox(height: 16),
          UniversalPaneChild(
            child: Obx(
              () => Row(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'extensionInstallUrl'.tr,
                      child: TextBox(placeholder: 'url'.tr, controller: _installUrlController),
                    ),
                  ),
                  Tooltip(
                    message: 'install'.tr,
                    child: IconButtonLoading(
                      controller: _installBtnController,
                      onPressed: () async {
                        if (_installUrlController.text.isEmpty) {
                          controller.tryOpenDevMode();
                          return;
                        }
                        _installBtnController.start();
                        try {
                          await installExtension(InstallExtension(url: _installUrlController.text));
                          if (context.mounted) showMessage(context, 'tip'.tr, 'extensionInstallSuccess'.tr);
                          await controller.load();
                        } catch (e) {
                          if (context.mounted) showErrorMessage(context, e);
                        } finally {
                          _installBtnController.stop();
                        }
                      },
                      icon: const Icon(FluentIcons.arrow_download_20_regular, size: 20.0),
                    ),
                  ),
                  controller.devMode.value && Util.isDesktop()
                      ? Tooltip(
                          message: 'installFromFolder'.tr,
                          child: IconButton(
                            icon: const Icon(FluentIcons.folder_add_20_regular, size: 20.0),
                            onPressed: () async {
                              var dir = await FilePicker.platform.getDirectoryPath();
                              if (dir != null) {
                                try {
                                  await installExtension(InstallExtension(devMode: true, url: dir));
                                  if (context.mounted) showMessage(context, 'tip'.tr, 'extensionInstallSuccess'.tr);
                                  await controller.load();
                                } catch (e) {
                                  if (context.mounted) showErrorMessage(context, e);
                                }
                              }
                            },
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(
              () => ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: controller.extensions.length,
                itemBuilder: (context, index) {
                  final extension = controller.extensions[index];
                  return UniversalPaneChild(child: _ExtensionItem(key: Key('extension-$index'), extension, controller));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///普通扩展项
class _ExtensionItem extends StatelessWidget {
  _ExtensionItem(this.extension, this.controller, {super.key});

  final Extension extension;
  final ExtensionController controller;

  final menuController = FlyoutController();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final subTitleStyle = theme.typography.caption;
    return UniversalListItem(
      backgroundColor: getCardBackgroundColor(FluentTheme.of(context)),
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 12, 16),
        child: SizedBox(
          width: 48.0,
          height: 48.0,
          child: extension.icon.isEmpty
              ? Image.asset("assets/extension/default_icon.png", fit: BoxFit.cover)
              : Util.isWeb()
              ? Image.network(
                  join('/fs/extensions/${extension.identity}/${extension.icon}'),
                  fit: BoxFit.cover,
                  headers: {'Authorization': 'Bearer ${Database.instance.getWebToken()}'},
                )
              : Image.file(
                  extension.devMode
                      ? File(path.join(extension.devPath, extension.icon))
                      : File(path.join(Util.getStorageDir(), "extensions", extension.identity, extension.icon)),
                  fit: BoxFit.cover,
                ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 12, 16),
        child: Column(
          spacing: 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: extension.title, style: theme.typography.body),
                  WidgetSpan(child: buildChip('v${extension.version}')),
                  if (extension.devMode) WidgetSpan(child: buildChip('dev', dev: true)),
                ],
              ),
            ),
            ResponsiveBuilder.isNarrow(context)
                ? Text(extension.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: subTitleStyle)
                : Text(extension.description, style: subTitleStyle),
          ],
        ),
      ),
      trailing: Row(
        spacing: 12.0,
        children: [
          ToggleSwitch(
            checked: !extension.disabled,
            leadingContent: true,
            content: Text(extension.disabled ? 'disable'.tr : 'enable'.tr),
            onChanged: (value) async {
              try {
                await switchExtension(extension.identity, SwitchExtension(status: value));
                await controller.load();
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
              }
            },
          ),
          Obx(() {
            final haveExtUpdate = controller.updateFlags.containsKey(extension.identity);

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
                          leading: haveExtUpdate
                              ? badges.Badge(
                                  position: badges.BadgePosition.topEnd(),
                                  child: const Icon(FluentIcons.arrow_sync_16_regular, size: 16.0),
                                )
                              : const Icon(FluentIcons.arrow_sync_16_regular, size: 16.0),
                          text: Text('update'.tr),
                          onPressed: () {
                            if (haveExtUpdate) {
                              _showUpdateDialog(extension).then((_) {
                                if (ctx.mounted) Flyout.of(ctx).close();
                              });
                            } else {
                              showMessage(context, 'tip'.tr, 'extensionAlreadyLatest'.tr);
                            }
                          },
                        ),
                        const MenuFlyoutSeparator(),
                        if (extension.homepage.isNotEmpty == true)
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.home_16_regular, size: 16.0),
                            text: Text('homepage'.tr),
                            onPressed: () => launchUrl(Uri.parse(extension.homepage)),
                          ),
                        if (extension.repository?.url.isNotEmpty == true)
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.code_16_regular, size: 16.0),
                            text: Text('repository'.tr),
                            onPressed: () => launchUrl(Uri.parse(extension.repository!.url)),
                          ),
                        if (extension.homepage.isNotEmpty == true || extension.repository?.url.isNotEmpty == true)
                          const MenuFlyoutSeparator(),
                        MenuFlyoutItem(
                          leading: const Icon(FluentIcons.delete_16_regular, size: 16.0),
                          text: Text('delete'.tr),
                          onPressed: () {
                            _showDeleteDialog(context, extension).then((_) {
                              if (ctx.mounted) Flyout.of(ctx).close();
                            });
                          },
                        ),
                        if (extension.settings?.isNotEmpty == true)
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.settings_16_regular, size: 16.0),
                            text: Text('setting'.tr),
                            onPressed: () {
                              _showSettingDialog(context, extension).then((_) {
                                if (ctx.mounted) Flyout.of(ctx).close();
                              });
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
              child: haveExtUpdate
                  ? badges.Badge(position: badges.BadgePosition.topEnd(top: 1, end: 1), child: moreIconButton)
                  : moreIconButton,
            );
          }),
        ],
      ),
    );
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

  Widget _buildSettingItem(Setting setting) {
    final requiredValidator = setting.required ? FormBuilderValidators.required() : null;

    final tipWidget = setting.description.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: setting.description,
              child: IconButton(icon: const Icon(FluentIcons.info_24_regular, size: 20), onPressed: () {}),
            ),
          )
        : null;

    Widget buildTextField(
      TextInputFormatter? inputFormatter,
      FormFieldValidator<String>? validator,
      TextInputType? keyBoardType,
    ) {
      final validate = FormBuilderValidators.compose(
        [requiredValidator, validator].where((e) => e != null).map((e) => e!).toList(),
      );
      return InfoLabel(
        label: setting.title,
        child: FormBuilderField<String>(
          name: setting.name,
          validator: validate,
          initialValue: setting.value?.toString(),
          builder: (field) {
            return Row(
              children: [
                Expanded(
                  child: TextFormBox(
                    initialValue: field.value,
                    inputFormatters: inputFormatter != null ? [inputFormatter] : null,
                    keyboardType: keyBoardType,
                    validator: validate,
                    onChanged: (value) => field.didChange(value),
                  ),
                ),
                ?tipWidget,
              ],
            );
          },
        ),
      );
    }

    Widget buildDropdown() {
      final validator = FormBuilderValidators.compose(
        [requiredValidator].where((e) => e != null).map((e) => e!).toList(),
      );
      return InfoLabel(
        label: setting.title,
        child: FormBuilderField<String>(
          name: setting.name,
          validator: validator,
          initialValue: setting.value?.toString(),
          builder: (field) {
            return Row(
              children: [
                Flexible(
                  child: Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    child: FormRow(
                      padding: EdgeInsets.zero,
                      error: field.errorText != null ? Text(field.errorText!) : null,
                      child: ComboBox<String>(
                        value: field.value,
                        items: setting.options!
                            .map((e) => ComboBoxItem(value: e.value.toString(), child: Text(e.label)))
                            .toList(),
                        onChanged: (String? value) => field.didChange(value),
                      ),
                    ),
                  ),
                ),
                ?tipWidget,
              ],
            );
          },
        ),
      );
    }

    Widget buildToggleSwitch() {
      final bool initValue = ((setting.value is bool) ? setting.value as bool : false);
      return FormBuilderField<bool>(
        name: setting.name,
        validator: requiredValidator,
        initialValue: initValue,
        builder: (field) {
          return Row(
            children: [
              Flexible(
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  child: FormRow(
                    padding: EdgeInsets.zero,
                    error: field.errorText != null ? Text(field.errorText!) : null,
                    child: ToggleSwitch(
                      checked: (field.value ?? false),
                      content: Text(setting.title),
                      onChanged: (value) => field.didChange(value),
                    ),
                  ),
                ),
              ),
              ?tipWidget,
            ],
          );
        },
      );
    }

    switch (setting.type) {
      case SettingType.string:
        return setting.options?.isNotEmpty == true ? buildDropdown() : buildTextField(null, null, null);
      case SettingType.number:
        return setting.options?.isNotEmpty == true
            ? buildDropdown()
            : buildTextField(
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                FormBuilderValidators.numeric(),
                const TextInputType.numberWithOptions(decimal: true),
              );
      case SettingType.boolean:
        return buildToggleSwitch();
    }
  }

  Future<void> _showUpdateDialog(Extension extension) {
    final confrimController = FilledButtonLoadingController();
    return showDialog<void>(
      context: Get.context!,
      builder: (context) => ContentDialog(
        content: Text('newVersionTitle'.trParams({'version': 'v${controller.updateFlags[extension.identity]!}'})),
        actions: [
          FilledButtonLoading(
            controller: confrimController,
            onPressed: () async {
              confrimController.start();
              try {
                await updateExtension(extension.identity);
                await controller.load();
                controller.updateFlags.remove(extension.identity);
                Get.back();
                if (context.mounted) showMessage(context, 'tip'.tr, 'extensionUpdateSuccess'.tr);
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
              } finally {
                confrimController.stop();
              }
            },
            child: Text('newVersionUpdate'.tr),
          ),
          Button(onPressed: () => Get.back(), child: Text('newVersionLater'.tr)),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, Extension extension) {
    return showDialog<void>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (_) => ContentDialog(
        title: Text('extensionDelete'.tr),
        actions: [
          FilledButton(
            child: Text('confirm'.tr),
            onPressed: () async {
              try {
                await deleteExtension(extension.identity);
                await controller.load();
                Get.back();
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
              }
            },
          ),
          Button(child: Text('cancel'.tr), onPressed: () => Get.back()),
        ],
      ),
    );
  }

  Future<void> _showSettingDialog(BuildContext context, Extension extension) async {
    final formKey = GlobalKey<FormBuilderState>();
    final confrimController = FilledButtonLoadingController();

    return showDialog<void>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (_) => ContentDialog(
        title: Text('setting'.tr),
        content: FormBuilder(
          key: formKey,
          // autovalidateMode: AutovalidateMode.always,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(spacing: 16, children: extension.settings!.map((e) => _buildSettingItem(e)).toList()),
          ),
        ),

        actions: [
          FilledButtonLoading(
            onPressed: () async {
              try {
                confrimController.start();
                if (formKey.currentState?.saveAndValidate() == true) {
                  await updateExtensionSettings(
                    extension.identity,
                    UpdateExtensionSettings(settings: formKey.currentState!.value),
                  );
                  await controller.load();
                  Get.back();
                }
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
              } finally {
                confrimController.stop();
              }
            },
            controller: confrimController,
            child: Text('confirm'.tr),
          ),
          Button(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        ],
      ),
    );
  }
}
