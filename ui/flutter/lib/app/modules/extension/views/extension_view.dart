import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:gopeed/api/model/store_extension.dart';
import 'package:gopeed/app/modules/extension/views/extension_card.dart';
import 'package:gopeed/app/modules/extension/views/extension_detail_view.dart' show ExtensionDetailDrawer;
import 'package:gopeed/app/views/filled_button_loading.dart';
import 'package:gopeed/app/views/fluent/base_pane_body.dart';
import 'package:gopeed/app/views/fluent/universal_pane_child.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../api/api.dart';
import '../../../../api/model/extension.dart';
import '../../../../api/model/install_extension.dart';
import '../../../../api/model/update_extension_settings.dart';
import '../../../../util/message.dart';
import '../../../../util/util.dart';
import '../../../views/icon_button_loading.dart';
import '../controllers/extension_controller.dart';

class ExtensionView extends GetView<ExtensionController> {
  ExtensionView({Key? key}) : super(key: key);

  final _installUrlController = TextEditingController();
  final _searchController = TextEditingController();
  final _installBtnController = IconButtonLoadingController();

  Future<void> _doInstall(BuildContext context) async {
    final url = _installUrlController.text.trim();
    if (url.isEmpty) {
      controller.tryOpenDevMode();
      return;
    }
    if (controller.busyExtensionIds.contains(ExtensionController.manualInstallBusyKey)) {
      return;
    }
    _installBtnController.start();
    try {
      await controller.installFromUrl(url);
      if (context.mounted) showMessage(context, 'tip'.tr, 'extensionInstallSuccess'.tr);
    } catch (e) {
      if (context.mounted) showErrorMessage(context, e);
    } finally {
      _installBtnController.stop();
    }
  }

  Future<void> _installFromFolder(BuildContext context) async {
    if (controller.busyExtensionIds.contains(ExtensionController.manualInstallBusyKey)) {
      return;
    }
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    try {
      await controller.installFromUrl(dir, devInstall: true);
      if (context.mounted) showMessage(context, 'tip'.tr, 'extensionInstallSuccess'.tr);
    } catch (e) {
      if (context.mounted) showErrorMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.rootDelegate.arguments();
    if (args is InstallExtension && !controller.pendingInstallHandled) {
      controller.pendingInstallHandled = true;
      _installUrlController.text = args.url;
      WidgetsBinding.instance.addPostFrameCallback((_) => _doInstall(context));
    }

    return BasePaneBody(
      title: 'extensions'.tr,
      titleActions: [
        Tooltip(
          message: 'extensionManualInstall'.tr,
          child: IconButton(
            icon: const Icon(FluentIcons.wrench_settings_24_regular, size: 24.0),
            onPressed: controller.toggleInstallTools,
          ),
        ),
        const SizedBox(width: 16),
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
            icon: const Icon(FluentIcons.chat_help_24_regular, size: 24.0),
            onPressed: () => launchUrl(Uri.parse('https://gopeed.com/docs/dev-extension')),
          ),
        ),
      ],
      body: Obx(
        () => Column(
          children: [
            const SizedBox(height: 16),
            UniversalPaneChild(child: _buildMarketToolbar(context)),
            if (controller.showInstallTools.value) ...[
              const SizedBox(height: 16),
              UniversalPaneChild(
                child: Row(
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
                        onPressed: () => _doInstall(context),
                        icon: const Icon(FluentIcons.arrow_download_20_regular, size: 20.0),
                      ),
                    ),
                    if (controller.devMode.value && Util.isDesktop())
                      Tooltip(
                        message: 'extensionLoadLocal'.tr,
                        child: IconButton(
                          icon: const Icon(FluentIcons.folder_add_20_regular, size: 20.0),
                          onPressed: () => _installFromFolder(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Obx(() => UniversalPaneChild(child: _buildFilterBar(context))),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  UniversalPaneChild(child: _buildUnifiedGrid(context)),
                  if (controller.listFilter.value == ExtensionListFilter.market &&
                      controller.storePagination.value?.hasNext == true) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: Button(
                        onPressed: controller.loadingMoreStore.value ? null : controller.loadMoreStore,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            controller.loadingMoreStore.value
                                ? const SizedBox(width: 14, height: 14, child: ProgressRing(strokeWidth: 2))
                                : const Icon(FluentIcons.chevron_circle_down_16_regular, size: 14.0),
                            Text('extensionLoadMore'.tr),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (controller.listFilter.value == ExtensionListFilter.market &&
                      controller.storePagination.value != null &&
                      controller.storeExtensions.isNotEmpty &&
                      controller.storePagination.value!.hasNext == false) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'extensionNoMore'.tr,
                        style: FluentTheme.of(context).typography.caption?.copyWith(color: Get.theme.hintColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketToolbar(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: TextBox(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: controller.searchStore,
            placeholder: '搜索扩展...',
          ),
        ),
        _buildSortTabs(context),
        Tooltip(
          message: 'search'.tr,
          child: IconButton(
            onPressed: () => controller.searchStore(_searchController.text),
            icon: const Icon(FluentIcons.search_24_regular, size: 24.0),
          ),
        ),
        Tooltip(
          message: 'update'.tr,
          child: IconButton(
            onPressed: controller.refreshStore,
            icon: const Icon(FluentIcons.arrow_clockwise_24_regular, size: 24.0),
          ),
        ),
      ],
    );
  }

  Widget _buildSortTabs(BuildContext context) {
    return ComboBox<StoreExtensionSort>(
      value: controller.storeSort.value,
      items: StoreExtensionSort.values.map((e) {
        return ComboBoxItem(
          value: e,
          child: Text(switch (e) {
            StoreExtensionSort.stars => 'extensionSortStars'.tr,
            StoreExtensionSort.installs => 'extensionSortInstalls'.tr,
            StoreExtensionSort.updated => 'extensionSortUpdated'.tr,
          }),
        );
      }).toList(),
      onChanged: (sort) {
        if (sort != null) controller.changeSort(sort);
      },
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final theme = FluentTheme.of(context);
    Widget option(ExtensionListFilter filter, String text) {
      final selected = controller.listFilter.value == filter;
      return HoverButton(
        onPressed: () => controller.changeFilter(filter),
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(minWidth: 75),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: BoxBorder.all(color: selected ? theme.accentColor : theme.resources.dividerStrokeColorDefault),
              color: () {
                if (selected) return null;
                final color = theme.resources.cardBackgroundFillColorDefault;
                if (state.contains(WidgetState.hovered)) {
                  return color.withValues(alpha: 0.1);
                }
                if (state.contains(WidgetState.pressed)) {
                  return color.withValues(alpha: 0.2);
                }
                return null;
              }(),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: selected ? theme.accentColor : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        },
      );
    }

    final left = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 8,
      children: [
        option(ExtensionListFilter.market, 'extensionFilterMarket'.tr),
        const SizedBox(width: 8),
        option(ExtensionListFilter.installed, 'extensionFilterInstalled'.tr),
      ],
    );

    return left;
  }

  Widget _buildUnifiedGrid(BuildContext context) {
    final items = controller.displayItems;
    final loading = controller.loadingInstalled.value || controller.loadingStore.value;
    if (loading && items.isEmpty) {
      return const Center(child: ProgressRing());
    }
    if (items.isEmpty) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('extensionStoreEmpty'.tr));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      shrinkWrap: true,
      itemBuilder: (context, index) => _buildUnifiedCard(context, items[index]),
    );
  }

  Widget _buildUnifiedCard(BuildContext context, ExtensionListItem item) {
    final installed = item.installed;
    final store = item.store;
    final canUpdate = controller.canUpdateItem(item);
    final busy = controller.busyExtensionIds.contains(item.id);

    return ExtensionCard(
      item: item,
      busy: busy,
      canUpdate: canUpdate,
      onTap: store != null ? () => _showExtensionDrawer(item) : null,
      onToggle: installed == null
          ? null
          : (value) async {
              try {
                await controller.toggleExtension(installed, value);
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
              }
            },
      onOpenSetting: installed != null && installed.settings?.isNotEmpty == true
          ? () => _showSettingDialog(context, installed)
          : null,
      onUpdate: installed != null && canUpdate
          ? () async {
              try {
                await controller.upgradeExtension(installed);
                if (context.mounted) showMessage(context, 'tip'.tr, 'extensionUpdateSuccess'.tr);
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
              }
            }
          : null,
      onDelete: installed != null ? () => _showDeleteDialog(context, installed) : null,
      onInstall: !item.isInstalled && store != null
          ? () async {
              try {
                await controller.installFromStore(store);
                if (context.mounted) showMessage(context, 'tip'.tr, 'extensionInstallSuccess'.tr);
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
              }
            }
          : null,
    );
  }

  Future<void> _showExtensionDrawer(ExtensionListItem item) async {
    final store = item.store;
    if (store == null) return;
    await showDialog(
      context: Get.context!,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: const Color(0x8A000000),
      transitionDuration: const Duration(milliseconds: 180),
      builder: (BuildContext context) {
        return ExtensionDetailDrawer(extension: store, installed: item.installed);
      },
    );
  }

  Future<void> _showSettingDialog(BuildContext context, Extension extension) async {
    final formKey = GlobalKey<FormBuilderState>();
    final confrimController = FilledButtonLoadingController();

    return showDialog<void>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (dialogContext) => ContentDialog(
        title: Text('setting'.tr),
        content: FormBuilder(
          key: formKey,
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
                  await controller.loadInstalled(refreshUpdates: false);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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
          Button(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('cancel'.tr)),
        ],
      ),
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

  Future<void> _showDeleteDialog(BuildContext context, Extension extension) {
    return showDialog<void>(
      context: Get.context!,
      barrierDismissible: false,
      builder: (dialogContext) => ContentDialog(
        title: Text('extensionDelete'.tr),
        actions: [
          FilledButton(
            child: Text('confirm'.tr),
            onPressed: () async {
              try {
                await controller.removeExtension(extension);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
              }
            },
          ),
          Button(child: Text('cancel'.tr), onPressed: () => Navigator.of(dialogContext).pop()),
        ],
      ),
    );
  }
}
