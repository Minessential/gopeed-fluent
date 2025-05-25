import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:gopeed/core/get_fluent_app/get_fluent_app.dart';
import 'package:gopeed/theme/theme.dart';
import 'package:window_manager/window_manager.dart'; // Import the required packages

import '../../../../i18n/message.dart';
import '../../../../util/locale_manager.dart';
import '../../../../util/util.dart'; // Import the required packages
import '../../../routes/app_pages.dart';
import '../controllers/app_controller.dart';

class AppView extends GetView<AppController> {
  const AppView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = controller.downloaderConfig.value;
    return WithForegroundTask(
      child: GetFluentApp.router(
        useInheritedMediaQuery: true,
        debugShowCheckedModeBanner: false,
        theme: GopeedTheme.light,
        darkTheme: GopeedTheme.dark,
        themeMode: ThemeMode.values.byName(config.extra.themeMode),
        translations: messages,
        locale: toLocale(config.extra.locale),
        fallbackLocale: fallbackLocale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: messages.keys.keys.map((e) => toLocale(e)).toList(),
        getPages: AppPages.routes,

        // Add listening to theme changes, set the title bar color according to the current system theme.
        builder: (context, child) {
          // if platform is desktop
          if (Util.isDesktop()) {
            // actual brightness of the UI
            Brightness brightness = FluentTheme.of(context).brightness;
            // Set the title bar to use the actual brightness of the UI
            windowManager.setBrightness(brightness);
          }
          return child!;
        },
      ),
    );
  }
}
