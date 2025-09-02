// lib/screens/main_pt/widgets/main_slider/home_visit_history.dart
import 'package:flutter/material.dart';

class HomeVisitHistory extends StatelessWidget {
  const HomeVisitHistory({Key? key}) : super(key: key);

  Widget _item({required String title, required String by}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(by, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF00B3A8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('ประวัติการเยี่ยมบ้าน', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      _item(title: 'นัดวันที่ 11 สิงหาคม 2568', by: 'บันทึกโดย บส.สมใจ ยิ้มดี'),
      _item(title: 'นัดวันที่ 01 สิงหาคม 2568', by: 'บันทึกโดย บส.สมใจ ยิ้มดี'),
      _item(title: 'นัดวันที่ 22 กรกฎาคม 2568', by: 'บันทึกโดย บส.สมใจ ยิ้มดี'),
    ]);
  }
}