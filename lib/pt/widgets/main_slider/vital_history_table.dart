// lib/screens/main_pt/widgets/main_slider/vital_history_table.dart
import 'package:flutter/material.dart';

class VitalHistoryTable extends StatelessWidget {
  const VitalHistoryTable({Key? key}) : super(key: key);

  TableRow _header() => const TableRow(
        decoration: BoxDecoration(color: Color(0xFFF4F6F8)),
        children: [
          _Th('Date\n(DD/MM/YY)'), _Th('BP\n(mmHg)'), _Th('PR\n(bpm)'),
          _Th('RR\n(bpm)'), _Th('SpO2\n(%)'), _Th('BT\n(°C)'),
        ],
      );

  TableRow _data(List<String> cols) =>
      TableRow(decoration: const BoxDecoration(color: Colors.white), children: cols.map((e) => _Td(e)).toList());

  @override
  Widget build(BuildContext context) {
    final rows = <TableRow>[
      _header(),
      _data(const ['11/08/68', '140/90', '76', '20', '100', '36.7']),
      _data(const ['', '', '', '', '', '']),
      _data(const ['', '', '', '', '', '']),
      _data(const ['', '', '', '', '', '']),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('ประวัติค่าสัญญาณชีพ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(.9),
              3: FlexColumnWidth(.9),
              4: FlexColumnWidth(.9),
              5: FlexColumnWidth(1.0),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(text, textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)));
}

class _Td extends StatelessWidget {
  final String text;
  const _Td(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: .9)),
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
      );
}
