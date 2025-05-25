import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:gopeed/database/database.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key, required this.isHistoryListEmpty, required this.historyList});

  final bool isHistoryListEmpty;
  final Widget historyList;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
      content: Column(
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(FluentIcons.history_24_regular, size: 24),
              Expanded(child: Text('history'.tr, style: theme.typography.subtitle)),
              Tooltip(
                message: "clearHistory".tr,
                child: IconButton(
                  onPressed: () {
                    Database.instance.clearCreateHistory();
                    Navigator.pop(context);
                  },
                  icon: const Icon(FluentIcons.history_dismiss_20_regular, size: 20),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(FluentIcons.dismiss_20_regular, size: 20),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.isHistoryListEmpty
                    ? [const Icon(FluentIcons.info_48_regular, size: 48), Text('noHistoryFound'.tr)]
                    : [Expanded(child: widget.historyList)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
