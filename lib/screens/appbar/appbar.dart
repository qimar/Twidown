import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onDownloadsPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.onMenuPressed,
    this.onDownloadsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF3B82F6),
      elevation: 0,
      titleSpacing: 16,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 26),
              onPressed: onMenuPressed ?? () {},
            ),
      
      // Title - Now Left Aligned
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: false,   // ← This makes title left-aligned

      actions: showBackButton
          ? null
          : [
              IconButton(
                icon: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: onDownloadsPressed ?? () {},
                tooltip: "Open Downloads",
              ),
              const SizedBox(width: 8),
            ],
    );
  }
}