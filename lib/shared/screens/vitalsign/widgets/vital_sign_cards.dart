import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/screens/vitalsign/widgets/numpad.dart';

class VitalSignCards extends StatefulWidget {
  const VitalSignCards({Key? key}) : super(key: key);

  @override
  State<VitalSignCards> createState() => _VitalSignCardsState();
}

class _VitalSignCardsState extends State<VitalSignCards> {
  int _selectedIndex = -1;
  final List<Map<String, dynamic>> _items = [
    {'title': 'BP',   'value': '140/90', 'unit': 'mmHg', 'allowDecimal': false, 'allowSlash': true},
    {'title': 'PR',   'value': '78',     'unit': 'bpm.', 'allowDecimal': false, 'allowSlash': false},
    {'title': 'RR',   'value': '20',     'unit': 'bpm.', 'allowDecimal': false, 'allowSlash': false},
    {'title': 'SpO2', 'value': '99',     'unit': '%',    'allowDecimal': false, 'allowSlash': false},
    {'title': 'BT',   'value': '36.7',   'unit': '°C',   'allowDecimal': true,  'allowSlash': false},
    {'title': 'DTX',  'value': '123',    'unit': 'mg%',  'allowDecimal': false, 'allowSlash': false},
    {'title': 'BW',   'value': '78',     'unit': 'Kg',   'allowDecimal': true,  'allowSlash': false},
    {'title': 'H',    'value': '167',    'unit': 'cm',   'allowDecimal': false, 'allowSlash': false},
  ];

  Future<void> _editItem(int i) async {
    setState(() => _selectedIndex = i);
    final it = _items[i];
    final res = await showNativeNumPad(
      context,
      title: it['title'],
      unit: it['unit'],
      initial: it['value'],
      allowDecimal: it['allowDecimal'],
      allowSlash: it['allowSlash'], // BP จะพิมพ์ได้เป็น 120/80
    );
    if (!mounted) return;
    if (res != null) setState(() => it['value'] = res);
    setState(() => _selectedIndex = -1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text('Vital sign',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        GridView.builder(
          itemCount: _items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, i) {
            final it = _items[i];
            final selected = i == _selectedIndex;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _editItem(i),
              child: VitalSignCard(
                title: it['title'],
                value: it['value'],
                unit: it['unit'],
                valueColor: Colors.teal,
                selected: selected,
              ),
            );
          },
        ),
      ],
    );
  }
}

class VitalSignCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color valueColor;
  final bool selected;

  const VitalSignCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    this.valueColor = Colors.teal,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final border = selected ? Border.all(color: const Color(0xFF00B3A8), width: 2) : null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, color: valueColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(unit, style: const TextStyle(fontSize: 10, color: Colors.black38)),
          ],
        ),
      ),
    );
  }
}
