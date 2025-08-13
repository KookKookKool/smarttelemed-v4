// lib/widget/manubar.dart
import 'package:flutter/material.dart';

class Manubar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const Manubar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'About'),
      ],
      currentIndex: currentIndex,
      selectedItemColor: Colors.blue,
      onTap: onTap,
    );
  }
}
