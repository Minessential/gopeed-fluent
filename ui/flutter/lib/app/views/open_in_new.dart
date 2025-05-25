import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenInNew extends StatelessWidget {
  final String url;

  const OpenInNew({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'open'.tr,
      child: HyperlinkButton(
        onPressed: () {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        style: ButtonStyle(padding: WidgetStateProperty.all(const EdgeInsets.all(6))),
        child: const Icon(FluentIcons.open_24_regular, size: 16.0),
      ),
    );
  }
}
