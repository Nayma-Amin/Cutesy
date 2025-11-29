import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        // 🔥 Prevent Flutter crash if index = -1
        currentIndex: currentIndex == -1 ? 0 : currentIndex,

        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: const Color(0xFFFDF1F5),

        showSelectedLabels: false,
        showUnselectedLabels: false,

        items: [
          _navItem(Icons.home_rounded, 0, currentIndex),
          _navItem(Icons.discount_rounded, 1, currentIndex),
          _navItem(Icons.shopping_cart, 2, currentIndex),
          _navItem(Icons.person_rounded, 3, currentIndex),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(
      IconData icon, int index, int currentIndex) {
    
    // 🔥 NEW: If currentIndex = -1 → force all icons unselected
    final bool isActive =
        currentIndex != -1 && index == currentIndex;

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: isActive ? 28 : 26,
          color: isActive ? const Color(0xFFE370E4) : Colors.grey.shade400,
        ),
      ),
      label: "",
    );
  }
}