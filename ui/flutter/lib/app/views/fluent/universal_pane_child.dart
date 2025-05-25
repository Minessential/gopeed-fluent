import 'package:fluent_ui/fluent_ui.dart';

class UniversalPaneChild extends StatelessWidget {
  const UniversalPaneChild({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        constraints: const BoxConstraints(maxWidth: 1024),
        child: child,
      ),
    );
  }
}
