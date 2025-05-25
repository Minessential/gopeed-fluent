import 'package:fluent_ui/fluent_ui.dart';

class FilledButtonLoading extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FilledButtonLoadingController controller;

  const FilledButtonLoading({super.key, required this.child, required this.onPressed, required this.controller});

  @override
  State<FilledButtonLoading> createState() => _FilledButtonLoadingState();
}

class _FilledButtonLoadingState extends State<FilledButtonLoading> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        return FilledButton(

          key: widget.key,
          onPressed: value ? null : widget.onPressed,
          child: value ? const SizedBox(height: 20, width: 20, child: ProgressRing(strokeWidth: 2)) : widget.child,
        );
      },
    );
  }
}

class FilledButtonLoadingController extends ValueNotifier<bool> {
  FilledButtonLoadingController() : super(false);

  void start() {
    value = true;
  }

  void stop() {
    value = false;
  }
}
