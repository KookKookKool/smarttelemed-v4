import 'package:flutter/material.dart';

class VitalSignCards extends StatelessWidget {
  const VitalSignCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Vital sign',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          childAspectRatio: 0.8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: const [
            VitalSignCard(
              title: 'BP',
              value: '140/90',
              unit: 'bpm.',
              valueColor: Colors.teal,
            ),
            VitalSignCard(
              title: 'PR',
              value: '78',
              unit: 'bpm.',
              valueColor: Colors.teal,
            ),
            VitalSignCard(
              title: 'RR',
              value: '20',
              unit: 'bpm.',
              valueColor: Colors.teal,
            ),
            VitalSignCard(
              title: 'SpO2',
              value: '99',
              unit: '%',
              valueColor: Colors.teal,
            ),
            VitalSignCard(
              title: 'BT',
              value: '36.7',
              unit: '°C',
              valueColor: Colors.teal,
            ),
            VitalSignCard(
              title: 'DTX',
              value: '123',
              unit: 'mg%',
              valueColor: Colors.teal,
            ),
            VitalSignCard(
              title: 'BW',
              value: '78',
              unit: 'Kg',
              valueColor: Colors.teal,
            ),
            VitalSignCard(
              title: 'H',
              value: '167',
              unit: 'cm',
              valueColor: Colors.teal,
            ),
          ],
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

  const VitalSignCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    this.valueColor = Colors.teal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: const TextStyle(fontSize: 10, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}
