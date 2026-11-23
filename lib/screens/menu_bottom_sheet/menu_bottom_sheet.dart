// lib/screens/side_nav/custom_bottom_menu_sheet.dart
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:videodownloader/core/utils/app_constants.dart';
import 'package:videodownloader/screens/menu_bottom_sheet/webview_screen.dart';

class CustomBottomMenuSheet extends StatelessWidget {
  const CustomBottomMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final InAppReview inAppReview = InAppReview.instance;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,   // This ensures it fits content only
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          _buildMenuItem(
            icon: Icons.star_border_rounded,
            text: "Rate Us",
            onTap: () => inAppReview.openStoreListing(),
          ),

          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0), indent: 16, endIndent: 16),

          _buildMenuItem(
            icon: Icons.feedback_outlined,
            text: "Send us a feedback",
            onTap: () async {
              final Uri url = Uri.parse(
                  'mailto:${AppConstants.supportEmail}?subject=Feedback for TwiDown');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),

          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0), indent: 16, endIndent: 16),

          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            text: "Privacy Policy",
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebViewScreen(
                    url: "https://example.com/privacy-policy",
                    title: "Privacy Policy",
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3B82F6), size: 26),
      title: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}