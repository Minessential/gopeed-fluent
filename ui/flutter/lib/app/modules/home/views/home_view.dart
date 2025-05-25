import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/views/app_logo.dart';
import 'package:gopeed/app/views/window_buttons.dart';
import 'package:window_manager/window_manager.dart';

import '../../../routes/app_pages.dart';
import '../../../views/responsive_builder.dart';
import '../controllers/home_controller.dart';

const showLogoRoutes = [Routes.ROOT, Routes.HOME, Routes.TASK, Routes.TASK_DONE, Routes.EXTENSION, Routes.SETTING];

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetRouterOutlet.builder(
      builder: (context, delegate, currentRoute) {
        switch (currentRoute?.uri.path) {
          case Routes.TASK_DONE:
            controller.currentIndex.value = 1;
            break;
          case Routes.EXTENSION:
            controller.currentIndex.value = 2;
            break;
          case Routes.SETTING:
            controller.currentIndex.value = 3;
            break;
          default:
            controller.currentIndex.value = 0;
            break;
        }

        return NavigationView(
          appBar: NavigationAppBar(
            leading: !showLogoRoutes.contains(currentRoute?.uri.path)
                ? IconButton(
                    icon: const Icon(FluentIcons.arrow_left_16_regular, size: 18),
                    onPressed: () => delegate.popRoute(),
                  )
                : const DragToMoveArea(child: AppLogo(size: 25)),
            title: DragToMoveArea(
              child: Align(alignment: AlignmentDirectional.centerStart, child: Text('appNameMod'.tr)),
            ),
            actions: const WindowButtons(),
          ),
          paneBodyBuilder: (item, c) {
            return GetRouterOutlet(
              initialRoute: Routes.TASK,
              // anchorRoute: '/',
              // filterPages: (afterAnchor) {
              //   logger.w(afterAnchor);
              //   logger.w(afterAnchor.take(1));
              //   return afterAnchor.take(1);
              // },
            );
          },
          pane: NavigationPane(
            selected: controller.currentIndex.value,
            onItemPressed: (value) {
              final currentPath = currentRoute?.uri.path;
              switch (value) {
                case 0:
                  if (currentPath != Routes.TASK) delegate.offAndToNamed(Routes.TASK);
                  break;
                case 1:
                  if (currentPath != Routes.TASK_DONE) delegate.offAndToNamed(Routes.TASK_DONE);
                  break;
                case 2:
                  if (currentPath != Routes.EXTENSION) delegate.offAndToNamed(Routes.EXTENSION);
                  break;
                case 3:
                  if (currentPath != Routes.SETTING) delegate.offAndToNamed(Routes.SETTING);
                  break;
              }
            },
            displayMode: ResponsiveBuilder.isNarrow(context) || ResponsiveBuilder.isMedium(context)
                ? PaneDisplayMode.compact
                : PaneDisplayMode.open,
            items: [
              PaneItem(
                icon: const Icon(FluentIcons.cloud_arrow_down_32_regular),
                title: Text('task'.tr),
                body: const SizedBox.shrink(),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.cloud_archive_32_regular),
                title: Text('taskDone'.tr),
                body: const SizedBox.shrink(),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.wrench_screwdriver_32_regular),
                title: Text('extensions'.tr),
                body: const SizedBox.shrink(),
              ),
            ],
            footerItems: [
              PaneItem(
                icon: const Icon(FluentIcons.settings_32_regular),
                title: Text('setting'.tr),
                body: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}
