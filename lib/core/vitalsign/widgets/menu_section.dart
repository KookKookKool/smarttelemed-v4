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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            MenuActionButton(
              icon: Icons.edit_note,
              label: 'บันทึก',
              color: Colors.teal,
            ),
            MenuActionButton(
              icon: Icons.cleaning_services,
              label: 'สะอาด',
              color: Colors.teal,
            ),
            MenuActionButton(
              icon: Icons.emoji_emotions,
              label: 'อารมณ์',
              color: Colors.teal,
            ),
            MenuActionButton(
              icon: Icons.create,
              label: 'ทำนัด',
              color: Colors.teal,
            ),
          ],
        ),
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
