import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

enum SortState { none, asc, desc }

class SortIconButton extends StatefulWidget {
  final String label;
  final SortState initialState;
  final Function(SortState) onStateChanged;

  const SortIconButton({
    Key? key,
    required this.label,
    this.initialState = SortState.none,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  State<SortIconButton> createState() => _SortIconState();
}

class _SortIconState extends State<SortIconButton> {
  late SortState _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
  }

  void _toggleState() {
    setState(() {
      switch (_currentState) {
        case SortState.none:
          _currentState = SortState.asc;
          break;
        case SortState.asc:
          _currentState = SortState.desc;
          break;
        case SortState.desc:
          _currentState = SortState.none;
          break;
      }
    });
    widget.onStateChanged(_currentState);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return IconButton(
      onPressed: _toggleState,
      icon: Row(
        spacing: 4,
        children: [
          Text(widget.label, style: theme.typography.bodyStrong),
          ?switch (_currentState) {
            SortState.none => null,
            SortState.asc => const Icon(FluentIcons.chevron_up_16_filled, size: 16),
            SortState.desc => const Icon(FluentIcons.chevron_down_16_filled, size: 16),
          },
        ],
      ),
    );
  }
}
