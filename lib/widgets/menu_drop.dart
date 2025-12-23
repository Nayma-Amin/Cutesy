import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class DropMenu extends StatelessWidget {
  final bool isVisible;
  final Function(String) onItemTap;
  final String userRole;

  const DropMenu({
    super.key,
    required this.isVisible,
    required this.onItemTap,
    required this.userRole,
  });

  static const String adminEmail = "admin@shopcutesy.com";
  static const String facebookPageUrl =
      "https://www.facebook.com/your_facebook_page";
  static const String instagramPageUrl =
      "https://www.instagram.com/your_instagram_page";
  static const String shopAddressMapUrl =
      "https://www.google.com/maps/search/?api=1&query=Shop+Cutesy+Dhaka";
  static const String appShareText =
      "Check out Shop Cutesy! 💜\nDownload now:\nhttps://yourapp.link";

  @override
  Widget build(BuildContext context) {
    final items = [
      "Terms and Conditions",
      "Contact Us",
      "Facebook Page Link",
      "Instagram Link",
      "Share our App",
      "Shop Address",
      if (userRole == "admin" || userRole == "manager") "Management",
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isVisible
          ? Material(
              key: const ValueKey("dropdown"),
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.map((label) {
                    return GestureDetector(
                      onTap: () => _handleTap(context, label),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 15,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(241, 217, 251, 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _handleTap(BuildContext context, String label) async {
    switch (label) {
      case "Contact Us":
        await _launchUri(Uri(
          scheme: 'mailto',
          path: adminEmail,
          query: 'subject=Support Request',
        ));
        break;

      case "Facebook Page Link":
        await _launchUri(Uri.parse(facebookPageUrl));
        break;

      case "Instagram Link":
        await _launchUri(Uri.parse(instagramPageUrl));
        break;

      case "Share our App":
        await Share.share(appShareText);
        break;

      case "Shop Address":
        await _launchUri(Uri.parse(shopAddressMapUrl));
        break;

      default:
        onItemTap(label);
    }
  }

  Future<void> _launchUri(Uri uri) async {
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint("Could not launch $uri");
    }
  }
}
