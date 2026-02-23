import 'dart:html' as html;

void showWebNotification(String title, String body) {
  if (title.isEmpty) title = 'New Task';
  if (body.isEmpty) body = 'You have a new task';

  try {
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body, icon: '/icons/icon-192.png');
    } else if (html.Notification.permission != 'denied') {
      html.Notification.requestPermission().then((permission) {
        if (permission == 'granted') {
          html.Notification(title, body: body, icon: '/icons/icon-192.png');
        }
      });
    }
  } catch (e) {
    print('❌ web notification error: $e');
  }
}
