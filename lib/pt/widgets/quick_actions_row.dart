// lib/screens/main_pt/widgets/quick_actions_row.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/core/vitalsign/vitalsign_screen.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        QuickAction(icon: Icons.search, label: 'ตรวจ', routeName: '/search'),
        QuickAction(icon: Icons.medical_services_outlined, label: 'พบแพทย์', routeName: '/doctor'),
        QuickAction(icon: Icons.calendar_month_outlined, label: 'นัดหมาย', routeName: '/appoint'),
      ],
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String routeName;
  const QuickAction({Key? key, required this.icon, required this.label, required this.routeName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (label == 'ตรวจ') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VitalSignScreen()));
        } else {
          Navigator.pushNamed(context, routeName);
        }
      },
      child: Column(
        children: [
          Container(
            width: 96, height: 84,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(child: Icon(icon, size: 36, color: const Color(0xFF00B3A8))),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
