import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;

class IconButtonLoading extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final IconButtonLoadingController controller;

  const IconButtonLoading({Key? key, required this.icon, required this.onPressed, required this.controller})
    : super(key: key);

  @override
  State<IconButtonLoading> createState() => _IconButtonLoadingState();
}

class _IconButtonLoadingState extends State<IconButtonLoading> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        return IconButton(
          key: widget.key,
          onPressed: value ? null : widget.onPressed,
          icon: value ? const SizedBox(height: 20, width: 20, child: ProgressRing(strokeWidth: 2)) : widget.icon,
        );
      },
    );
  }
}

class IconButtonLoadingController extends ValueNotifier<bool> {
  IconButtonLoadingController() : super(false);

  void start() {
    value = true;
  }

  void stop() {
    value = false;
  }
}
