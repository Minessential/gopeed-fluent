import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:gopeed/util/notifications.dart';
import 'package:window_manager/window_manager.dart';

import 'api/api.dart' as api;
import 'app/modules/app/controllers/app_controller.dart';
import 'app/modules/app/views/app_view.dart';
import 'core/libgopeed_boot.dart';
import 'database/database.dart';
import 'i18n/message.dart';
import 'util/browser_extension_host/browser_extension_host.dart';
import 'util/locale_manager.dart';
import 'util/log_util.dart';
import 'util/package_info.dart';
import 'util/scheme_register/scheme_register.dart';
import 'util/util.dart';

class Args {
  static const flagHidden = "hidden";

  bool hidden = false;

  Args();

  Args.parse(List<String> args) {
    final parser = ArgParser();
    parser.addFlag(flagHidden);
    final results = parser.parse(args);
    hidden = results.flag(flagHidden);
  }
}

void main(List<String> arguments) async {
  Args args;
  // Parse url scheme arguments, e.g. gopeed:?hidden=true
  // TODO: macos open url handle
  // TODO: macos updater test
  if (arguments.firstOrNull?.startsWith("gopeed:") == true) {
    try {
      final uri = Uri.parse(arguments.first);
      args = Args()..hidden = uri.queryParameters["hidden"] == "true";
    } catch (e) {
      // ignore
      args = Args.parse([]);
    }
  } else {
    args = Args.parse(arguments);
  }

  await init(args);
  onStart();

  runApp(const AppView());
}

Future<void> init(Args args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Util.isMobile()) {
    FlutterForegroundTask.initCommunicationPort();
  }
  await Util.initStorageDir();
  await Database.instance.init();
  ///TODO Msix Pack
  if (Util.isDesktop()) {
    if (Platform.isWindows) {
      const initializationSettings = InitializationSettings(
        windows: WindowsInitializationSettings(
          appName: 'Gopeed(Fluent)',
          appUserModelId: 'Mine.Gopeed.Fluent',
          guid: '0197064E-A982-7D4A-8AAA-B3F15AF86E60',
        ),
      );
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // onDidReceiveNotificationResponse: selectNotificationStream.add,
        // onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
      //         Platform.isLinux
      //     ? null
      //     : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      // String initialRoute = HomePage.routeName;
      // if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      //   selectedNotificationPayload =
      //       notificationAppLaunchDetails!.notificationResponse?.payload;
      //   initialRoute = SecondPage.routeName;
      // }
    }
    await windowManager.ensureInitialized();
    final windowState = Database.instance.getWindowState();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
      await windowManager.setMinimumSize(const Size(500, 300));
      await windowManager.setSize(Size(windowState?.width ?? 800, windowState?.height ?? 600));
      await windowManager.setAlignment(Alignment.center);
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setSkipTaskbar(false);
      await windowManager.setPreventClose(true);
    });
  }

  initLogger();

  try {
    await initPackageInfo();
  } catch (e) {
    logger.e("init package info fail", e);
  }

  final controller = Get.put(AppController());
  try {
    await controller.loadStartConfig();
    final startCfg = controller.startConfig.value;
    controller.runningPort.value = await LibgopeedBoot.instance.start(startCfg);
    api.init(startCfg.network, controller.runningAddress(), startCfg.apiToken);
  } catch (e) {
    logger.e("libgopeed init fail", e);
  }

  try {
    await controller.loadDownloaderConfig();
  } catch (e) {
    logger.e("load config fail", e);
  }

  () async {
    if (Util.isDesktop()) {
      try {
        registerUrlScheme("gopeed");
        if (controller.downloaderConfig.value.extra.defaultBtClient) {
          registerDefaultTorrentClient();
        }
      } catch (e) {
        logger.e("register scheme fail", e);
      }

      try {
        await installHost();
      } catch (e) {
        logger.e("browser extension host binary install fail", e);
      }
      for (final browser in Browser.values) {
        try {
          await installManifest(browser);
        } catch (e) {
          logger.e("browser [${browser.name}] extension host integration fail", e);
        }
      }
    }
  }();
}

Future<void> onStart() async {
  // if is debug mode, check language message is complete,change debug locale to your comfortable language if you want
  if (kDebugMode) {
    final debugLang = getLocaleKey(debugLocale);
    final fullMessages = messages.keys[debugLang];
    messages.keys.keys.where((e) => e != debugLang).forEach((lang) {
      final langMessages = messages.keys[lang];
      if (langMessages == null) {
        logger.w("missing language: $lang");
        return;
      }
      final missingKeys = fullMessages!.keys.where((key) => langMessages[key] == null);
      if (missingKeys.isNotEmpty) {
        logger.w("missing language: $lang, keys: $missingKeys");
      }
    });
  }
}
