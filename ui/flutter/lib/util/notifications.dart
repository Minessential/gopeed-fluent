import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
int id = 0;

Future<void> showNotificationWithActions(String title, String body) async {
  // final WindowsNotificationDetails windowsNotificationsDetails = WindowsNotificationDetails(
  //   subtitle: 'Click the three dots for another button',
  //   actions: <WindowsAction>[
  //     const WindowsAction(
  //       content: 'Text',
  //       arguments: 'text',
  //     ),
  //     WindowsAction(
  //       content: 'Image',
  //       arguments: 'image',
  //       imageUri: WindowsImage.getAssetUri('icons/coworker.png'),
  //     ),
  //     const WindowsAction(
  //       content: 'Context',
  //       arguments: 'context',
  //       placement: WindowsActionPlacement.contextMenu,
  //     ),
  //   ],
  // );

  // final NotificationDetails notificationDetails = NotificationDetails(windows: windowsNotificationsDetails);
  await flutterLocalNotificationsPlugin.show(id, title, body, const NotificationDetails(), payload: 'item z');
}
