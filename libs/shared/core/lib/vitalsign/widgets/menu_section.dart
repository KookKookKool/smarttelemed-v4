import 'package:flutter/material.dart';

class MenuSection extends StatelessWidget {
  const MenuSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 12),
          child: Text(
            'การบันทึก',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
       Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 33,
            runSpacing: 12,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/recordNote'),
                child: const MenuActionButton(
                  icon: Icons.edit_note,
                  label: 'บันทึก',
                  color: Colors.teal,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/makeAppointment'),
                child: const MenuActionButton(
                  icon: Icons.create, 
                  label: 'ทำนัด', 
                  color: Colors.teal
                ),
              ),
              
              const MenuActionButton(icon: Icons.add, label: 'เพิ่ม', color: Colors.teal),
            ],
          ),
        )
      ],
    );
  }
}

class MenuActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const MenuActionButton({
    Key? key,
    required this.icon,
    required this.label,
    this.color = Colors.teal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
