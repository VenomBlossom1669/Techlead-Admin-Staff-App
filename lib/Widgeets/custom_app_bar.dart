import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techlead/core/app_bar_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final double fontSize;
  const CustomAppBar({super.key, this.fontSize = 15});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleText = ref.watch(appBarTitleProvider);
    final gradientColors = ref.watch(appBarGradientColorsProvider);
    final customTitle = ref.watch(customTitleWidgetProvider);

    return AppBar(
      title: customTitle ??
          Text(
            titleText,
            textScaleFactor: 1.0,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: "Times New Roman",
              fontSize: fontSize,
            ),
          ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

