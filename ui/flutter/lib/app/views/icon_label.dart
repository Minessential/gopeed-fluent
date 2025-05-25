import 'package:fluent_ui/fluent_ui.dart';

class IconLabel extends StatelessWidget {
  const IconLabel({
    super.key,
    required this.icon,
    required this.label,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final Widget icon;
  final String label;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        Container(width: 16, height: 16, margin: const EdgeInsets.only(right: 4), child: icon),
        Text(label),
      ],
    );
  }
}
