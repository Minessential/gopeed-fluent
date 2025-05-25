import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';

import '../../util/message.dart';

class CopyButton extends StatefulWidget {
  final String? url;
  final double size;
  const CopyButton(this.url, {super.key, this.size = 20});

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool success = false;

  copy() {
    final url = widget.url;
    if (url != null) {
      try {
        Clipboard.setData(ClipboardData(text: url));
        setState(() {
          success = true;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            success = false;
          });
        });
      } catch (e) {
        showErrorMessage(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: success
          ? Icon(FluentIcons.checkmark_32_regular, size: widget.size)
          : Icon(FluentIcons.copy_32_regular, size: widget.size),
      onPressed: copy,
    );
  }
}
