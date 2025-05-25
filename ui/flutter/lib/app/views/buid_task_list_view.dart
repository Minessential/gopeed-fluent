import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:gopeed/app/modules/task/controllers/task_list_controller.dart';
import 'package:gopeed/app/views/copy_button.dart';
import 'package:gopeed/app/views/fluent/universal_pane_child.dart';
import 'package:gopeed/app/views/icon_label.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;

import '../../api/api.dart';
import '../../api/model/task.dart';
import '../../util/file_explorer.dart';
import '../../util/message.dart';
import '../../util/util.dart';
import '../modules/app/controllers/app_controller.dart';
import '../modules/task/controllers/task_downloaded_controller.dart';
import '../modules/task/controllers/task_downloading_controller.dart';
import '../routes/app_pages.dart';
import 'file_icon.dart';

enum TaskListStatus { downloading, downloaded }

class BuildTaskListView extends GetView {
  final List<Task> tasks;
  final TaskListStatus status;

  const BuildTaskListView({super.key, required this.tasks, required this.status});

  @override
  Widget build(BuildContext context) {
    late final TaskListController taskListController;
    switch (status) {
      case TaskListStatus.downloading:
        taskListController = Get.find<TaskDownloadingController>();
      case TaskListStatus.downloaded:
        taskListController = Get.find<TaskDownloadedController>();
    }

    bool? isAllSelected() {
      final List<Task> currentTasks = taskListController.tasks;
      final List<String> currentSelectedTaskIds = taskListController.selectedTaskIds;

      if (currentTasks.isEmpty) {
        return false;
      }

      if (currentSelectedTaskIds.isEmpty) {
        return false;
      }

      final Set<String> allTaskIds = currentTasks.map((task) => task.id).toSet();
      final Set<String> selectedIdsSet = currentSelectedTaskIds.toSet();

      if (selectedIdsSet.length >= allTaskIds.length) {
        if (allTaskIds.every((taskId) => selectedIdsSet.contains(taskId))) {
          return true;
        }
      }

      if (currentSelectedTaskIds.isNotEmpty && currentSelectedTaskIds.length < currentTasks.length) {
        bool allSelectedAreValidTasks = currentSelectedTaskIds.every((id) => allTaskIds.contains(id));
        if (allSelectedAreValidTasks) {
          return null;
        }
      }

      return false;
    }

    // Check if there are tasks that can be continued
    bool canContinue() {
      return tasks
          .where((e) => taskListController.selectedTaskIds.contains(e.id))
          .any((task) => task.status == Status.pause || task.status == Status.wait);
    }

    // Check if there are tasks that can be paused
    bool canPause() {
      return tasks
          .where((e) => taskListController.selectedTaskIds.contains(e.id))
          .any((task) => task.status == Status.running);
    }

    // Filter selected task ids that are still in the task list
    filterSelectedTaskIds(Iterable<String> selectedTaskIds) =>
        selectedTaskIds.where((id) => tasks.any((task) => task.id == id)).toList();

    return Column(
      children: [
        UniversalPaneChild(
          child: SizedBox(
            height: 48,
            child: Obx(() {
              if (tasks.isEmpty) return const SizedBox.shrink();
              return Row(
                children: [
                  const SizedBox(width: 16),
                  Checkbox(
                    checked: isAllSelected(),
                    onChanged: (v) {
                      if (v == false) {
                        taskListController.selectedTaskIds([]);
                      } else {
                        taskListController.selectedTaskIds(tasks.map((e) => e.id).toList());
                      }
                    },
                    content: Text('selectAll'.tr),
                  ),
                  const Spacer(),
                  if (status == TaskListStatus.downloading && canContinue()) ...[
                    IconButton(
                      icon: IconLabel(icon: const Icon(FluentIcons.play_16_regular, size: 16), label: 'continue'.tr),
                      onPressed: () async {
                        try {
                          await continueAllTasks(filterSelectedTaskIds(taskListController.selectedTaskIds));
                        } finally {
                          taskListController.selectedTaskIds([]);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (status == TaskListStatus.downloading && canPause()) ...[
                    IconButton(
                      icon: IconLabel(icon: const Icon(FluentIcons.pause_16_regular, size: 16), label: 'pause'.tr),
                      onPressed: () async {
                        try {
                          await pauseAllTasks(filterSelectedTaskIds(taskListController.selectedTaskIds));
                        } finally {
                          taskListController.selectedTaskIds([]);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (taskListController.selectedTaskIds.isNotEmpty)
                    IconButton(
                      icon: IconLabel(icon: const Icon(FluentIcons.delete_16_regular, size: 16), label: 'delete'.tr),
                      onPressed: () async {
                        try {
                          await showDeleteDialog(context, filterSelectedTaskIds(taskListController.selectedTaskIds));
                        } finally {
                          taskListController.selectedTaskIds([]);
                        }
                      },
                    ),
                  const SizedBox(width: 20),
                ],
              );
            }),
          ),
        ),
        Expanded(child: Obx(() => buildTaskList(context, tasks, taskListController.selectedTaskIds))),
      ],
    );
  }

  Widget buildTaskList(BuildContext context, tasks, selectedTaskIds) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length + 1,
      itemBuilder: (context, index) {
        if (index == tasks.length) {
          return const SizedBox(height: 75);
        }
        return UniversalPaneChild(
          child: _Item(selectedTaskIds: selectedTaskIds, task: tasks[index], status: status),
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.selectedTaskIds, required this.task, required this.status});

  final List<String> selectedTaskIds;
  final TaskListStatus status;
  final Task task;

  bool isDone() {
    return task.status == Status.done;
  }

  bool isRunning() {
    return task.status == Status.running;
  }

  bool isSelect() {
    return selectedTaskIds.contains(task.id);
  }

  bool isFolderTask() {
    return task.isFolder;
  }

  String getProgressText() {
    if (isDone()) {
      return Util.fmtByte(task.meta.res!.size);
    }
    if (task.meta.res == null) {
      return "";
    }
    final total = task.meta.res!.size;
    return Util.fmtByte(task.progress.downloaded) + (total > 0 ? " / ${Util.fmtByte(total)}" : "");
  }

  Future<void> _showInfoDialog(BuildContext context, Task task) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        final theme = FluentTheme.of(context);
        final titleStyle = theme.typography.bodyLarge?.copyWith(fontWeight: FontWeight.bold);
        return ContentDialog(
          title: Text('taskDetail'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text('taskName'.tr, style: titleStyle),
                Text(task.name),
                const SizedBox(height: 16),
                Row(
                  spacing: 8,
                  children: [
                    Flexible(child: Text('taskUrl'.tr, style: titleStyle)),
                    CopyButton(task.meta.req.url),
                  ],
                ),
                Text(task.meta.req.url),
                const SizedBox(height: 16),
                Row(
                  spacing: 8,
                  children: [
                    Flexible(child: Text('downloadPath'.tr, style: titleStyle)),
                    IconButton(
                      icon: const Icon(FluentIcons.folder_open_20_regular, size: 20.0),
                      onPressed: () => task.explorer(),
                    ),
                  ],
                ),
                Text(task.explorerUrl),
              ],
            ),
          ),
          actions: [
            Container(),
            FilledButton(child: Text('close'.tr), onPressed: () => Get.back()),
            Container(),
          ],
        );
      },
    );
  }

  Widget _buildAction(BuildContext context) {
    double getProgress() {
      final totalSize = task.meta.res?.size ?? 0;
      return totalSize <= 0 ? 0 : (task.progress.downloaded / totalSize) * 100;
    }

    final theme = FluentTheme.of(context);
    final color = theme.brightness == Brightness.light ? Colors.white : const Color(0xE4000000);

    return SizedBox(
      width: 95,
      child: isDone()
          ? Button(onPressed: () => task.open(), child: Text('open'.tr))
          : FilledButton(
              onPressed: () {
                if (isRunning()) {
                  pauseTask(task.id).catchError((e) {
                    if (context.mounted) showErrorMessage(context, e);
                  });
                } else {
                  continueTask(task.id).catchError((e) {
                    if (context.mounted) showErrorMessage(context, e);
                  });
                }
              },
              child: SizedBox(
                width: 20,
                height: 20,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    ProgressRing(
                      value: isRunning() ? getProgress() : null,
                      strokeWidth: 2,
                      activeColor: color,
                      backgroundColor: color.withValues(alpha: 0.3),
                    ),
                    Icon(
                      isRunning() ? FluentIcons.pause_12_filled : FluentIcons.play_12_filled,
                      size: 12.0,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final menuController = FlyoutController();

    late final TaskListController taskListController;
    switch (status) {
      case TaskListStatus.downloading:
        taskListController = Get.find<TaskDownloadingController>();
      case TaskListStatus.downloaded:
        taskListController = Get.find<TaskDownloadedController>();
    }

    return HoverButton(
      onPressed: () {},
      hitTestBehavior: HitTestBehavior.deferToChild,
      builder: (context, states) {
        return FocusBorder(
          focused: states.isFocused,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            constraints: const BoxConstraints(minHeight: 42),
            decoration: ShapeDecoration(
              color: theme.resources.cardBackgroundFillColorDefault,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.resources.cardStrokeColorDefault),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0), bottom: Radius.circular(6.0)),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Obx(
                  () => Row(
                    children: [
                      const SizedBox(width: 16),
                      Checkbox(
                        checked: isSelect(),
                        onChanged: (v) {
                          if (v == null) return;
                          if (v == false) {
                            taskListController.selectedTaskIds(
                              taskListController.selectedTaskIds.where((element) => element != task.id).toList(),
                            );
                          } else {
                            taskListController.selectedTaskIds([...taskListController.selectedTaskIds, task.id]);
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          fileIcon(task.name, isFolder: isFolderTask(), isBitTorrent: task.protocol == Protocol.bt),
                          size: 48,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(getProgressText(), style: theme.typography.caption),
                          ],
                        ),
                      ),
                      if (constraints.maxWidth > 750)
                        Expanded(flex: 1, child: Text(task.status.humanname, textAlign: TextAlign.center)),
                      if (constraints.maxWidth > 650)
                        Expanded(
                          flex: 1,
                          child: Text(
                            "${Util.fmtByte(task.progress.speed)} / s",
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(width: 8),
                      _buildAction(context),
                      const SizedBox(width: 8),
                      FlyoutTarget(
                        controller: menuController,
                        child: IconButton(
                          icon: const Icon(FluentIcons.more_horizontal_24_regular, size: 24.0),
                          onPressed: () {
                            menuController.showFlyout(
                              autoModeConfiguration: FlyoutAutoConfiguration(
                                preferredMode: FlyoutPlacementMode.bottomCenter,
                              ),
                              barrierDismissible: true,
                              dismissOnPointerMoveAway: false,
                              dismissWithEsc: true,
                              navigatorKey: Get.key.currentState,
                              builder: (ctx) {
                                return MenuFlyout(
                                  items: [
                                    if (isDone())
                                      MenuFlyoutItem(
                                        leading: const Icon(FluentIcons.folder_open_16_regular, size: 16.0),
                                        text: Text('openFolder'.tr),
                                        onPressed: () => task.explorer(),
                                      ),
                                    MenuFlyoutItem(
                                      leading: const Icon(FluentIcons.delete_16_regular, size: 16.0),
                                      text: Text('delete'.tr),
                                      onPressed: () {
                                        showDeleteDialog(context, [task.id]).then((_) {
                                          if (ctx.mounted) Flyout.of(ctx).close();
                                        });
                                      },
                                    ),
                                    const MenuFlyoutSeparator(),
                                    MenuFlyoutItem(
                                      leading: const Icon(FluentIcons.info_16_regular, size: 16.0),
                                      text: Text('info'.tr),
                                      onPressed: () {
                                        _showInfoDialog(context, task).then((_) {
                                          if (ctx.mounted) Flyout.of(ctx).close();
                                        });
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

Future<void> showDeleteDialog(BuildContext context, List<String> ids) {
  final appController = Get.find<AppController>();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ContentDialog(
      title: Text('deleteTask'.trParams({'count': ids.length.toString()})),
      content: Obx(
        () => Checkbox(
          checked: appController.downloaderConfig.value.extra.lastDeleteTaskKeep,
          content: Text('deleteTaskTip'.tr, style: context.textTheme.bodyLarge),
          onChanged: (v) {
            appController.downloaderConfig.update((val) {
              val!.extra.lastDeleteTaskKeep = v!;
            });
          },
        ),
      ),
      actions: [
        FilledButton(
          child: Text('confirm'.tr),
          onPressed: () async {
            try {
              final force = !appController.downloaderConfig.value.extra.lastDeleteTaskKeep;
              await appController.saveConfig();
              await deleteTasks(ids, force);
              Get.back();
            } catch (e) {
              Get.back();
              if (context.mounted) showErrorMessage(context, e);
            }
          },
        ),
        Button(child: Text('cancel'.tr), onPressed: () => Get.back()),
      ],
    ),
  );
}

extension TaskEnhance on Task {
  bool get isFolder {
    return meta.res?.name.isNotEmpty ?? false;
  }

  String get explorerUrl {
    return path.join(Util.safeDir(meta.opts.path), Util.safeDir(name));
  }

  Future<void> explorer() async {
    if (Util.isDesktop()) {
      await FileExplorer.openAndSelectFile(explorerUrl);
    } else {
      Get.rootDelegate.toNamed(Routes.TASK_FILES, parameters: {'id': id});
    }
  }

  Future<void> open() async {
    if (status != Status.done) {
      return;
    }

    if (isFolder) {
      await explorer();
    } else {
      await OpenFilex.open(explorerUrl);
    }
  }
}

extension on Status {
  String get humanname => switch (this) {
    Status.ready => 'taskReady'.tr,
    Status.running => 'taskRunning'.tr,
    Status.pause => 'taskPause'.tr,
    Status.wait => 'taskWait'.tr,
    Status.error => 'taskError'.tr,
    Status.done => 'taskDone'.tr,
  };
}
