import 'package:flutter/material.dart';

class Manubar extends StatelessWidget {
  final int? currentIndex;            // ส่งมาก็ได้
  final ValueChanged<int>? onTap;     // ส่งมาก็ได้

  const Manubar({super.key, this.currentIndex, this.onTap});

  int _indexForRoute(String? name) {
    switch (name) {
      case '/dashboard': return 0;
      case '/addcardpt':  return 1; // ให้ตรงกับ routes ของคุณ
      case '/settings':     return 2;
      default:           return 0;
    }
  }

  String _routeForIndex(int i) {
    switch (i) {
      case 0: return '/dashboard';
      case 1: return '/addcardpt';
      case 2: return '/settings';
      default: return '/dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name;
    final idx = currentIndex ?? _indexForRoute(routeName);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: 'Home', // ต้องไม่เป็น null
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Add Card',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      currentIndex: idx,
      selectedItemColor: Colors.blue,
      // ถ้าอยากซ่อนไม่ให้โชว์ข้อความใต้ไอคอน ก็เปิดสองบรรทัดนี้ได้
      // showSelectedLabels: false,
      // showUnselectedLabels: false,
      onTap: onTap ?? (i) {
        if (i == idx) return;
        Navigator.pushReplacementNamed(context, _routeForIndex(i));
      },
    );
  }
}
