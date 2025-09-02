// lib/screens/main_pt/widgets/patient_card.dart
import 'package:flutter/material.dart';

class PatientCard extends StatelessWidget {
  const PatientCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/profile.jpg',
              width: 92, height: 72, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(width: 92, height: 72, child: Icon(Icons.person)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('นายสมใจ อิ่มบุญ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('วันเกิด 01 ม.ค. 2500 (อายุ 66 ปี)', style: TextStyle(fontSize: 13)),
                Text('กรุ๊ปเลือด โอ+', style: TextStyle(fontSize: 13)),
                Text('น้ำหนัก 70 กก. ส่วนสูง 175 ซม.', style: TextStyle(fontSize: 13)),
                Text('โรคประจำตัว', style: TextStyle(fontSize: 13)),
                Text('ประวัติการแพ้', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}