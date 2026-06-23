import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CustomHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFFA052BE), // สีม่วงตามภาพ
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
    );
  }

  // กำหนดความสูงของ AppBar ตามมาตรฐาน Flutter
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
