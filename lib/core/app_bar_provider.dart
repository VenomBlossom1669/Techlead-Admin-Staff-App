import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final appBarTitleProvider = StateProvider<String>((ref) => "Default Title");

final appBarGradientColorsProvider = StateProvider<List<Color>>((ref) => [
  Color(0xFF2F68AA),
  Color(0xFF025BB6),
]);

// Custom title widget provider
final customTitleWidgetProvider = StateProvider<Widget?>((ref) => null);


void resetAppBar(WidgetRef ref) {
  ref.read(appBarTitleProvider.notifier).state = "Default Title";
  ref.read(appBarGradientColorsProvider.notifier).state = [
    Color(0xFF2F68AA),
    Color(0xFF025BB6),
  ];
  ref.read(customTitleWidgetProvider.notifier).state = null;
}