import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';

import '../api/model/result.dart';

Future<void> _showErrorInfoBar(BuildContext context, String title, String content) {
  return displayInfoBar(
    context,
    builder: (context, close) {
      return InfoBar(
        title: Text(title),
        content: Text(content),
        severity: InfoBarSeverity.error,
        isLong: content.length > 75,
      );
    },
  );
}

Future<void> _showMsgInfoBar(BuildContext context, String title, String content) {
  return displayInfoBar(
    context,
    builder: (context, close) {
      return InfoBar(title: Text(title), content: Text(content), isLong: content.length > 75);
    },
  );
}

void showErrorMessage(BuildContext context, msg) {
  final title = 'error'.tr;
  if (msg is Result) {
    _showErrorInfoBar(context, title, msg.msg!);
    return;
  }
  if (msg is Exception) {
    final message = (msg as dynamic).message;
    if (message is Result) {
      _showErrorInfoBar(context, title, ((msg as dynamic).message as Result).msg!);
      return;
    }
    if (message is String) {
      _showErrorInfoBar(context, title, message);
      return;
    }
  }
  _showErrorInfoBar(context, title, msg.toString());
}

var _showMessageFlag = true;

void showMessage(BuildContext context, title, msg) {
  if (_showMessageFlag) {
    _showMessageFlag = false;
    _showMsgInfoBar(context, title, msg);
    Future.delayed(const Duration(seconds: 3), () {
      _showMessageFlag = true;
    });
  }
}
