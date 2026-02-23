import 'dart:html' as html;

Future<void> openMapUrl(String url) async {
  html.window.open(url, '_blank');
}