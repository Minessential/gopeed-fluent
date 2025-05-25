import 'package:fluent_ui/fluent_ui.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 200});

  @override
  Widget build(context) {
    return Image.asset("assets/icon/icon_512.png", width: size, height: size, fit: BoxFit.contain);
  }
}
