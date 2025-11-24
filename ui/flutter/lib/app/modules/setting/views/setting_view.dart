import 'dart:async';
import 'dart:io';

import 'package:badges/badges.dart' as badges;
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/views/app_logo.dart';
import 'package:gopeed/app/views/copy_button.dart';
import 'package:gopeed/app/views/fluent/base_pane_body.dart';
import 'package:gopeed/app/views/fluent/universal_list_item.dart';
import 'package:gopeed/app/views/icon_label.dart';
import 'package:gopeed/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../api/model/downloader_config.dart';
import '../../../../i18n/message.dart';
import '../../../../util/input_formatter.dart';
import '../../../../util/locale_manager.dart';
import '../../../../util/log_util.dart';
import '../../../../util/message.dart';
import '../../../../util/package_info.dart';
import '../../../../util/scheme_register/scheme_register.dart';
import '../../../../util/updater.dart';
import '../../../../util/util.dart';
import '../../../views/check_list_view.dart';
import '../../../views/outlined_button_loading.dart';
import '../../app/controllers/app_controller.dart';
import '../controllers/setting_controller.dart';

const homePage = 'https://gopeed.com';
const thankPage = 'https://github.com/GopeedLab/gopeed/graphs/contributors';

class SettingView extends GetView<SettingController> {
  const SettingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();
    final downloaderCfg = appController.downloaderConfig;
    final startCfg = appController.startConfig;

    Timer? timer;
    Future<bool> debounceSave({
      Future<String> Function()? check,
      bool needRestart = false,
    }) {
      var completer = Completer<bool>();
      timer?.cancel();
      timer = Timer(const Duration(milliseconds: 1000), () async {
        if (check != null) {
          final checkResult = await check();
          if (checkResult.isNotEmpty && context.mounted) {
            showErrorMessage(context, checkResult);
            completer.complete(false);
            return;
          }
        }
        appController
            .saveConfig()
            .then((_) => completer.complete(true))
            .onError(completer.completeError);
        if (needRestart && context.mounted) {
          showMessage(context, 'tip'.tr, 'effectAfterRestart'.tr);
        }
      });
      return completer.future;
    }

    // download basic config items start
    Widget buildDownloadDir() {
      return _SettingItem(
        icon: FluentIcons.folder_24_regular,
        title: 'downloadDir'.tr,
        trailing: Obx(
          () => _TextIconButton(
            label: downloaderCfg.value.downloadDir.getSuffix,
            tooltip: downloaderCfg.value.downloadDir,
            icon: FluentIcons.edit_20_regular,
            onTap: () async {
              final dir = await FilePicker.platform.getDirectoryPath();
              if (dir != null && dir != downloaderCfg.value.downloadDir) {
                downloaderCfg.update((val) => val!.downloadDir = dir);
                await debounceSave();
              }
            },
          ),
        ),
      );
    }

    final buildMaxRunning = _buildConfigItem(
      FluentIcons.arrow_download_24_regular,
      'maxRunning',
      trailing: Obx(() => Text(downloaderCfg.value.maxRunning.toString())),
      keyBuilder: (Key key) {
        final maxRunningController = TextEditingController(
          text: downloaderCfg.value.maxRunning.toString(),
        );
        maxRunningController.addListener(() async {
          if (maxRunningController.text.isNotEmpty &&
              maxRunningController.text !=
                  downloaderCfg.value.maxRunning.toString()) {
            downloaderCfg.update(
              (val) => val!.maxRunning = int.parse(maxRunningController.text),
            );
            await debounceSave();
          }
        });

        return TextBox(
          key: key,
          focusNode: FocusNode(),
          controller: maxRunningController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            NumericalRangeFormatter(min: 1, max: 256),
          ],
        );
      },
    );

    Widget buildDefaultDirectDownload() {
      return _SettingItem(
        icon: FluentIcons.flash_flow_24_regular,
        title: 'defaultDirectDownload'.tr,
        trailing: Obx(
          () => ToggleSwitch(
            content: Text(
              downloaderCfg.value.extra.defaultDirectDownload
                  ? 'on'.tr
                  : 'off'.tr,
            ),
            leadingContent: true,
            checked: downloaderCfg.value.extra.defaultDirectDownload,
            onChanged: (bool value) async {
              downloaderCfg.update(
                (val) => val!.extra.defaultDirectDownload = value,
              );
              await debounceSave();
            },
          ),
        ),
      );
    }

    Widget buildBrowserExtension() {
      return _SettingExpanderItem(
        icon: FluentIcons.puzzle_piece_24_regular,
        title: 'browserExtension'.tr,
        content: Column(
          children: [
            _buildLinkItem(
              "Chrome",
              "https://chromewebstore.google.com/detail/gopeed/mijpgljlfcapndmchhjffkpckknofcnd",
            ),
            _buildLinkItem(
              "Edge",
              "https://microsoftedge.microsoft.com/addons/detail/dkajnckekendchdleoaenoophcobooce",
            ),
            _buildLinkItem(
              "Firefox",
              "https://addons.mozilla.org/zh-CN/firefox/addon/gopeed-extension",
            ),
          ],
        ),
      );
    }

    // Currently auto startup only support Windows and Linux
    Widget? buildAutoStartup() {
      if (!Util.isWindows() && !Util.isLinux()) return null;
      return _SettingItem(
        icon: FluentIcons.rocket_24_regular,
        title: 'launchAtStartup'.tr,
        trailing: Obx(
          () => ToggleSwitch(
            content: Text(appController.autoStartup.value ? 'on'.tr : 'off'.tr),
            leadingContent: true,
            checked: appController.autoStartup.value,
            onChanged: (bool value) async {
              try {
                if (value) {
                  await launchAtStartup.enable();
                } else {
                  await launchAtStartup.disable();
                }
                appController.autoStartup.value = value;
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
                logger.e('launchAtStartup fail', e);
              }
            },
          ),
        ),
      );
    }

    // http config items start
    final buildHttpUa = _buildConfigItem(
      FluentIcons.globe_desktop_24_regular,
      'User-Agent',
      subWidget: Obx(() => Text(appController.httpConfig.userAgent)),
      keyBuilder: (Key key) {
        final uaController = TextEditingController(
          text: appController.httpConfig.userAgent,
        );
        uaController.addListener(() async {
          if (uaController.text.isNotEmpty &&
              uaController.text != appController.httpConfig.userAgent) {
            downloaderCfg.update(
              (val) => val!.protocolConfig.http.userAgent = uaController.text,
            );
            await debounceSave();
          }
        });

        return TextBox(
          key: key,
          focusNode: FocusNode(),
          controller: uaController,
        );
      },
    );

    final buildHttpConnections = _buildConfigItem(
      FluentIcons.plug_connected_settings_24_regular,
      'connections',
      trailing: Obx(
        () => Text(appController.httpConfig.connections.toString()),
      ),
      keyBuilder: (Key key) {
        final connectionsController = TextEditingController(
          text: appController.httpConfig.connections.toString(),
        );
        connectionsController.addListener(() async {
          if (connectionsController.text.isNotEmpty &&
              connectionsController.text !=
                  appController.httpConfig.connections.toString()) {
            downloaderCfg.update(
              (val) => val!.protocolConfig.http.connections = int.parse(
                connectionsController.text,
              ),
            );
            await debounceSave();
          }
        });

        return TextBox(
          key: key,
          focusNode: FocusNode(),
          controller: connectionsController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            NumericalRangeFormatter(min: 1, max: 256),
          ],
        );
      },
    );

    Widget buildHttpUseServerCtime() {
      return _SettingItem(
        icon: FluentIcons.clock_24_regular,
        title: 'useServerCtime'.tr,
        trailing: Obx(
          () => ToggleSwitch(
            content: Text(
              appController.httpConfig.useServerCtime ? 'on'.tr : 'off'.tr,
            ),
            leadingContent: true,
            checked: appController.httpConfig.useServerCtime,
            onChanged: (bool value) {
              downloaderCfg.update(
                (val) => val!.protocolConfig.http.useServerCtime = value,
              );
              debounceSave();
            },
          ),
        ),
      );
    }

    // bt config items start
    final buildBtListenPort = _buildConfigItem(
      FluentIcons.router_24_regular,
      'port',
      trailing: Obx(() => Text(appController.btConfig.listenPort.toString())),
      keyBuilder: (Key key) {
        final listenPortController = TextEditingController(
          text: appController.btConfig.listenPort.toString(),
        );
        listenPortController.addListener(() async {
          if (listenPortController.text.isNotEmpty &&
              listenPortController.text !=
                  appController.btConfig.listenPort.toString()) {
            downloaderCfg.update(
              (val) => val!.protocolConfig.bt.listenPort = int.parse(
                listenPortController.text,
              ),
            );
            await debounceSave();
          }
        });

        return TextBox(
          key: key,
          focusNode: FocusNode(),
          controller: listenPortController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            NumericalRangeFormatter(min: 0, max: 65535),
          ],
        );
      },
    );

    final buildBtTrackerSubscribeUrls = _buildConfigItem(
      FluentIcons.link_multiple_24_regular,
      'subscribeTracker',
      trailing: Obx(
        () => Text(
          'items'.trParams({
            'count': appController.btExtConfig.trackerSubscribeUrls.length
                .toString(),
          }),
        ),
      ),
      keyBuilder: (Key key) {
        final trackerUpdateController = OutlinedButtonLoadingController();
        return Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: CheckListView(
                items: allTrackerSubscribeUrls,
                checked: appController.btExtConfig.trackerSubscribeUrls,
                onChanged: (value) {
                  downloaderCfg.update(
                    (val) => val!.extra.bt.trackerSubscribeUrls = value,
                  );
                  debounceSave();
                },
              ),
            ),
            Obx(
              () => ToggleSwitch(
                checked: appController.btExtConfig.autoUpdateTrackers,
                onChanged: (bool value) {
                  downloaderCfg.update(
                    (val) => val!.extra.bt.autoUpdateTrackers = value,
                  );
                  debounceSave();
                },
                content: Text('updateDaily'.tr),
              ),
            ),
            Row(
              spacing: 12,
              children: [
                OutlinedButtonLoading(
                  onPressed: () async {
                    trackerUpdateController.start();
                    try {
                      await appController.trackerUpdate();
                    } catch (e) {
                      if (context.mounted)
                        showErrorMessage(context, 'subscribeFail'.tr);
                    } finally {
                      trackerUpdateController.stop();
                    }
                  },
                  controller: trackerUpdateController,
                  child: Text('update'.tr),
                ),
                Expanded(
                  child: Obx(
                    () => Text(
                      'lastUpdate'.trParams({
                        'time':
                            appController.btExtConfig.lastTrackerUpdateTime !=
                                null
                            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
                                appController
                                    .btExtConfig
                                    .lastTrackerUpdateTime!,
                              )
                            : '',
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    final buildBtTrackers = _buildConfigItem(
      FluentIcons.cloud_link_24_regular,
      'addTracker',
      trailing: Obx(
        () => Text(
          'items'.trParams({
            'count': appController.btExtConfig.customTrackers.length.toString(),
          }),
        ),
      ),
      keyBuilder: (Key key) {
        final trackersController = TextEditingController(
          text: appController.btExtConfig.customTrackers
              .join('\r\n')
              .toString(),
        );
        return TextBox(
          key: key,
          focusNode: FocusNode(),
          controller: trackersController,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          placeholder: 'addTrackerHit'.tr,
          onChanged: (value) async {
            downloaderCfg.update(
              (val) => val!.extra.bt.customTrackers = Util.textToLines(value),
            );
            appController.refreshTrackers();
            await debounceSave();
          },
        );
      },
    );

    final buildBtSeedConfig = _buildConfigItem(
      FluentIcons.share_ios_24_regular,
      'seedConfig',
      subWidget: Obx(
        () => Text(
          '${'seedKeep'.tr}(${appController.btConfig.seedKeep ? 'on'.tr : 'off'.tr})',
        ),
      ),
      keyBuilder: (Key key) {
        final seedRatioController = TextEditingController(
          text: appController.btConfig.seedRatio.toString(),
        );
        seedRatioController.addListener(() {
          if (seedRatioController.text.isNotEmpty) {
            downloaderCfg.update(
              (val) => val!.protocolConfig.bt.seedRatio = double.parse(
                seedRatioController.text,
              ),
            );
            debounceSave();
          }
        });
        final seedTimeController = TextEditingController(
          text: (appController.btConfig.seedTime ~/ 60).toString(),
        );
        seedTimeController.addListener(() {
          if (seedTimeController.text.isNotEmpty) {
            downloaderCfg.update(
              (val) => val!.protocolConfig.bt.seedTime =
                  int.parse(seedTimeController.text) * 60,
            );
            debounceSave();
          }
        });
        return Obx(
          () => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('seedKeep'.tr)),
                    ToggleSwitch(
                      leadingContent: true,
                      checked: appController.btConfig.seedKeep,
                      content: Text(
                        appController.btConfig.seedKeep ? 'on'.tr : 'off'.tr,
                      ),
                      onChanged: (bool value) {
                        downloaderCfg.update(
                          (val) => val!.protocolConfig.bt.seedKeep = value,
                        );
                        debounceSave();
                      },
                    ),
                  ],
                ),
                appController.btConfig.seedKeep
                    ? null
                    : InfoLabel(
                        label: 'seedRatio'.tr,
                        child: TextBox(
                          controller: seedRatioController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                        ),
                      ),
                appController.btConfig.seedKeep
                    ? null
                    : InfoLabel(
                        label: 'seedTime'.tr,
                        child: TextBox(
                          controller: seedTimeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            NumericalRangeFormatter(min: 0, max: 100000000),
                          ],
                        ),
                      ),
              ].where((e) => e != null).map((e) => e!).toList(),
            ),
          ),
        );
      },
    );

    Widget? buildBtDefaultClientConfig() {
      if (!Util.isWindows()) return null;
      return _SettingItem(
        icon: FluentIcons.calendar_checkmark_24_regular,
        title: 'setAsDefaultBtClient'.tr,
        trailing: Obx(
          () => ToggleSwitch(
            content: Text(
              downloaderCfg.value.extra.defaultBtClient ? 'on'.tr : 'off'.tr,
            ),
            leadingContent: true,
            checked: downloaderCfg.value.extra.defaultBtClient,
            onChanged: (bool value) async {
              try {
                if (value) {
                  registerDefaultTorrentClient();
                } else {
                  unregisterDefaultTorrentClient();
                }
                downloaderCfg.update(
                  (val) => val!.extra.defaultBtClient = value,
                );
                await debounceSave();
              } catch (e) {
                if (context.mounted) showErrorMessage(context, e);
                logger.e('register default torrent client fail', e);
              }
            },
          ),
        ),
      );
    }

    // ui config items start
    Widget buildTheme() {
      return _SettingItem(
        icon: FluentIcons.paint_brush_24_regular,
        title: 'theme'.tr,
        trailing: Obx(
          () => ComboBox<ThemeMode>(
            isExpanded: true,
            value: ThemeMode.values.byName(downloaderCfg.value.extra.themeMode),
            items: ThemeMode.values.map((e) {
              return ComboBoxItem(
                value: e,
                child: IconLabel(
                  icon: Icon(switch (e) {
                    ThemeMode.light => FluentIcons.weather_sunny_16_regular,
                    ThemeMode.dark => FluentIcons.weather_moon_16_regular,
                    ThemeMode.system => FluentIcons.settings_16_regular,
                  }),
                  label: _getThemeName(e),
                ),
              );
            }).toList(),
            onChanged: (value) async {
              downloaderCfg.update((val) => val?.extra.themeMode = value!.name);
              Get.changeThemeMode(ThemeMode.values.byName(value!.name));
              Get.forceAppUpdate();
              await debounceSave();
            },
          ),
        ),
      );
    }

    Widget buildLocale() {
      return _SettingItem(
        icon: FluentIcons.translate_24_regular,
        title: 'locale'.tr,
        trailing: Obx(
          () => ComboBox<String>(
            isExpanded: true,
            value: downloaderCfg.value.extra.locale,
            items: messages.keys.keys
                .map(
                  (e) => ComboBoxItem(
                    value: e,
                    child: Text(messages.keys[e]!['label']!),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              downloaderCfg.update((val) => val!.extra.locale = value!);
              Get.updateLocale(toLocale(value!));
              await debounceSave();
            },
          ),
        ),
      );
    }

    // about config items start
    Widget buildAbout() {
      return _SettingExpanderItem(
        iconWidget: const AppLogo(size: 24),
        title: 'appName'.tr,
        subTitle: '© ${DateTime.now().year} monkeyWie',
        trailing: Obx(() {
          final hasNewVersion = controller.latestVersion.value != null;
          final widget = Text('${'version'.tr} ${packageInfo.version}');
          return hasNewVersion
              ? badges.Badge(
                  position: badges.BadgePosition.topEnd(top: -3, end: -6),
                  badgeStyle: const badges.BadgeStyle(
                    padding: EdgeInsetsGeometry.all(3.5),
                  ),
                  child: widget,
                )
              : widget;
        }),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SettingItem(
              icon: FluentIcons.megaphone_24_regular,
              title: 'notifyWhenNewVersion'.tr,
              trailing: Obx(
                () => ToggleSwitch(
                  content: Text(
                    downloaderCfg.value.extra.notifyWhenNewVersion
                        ? 'on'.tr
                        : 'off'.tr,
                  ),
                  leadingContent: true,
                  checked: downloaderCfg.value.extra.notifyWhenNewVersion,
                  onChanged: (bool value) async {
                    downloaderCfg.update(
                      (val) => val!.extra.notifyWhenNewVersion = value,
                    );
                    await debounceSave();
                  },
                ),
              ),
            ),
            _SettingItem(
              title: 'appNameMod'.tr,
              subTitle: 'modDesc'.tr,
              trailing: const Icon(FluentIcons.open_16_regular, size: 16.0),
              onPressed: () => launchUrl(
                Uri.parse(modRespository),
                mode: LaunchMode.externalApplication,
              ),
            ),
            Obx(() {
              final hasNewVersion = controller.latestVersion.value != null;
              return hasNewVersion
                  ? _SettingItem(
                      title:
                          '${'appNameMod'.tr} ${'newVersionTitle'.trParams({'version': ''})}',
                      subTitle: controller.latestVersion.value?.version ?? '',
                      trailing: FilledButton(
                        child: Text('view'.tr),
                        onPressed: () => showUpdateDialog(
                          context,
                          controller.latestVersion.value!,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }),
            _SettingItem(
              title: 'homepage'.tr,
              subTitle: homePage,
              trailing: const Icon(FluentIcons.open_16_regular, size: 16.0),
              onPressed: () => launchUrl(
                Uri.parse(homePage),
                mode: LaunchMode.externalApplication,
              ),
            ),
            _SettingItem(
              title: 'thanks'.tr,
              subTitle: 'thanksDesc'.tr,
              trailing: const Icon(FluentIcons.open_16_regular, size: 16.0),
              onPressed: () => launchUrl(
                Uri.parse(thankPage),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(height: 20),
            const AppLogo(),
            Text(
              'appName'.tr,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text('Version: ${packageInfo.version}'),
            Text('© ${DateTime.now().year} monkeyWie'),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    // advanced config proxy items start
    final buildProxy = _buildConfigItem(
      FluentIcons.server_link_24_regular,
      'proxy',
      subWidget: Obx(
        () => Text(switch (downloaderCfg.value.proxy.proxyMode) {
          ProxyModeEnum.noProxy => 'noProxy'.tr,
          ProxyModeEnum.systemProxy => 'systemProxy'.tr,
          ProxyModeEnum.customProxy =>
            '${downloaderCfg.value.proxy.scheme}://${downloaderCfg.value.proxy.host}',
        }),
      ),
      keyBuilder: (Key key) {
        final mode = SizedBox(
          width: 150,
          child: Obx(
            () => ComboBox<ProxyModeEnum>(
              isExpanded: true,
              value: downloaderCfg.value.proxy.proxyMode,
              onChanged: (value) async {
                if (value != null &&
                    value != downloaderCfg.value.proxy.proxyMode) {
                  downloaderCfg.value.proxy.proxyMode = value;
                  downloaderCfg.update(
                    (val) => val!.proxy = downloaderCfg.value.proxy,
                  );
                  await debounceSave();
                }
              },
              items: [
                ComboBoxItem<ProxyModeEnum>(
                  value: ProxyModeEnum.noProxy,
                  child: Text('noProxy'.tr),
                ),
                ComboBoxItem<ProxyModeEnum>(
                  value: ProxyModeEnum.systemProxy,
                  child: Text('systemProxy'.tr),
                ),
                ComboBoxItem<ProxyModeEnum>(
                  value: ProxyModeEnum.customProxy,
                  child: Text('customProxy'.tr),
                ),
              ],
            ),
          ),
        );

        final scheme = SizedBox(
          width: 150,
          child: Obx(
            () => ComboBox<String>(
              isExpanded: true,
              value: downloaderCfg.value.proxy.scheme,
              onChanged: (value) async {
                if (value != null &&
                    value != downloaderCfg.value.proxy.scheme) {
                  downloaderCfg.update((val) => val!.proxy.scheme = value);
                  await debounceSave();
                }
              },
              items: const [
                ComboBoxItem<String>(value: 'http', child: Text('HTTP')),
                ComboBoxItem<String>(value: 'https', child: Text('HTTPS')),
                ComboBoxItem<String>(value: 'socks5', child: Text('SOCKS5')),
              ],
            ),
          ),
        );

        final arr = downloaderCfg.value.proxy.host.split(':');
        var host = '';
        var port = '';
        if (arr.length > 1) {
          host = arr[0];
          port = arr[1];
        }

        final ipController = TextEditingController(text: host);
        final portController = TextEditingController(text: port);

        updateAddress() async {
          final newAddress = '${ipController.text}:${portController.text}';
          if (newAddress != startCfg.value.address) {
            downloaderCfg.update((val) => val!.proxy.host = newAddress);
            await debounceSave();
          }
        }

        ipController.addListener(updateAddress);
        portController.addListener(updateAddress);

        final server = Row(
          spacing: 10,
          children: [
            Flexible(
              child: InfoLabel(
                label: 'server'.tr,
                child: TextBox(controller: ipController),
              ),
            ),
            Flexible(
              child: InfoLabel(
                label: 'port'.tr,
                child: TextBox(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    NumericalRangeFormatter(min: 0, max: 65535),
                  ],
                ),
              ),
            ),
          ],
        );

        final usrController = TextEditingController(text: proxy.usr);
        final pwdController = TextEditingController(text: proxy.pwd);

        updateAuth() async {
          if (usrController.text != proxy.usr ||
              pwdController.text != proxy.pwd) {
            proxy.usr = usrController.text;
            proxy.pwd = pwdController.text;

            await debounceSave();
          }
        }

        usrController.addListener(updateAuth);
        pwdController.addListener(updateAuth);

        final auth = Row(
          spacing: 10,
          children: [
            Flexible(
              child: InfoLabel(
                label: 'username'.tr,
                child: TextBox(controller: usrController),
              ),
            ),
            Flexible(
              child: InfoLabel(
                label: 'password'.tr,
                child: TextBox(controller: pwdController),
              ),
              obscureText: true,
            ),
          ],
        );

        List<Widget> customView() {
          if (downloaderCfg.value.proxy.proxyMode != ProxyModeEnum.customProxy)
            return [];
          return [scheme, server, auth];
        }

        return Obx(
          () => Form(
            child: Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [mode, ...customView()],
            ),
          ),
        );
      },
    );

    // advanced config API items start
    final buildApiProtocol = _buildConfigItem(
      FluentIcons.router_24_regular,
      'protocol',
      subWidget: Obx(
        () => Text(
          startCfg.value.network == 'tcp'
              ? 'TCP ${startCfg.value.address}'
              : 'Unix',
        ),
      ),
      keyBuilder: (Key key) {
        final items = <Widget>[
          Obx(
            () => SizedBox(
              width: 80,
              child: ComboBox<String>(
                isExpanded: true,
                value: startCfg.value.network,
                onChanged: Util.isDesktop() || Util.isAndroid()
                    ? (value) async {
                        startCfg.update((val) => val!.network = value!);
                        await debounceSave(needRestart: true);
                      }
                    : null,
                items: [
                  const ComboBoxItem<String>(value: 'tcp', child: Text('TCP')),
                  Util.supportUnixSocket()
                      ? const ComboBoxItem<String>(
                          value: 'unix',
                          child: Text('Unix'),
                        )
                      : null,
                ].whereType<ComboBoxItem<String>>().toList(),
              ),
            ),
          ),
        ];

        if ((Util.isDesktop() || Util.isAndroid()) &&
            startCfg.value.network == 'tcp') {
          final arr = startCfg.value.address.split(':');
          var ip = '127.0.0.1';
          var port = '0';
          if (arr.length > 1) {
            ip = arr[0];
            port = arr[1];
          }

          final ipController = TextEditingController(text: ip);
          final portController = TextEditingController(text: port);
          updateAddress() async {
            if (ipController.text.isEmpty || portController.text.isEmpty)
              return;

            final newAddress = '${ipController.text}:${portController.text}';
            if (newAddress != startCfg.value.address) {
              startCfg.update((val) => val!.address = newAddress);

              final saved = await debounceSave(
                check: () async {
                  // Check if address already in use
                  final configIp = ipController.text;
                  final configPort = int.parse(portController.text);
                  if (configPort == 0) return '';
                  try {
                    final socket = await Socket.connect(
                      configIp,
                      configPort,
                      timeout: const Duration(seconds: 3),
                    );
                    socket.close();
                    return 'portInUse'.trParams({
                      'port': configPort.toString(),
                    });
                  } catch (e) {
                    return '';
                  }
                },
                needRestart: true,
              );

              if (!saved) {
                final oldAddress =
                    (await appController.loadStartConfig()).address;
                startCfg.update((val) => val!.address = oldAddress);
              }
            }
          }

          ipController.addListener(updateAddress);
          portController.addListener(updateAddress);
          items.addAll([
            const SizedBox(width: 20),
            Flexible(
              child: InfoLabel(
                label: 'IP',
                child: TextBox(
                  controller: ipController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: InfoLabel(
                label: 'port'.tr,
                child: TextBox(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    NumericalRangeFormatter(min: 0, max: 65535),
                  ],
                ),
              ),
            ),
          ]);
        }

        return Form(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: items,
          ),
        );
      },
    );

    final buildApiToken = Util.isDesktop() && startCfg.value.network == 'tcp'
        ? _buildConfigItem(
            FluentIcons.key_24_regular,
            'apiToken',
            trailing: Obx(
              () => Text(
                startCfg.value.apiToken.isEmpty ? 'notSet'.tr : 'set'.tr,
              ),
            ),
            keyBuilder: (Key key) {
              final apiTokenController = TextEditingController(
                text: startCfg.value.apiToken,
              );
              apiTokenController.addListener(() async {
                if (apiTokenController.text != startCfg.value.apiToken) {
                  startCfg.update(
                    (val) => val!.apiToken = apiTokenController.text,
                  );

                  await debounceSave(needRestart: true);
                }
              });
              return TextBox(
                key: key,
                obscureText: true,
                controller: apiTokenController,
                focusNode: FocusNode(),
              );
            },
          )
        : () => null;

    // advanced config log items start
    Widget buildLogsDir() {
      return _SettingItem(
        icon: FluentIcons.document_catch_up_24_regular,
        title: "logDirectory".tr,
        subTitle: logsDir(),
        trailing: Util.isDesktop()
            ? const Icon(FluentIcons.open_folder_20_regular, size: 16.0)
            : CopyButton(logsDir(), size: 16),
        onPressed: () =>
            Util.isDesktop() ? launchUrl(Uri.file(logsDir())) : null,
      );
    }

    return BasePaneBody.scrollable(
      title: 'setting'.tr,
      spacing: 24,
      children: [
        _SettingSection(
          sectionTitle: 'general'.tr,
          children: [
            buildDownloadDir(),
            buildMaxRunning(),
            buildDefaultDirectDownload(),
            buildBrowserExtension(),
            ?buildAutoStartup(),
          ],
        ),
        _SettingSection(
          sectionTitle: 'HTTP',
          children: [
            buildHttpUa(),
            buildHttpConnections(),
            buildHttpUseServerCtime(),
          ],
        ),
        _SettingSection(
          sectionTitle: 'BitTorrent',
          children: [
            buildBtListenPort(),
            buildBtTrackerSubscribeUrls(),
            buildBtTrackers(),
            buildBtSeedConfig(),
            ?buildBtDefaultClientConfig(),
          ],
        ),
        _SettingSection(
          sectionTitle: 'ui'.tr,
          children: [buildTheme(), buildLocale()],
        ),
        _SettingSection(sectionTitle: 'network'.tr, children: [buildProxy()]),
        _SettingSection(
          sectionTitle: 'API',
          children: [buildApiProtocol(), ?buildApiToken()],
        ),
        _SettingSection(
          sectionTitle: 'developer'.tr,
          children: [buildLogsDir()],
        ),
        _SettingSection(sectionTitle: 'about'.tr, children: [buildAbout()]),
      ],
    );
  }

  Widget _buildLinkItem(String title, String url) {
    return _SettingSubItem(
      title: title,
      onPressed: () {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      trailing: const Icon(FluentIcons.open_24_regular, size: 16.0),
    );
  }

  void _tapInputWidget(GlobalKey key, bool status) {
    if (key.currentContext == null) {
      return;
    }

    if (key.currentContext?.widget is TextBox) {
      final textField = key.currentContext?.widget as TextBox;
      if (status) {
        textField.focusNode?.requestFocus();
      } else {
        textField.focusNode?.unfocus();
      }
      return;
    }

    /* GestureDetector? detector;
    void searchForGestureDetector(BuildContext? element) {
      element?.visitChildElements((element) {
        if (element.widget is GestureDetector) {
          detector = element.widget as GestureDetector?;
        } else {
          searchForGestureDetector(element);
        }
      });
    }

    searchForGestureDetector(key.currentContext);
    detector?.onTap?.call(); */
  }

  Widget Function() _buildConfigItem(
    IconData icon,
    String label, {
    Widget? subWidget,
    Widget? trailing,
    required Widget Function(Key key) keyBuilder,
  }) {
    final inputKey = GlobalKey();
    return () => _SettingExpanderItem(
      icon: icon,
      title: label.tr,
      subWidget: subWidget,
      trailing: trailing,
      onStateChanged: (value) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _tapInputWidget(inputKey, value);
        });
      },
      content: Container(
        padding: const EdgeInsets.all(8),
        child: keyBuilder(inputKey),
      ),
    );
  }

  String _getThemeName(ThemeMode? themeMode) {
    switch (themeMode ?? ThemeMode.system.name) {
      case ThemeMode.light:
        return 'themeLight'.tr;
      case ThemeMode.dark:
        return 'themeDark'.tr;
      default:
        return 'themeSystem'.tr;
    }
  }
}

///SettingSection
class _SettingSection extends StatelessWidget {
  const _SettingSection({required this.sectionTitle, required this.children});

  final String sectionTitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return InfoLabel(
      label: sectionTitle,
      labelStyle: theme.typography.bodyStrong,
      child: Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

///SettingItem
class _SettingItem extends StatelessWidget {
  const _SettingItem({
    this.icon,
    required this.title,
    this.subTitle,
    required this.trailing,
    this.onPressed,
  });

  final IconData? icon;
  final String title;
  final String? subTitle;
  final Widget trailing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return UniversalListItem(
      onPressed: onPressed,
      leading: Padding(
        padding: const EdgeInsets.only(right: 6.0),
        child: icon != null
            ? Icon(icon, size: 24.0)
            : const SizedBox(width: 24.0),
      ),
      title: subTitle == null
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(title),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    subTitle!,
                    style: FluentTheme.of(context).typography.caption,
                  ),
                ],
              ),
            ),
      backgroundColor: getCardBackgroundColor(FluentTheme.of(context)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: trailing,
      ),
    );
  }
}

///SettingExpanderItem
class _SettingExpanderItem extends StatelessWidget {
  const _SettingExpanderItem({
    this.icon,
    this.iconWidget,
    required this.title,
    this.subTitle,
    this.subWidget,
    this.trailing,
    required this.content,
    this.onStateChanged,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? subTitle;
  final Widget? subWidget;
  final Widget? trailing;
  final Widget content;
  final ValueChanged<bool>? onStateChanged;

  @override
  Widget build(BuildContext context) {
    return Expander(
      leading: icon == null && iconWidget == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: iconWidget ?? Icon(icon, size: 24.0),
              ),
            ),
      header: subTitle == null && subWidget == null
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(title),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  DefaultTextStyle(
                    style:
                        FluentTheme.of(context).typography.caption ??
                        const TextStyle(),
                    child: subWidget ?? Text(subTitle!),
                  ),
                ],
              ),
            ),
      trailing: trailing != null
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: trailing,
            )
          : null,
      contentPadding: EdgeInsets.zero,
      onStateChanged: onStateChanged,
      content: content,
    );
  }
}

/// Used for items within expandable setting sections
class _SettingSubItem extends StatelessWidget {
  const _SettingSubItem({
    required this.title,
    required this.trailing,
    this.onPressed,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return UniversalListItem(
      onPressed: onPressed,
      leading: const SizedBox(width: 30),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(title),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.resources.cardStrokeColorDefault),
        borderRadius: BorderRadius.circular(2.0),
      ),
      backgroundColor: getCardBackgroundColor(theme),
      trailing: trailing != null
          ? Padding(padding: const EdgeInsets.only(right: 24), child: trailing)
          : null,
    );
  }
}

class _TextIconButton extends StatelessWidget {
  final String label;
  final String? tooltip;
  final IconData icon;
  final void Function() onTap;

  const _TextIconButton({
    required this.label,
    this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Tooltip(
      message: tooltip,
      child: HyperlinkButton(
        style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
        onPressed: onTap,
        child: Card(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Card(
                  backgroundColor: theme.accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: theme.brightness == Brightness.light
                          ? Colors.white
                          : const Color(0xE4000000),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                icon,
                color: theme.typography.body?.color,
                size: theme.typography.body?.fontSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  String get getSuffix {
    final index = lastIndexOf(RegExp(r'[\\/]+'));
    if (index == -1 || index == length - 1) return this;
    return substring(index + 1);
  }
}

enum ProxyModeEnum { noProxy, systemProxy, customProxy }

extension ProxyMode on ProxyConfig {
  ProxyModeEnum get proxyMode {
    if (!enable) {
      return ProxyModeEnum.noProxy;
    }
    if (system) {
      return ProxyModeEnum.systemProxy;
    }
    return ProxyModeEnum.customProxy;
  }

  set proxyMode(ProxyModeEnum value) {
    switch (value) {
      case ProxyModeEnum.noProxy:
        enable = false;
        break;
      case ProxyModeEnum.systemProxy:
        enable = true;
        system = true;
        break;
      case ProxyModeEnum.customProxy:
        enable = true;
        system = false;
        break;
    }
  }
}
