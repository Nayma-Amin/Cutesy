import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final items = [
      "Terms and Conditions",
      "About Us",
      "Contact Us",
      "Facebook Page Link",
      "Instagram Link",
      "Share our App",
      "Shop Address",
      if (userRole == "admin" || userRole == "manager") "Management",
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: isVisible
          ? Material(
              key: const ValueKey("dropdown"),
              color: Colors.transparent,
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
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
                      onTap: () => onItemTap(label),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
          : const SizedBox.shrink(
              key: ValueKey("hidden"),
            ),
    );
  }
}