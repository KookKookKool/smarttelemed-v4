import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/core/device/vitals.dart';
// เพิ่ม import
import 'package:flutter/foundation.dart'; // << ใหม่
import 'package:smarttelemed_v4/core/device/device_hub.dart'; // << ใหม่


// =============== หน้าแบบ Section (ฝังใน ScrollView อื่น) ===============
class DeviceDashboardSection extends StatefulWidget {
  const DeviceDashboardSection({Key? key}) : super(key: key);
  @override
  State<DeviceDashboardSection> createState() => _DeviceDashboardSectionState();
}

class _DeviceDashboardSectionState extends State<DeviceDashboardSection> {
  late final Listenable _merged; // << ใหม่

  Future<void> _resetAll(BuildContext context) async {
  final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ยืนยันการล้างค่า'),
          content: const Text('ต้องการล้างค่าค่าสัญญาณชีพทั้งหมดหรือไม่?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ยืนยัน')),
          ],
        ),
      ) ??
      false;
  if (!ok) return;

// ล้างค่าทั้งหมด
  for (final k in ['bp', 'pr', 'rr', 'spo2', 'bt', 'dtx', 'bw', 'h']) {
    try { Vitals.I.clear(k); } catch (_) {}
  }

  if (mounted) {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ล้างค่าค่าสัญญาณชีพทั้งหมดแล้ว')),
    );
  }
}

  @override
  void initState() {
    super.initState();
    // รวมแหล่งแจ้งเตือนการเปลี่ยนแปลง: วัดเมื่อไหร่ก็เด้ง
    _merged = Listenable.merge([Vitals.I, DeviceHub.I]); // << ใหม่
    // Vitals.I.ensure();
    Future(() async {
      await Vitals.I.ensure();
      for (final k in ['bp','pr','rr','spo2','bt','dtx','bw','h']) {
        try { Vitals.I.unlock(k); } catch (_) {}
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _merged, // << เดิมคือ Vitals.I
      // animation: Vitals.I,
      builder: (context, _) {
        if (!Vitals.I.ready) {
          return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
        }
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: LayoutBuilder(
                  builder: (context, c) {
                    const cols = 4;
                    const gap = 20.0;
                    final cellW = (c.maxWidth - (cols - 1) * gap) / cols;
                    final cellH = cellW * 0.95;
                    final s = (cellW / 230).clamp(0.45, 1.0);
                    final headSize = (34.0 * s).clamp(18.0, 34.0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 4 * s, bottom: 8 * s, right: 4 * s),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'ค่าสัญญาณชีพ',
                                  style: TextStyle(fontSize: headSize, fontWeight: FontWeight.w800),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _resetAll(context),
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('Reset ทั้งหมด'),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _bpCard(cellW, cellH, s),
                            // CHANGED: locked=false ทุกการ์ด
                            _numCard('PR',
                                value: Vitals.I.pr?.toString() ?? '--',
                                unit: 'bpm.',
                                locked: false,
                                w: cellW, h: cellH, s: s,
                                onTap: () => _editNumber(context, 'PR', Vitals.I.pr?.toString(),
                                    (v) => Vitals.I.putPr(int.parse(v)),
                                    onUnlock: () {}, onClear: () => Vitals.I.clear('pr'))),
                            _numCard('RR',
                                value: Vitals.I.rr?.toString() ?? '--',
                                unit: 'bpm.',
                                locked: false,
                                w: cellW, h: cellH, s: s,
                                onTap: () => _editNumber(context, 'RR', Vitals.I.rr?.toString(),
                                    (v) => Vitals.I.putRr(int.parse(v)),
                                    onUnlock: () {}, onClear: () => Vitals.I.clear('rr'))),
                            _numCard('SpO2',
                                value: Vitals.I.spo2?.toString() ?? '--',
                                unit: '%',
                                locked: false,
                                w: cellW, h: cellH, s: s,
                                onTap: () => _editNumber(context, 'SpO2', Vitals.I.spo2?.toString(),
                                    (v) => Vitals.I.putSpo2(int.parse(v)),
                                    onUnlock: () {}, onClear: () => Vitals.I.clear('spo2'))),
                            _numCard('BT',
                                value: Vitals.I.bt != null ? Vitals.I.bt!.toStringAsFixed(1) : '--.--',
                                unit: '°C',
                                locked: false,
                                w: cellW, h: cellH, s: s,
                                onTap: () => _editDecimal(context, 'BT (°C)', Vitals.I.bt?.toString(),
                                    (v) => Vitals.I.putBt(double.parse(v)),
                                    onUnlock: () {}, onClear: () => Vitals.I.clear('bt'))),
                            _numCard('DTX',
                                value: Vitals.I.dtx != null ? Vitals.I.dtx!.toStringAsFixed(0) : '--',
                                unit: 'mg%.',
                                locked: false,
                                w: cellW, h: cellH, s: s,
                                onTap: () => _editDecimal(context, 'DTX (mg%)', Vitals.I.dtx?.toString(),
                                    (v) => Vitals.I.putDtx(double.parse(v)),
                                    onUnlock: () {}, onClear: () => Vitals.I.clear('dtx'))),
                            _numCard('BW',
                                value: Vitals.I.bw != null ? Vitals.I.bw!.toStringAsFixed(1) : '--',
                                unit: 'Kg.',
                                locked: false,
                                w: cellW, h: cellH, s: s,
                                onTap: () => _editDecimal(context, 'น้ำหนัก (Kg)', Vitals.I.bw?.toString(),
                                    (v) => Vitals.I.putBw(double.parse(v)),
                                    onUnlock: () {}, onClear: () => Vitals.I.clear('bw'))),
                            _numCard('H',
                                value: Vitals.I.h != null ? Vitals.I.h!.toStringAsFixed(1) : '--',
                                unit: 'cm.',
                                locked: false,
                                w: cellW, h: cellH, s: s,
                                onTap: () => _editDecimal(context, 'ส่วนสูง (cm)', Vitals.I.h?.toString(),
                                    (v) => Vitals.I.putH(double.parse(v)),
                                    onUnlock: () {}, onClear: () => Vitals.I.clear('h'))),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- cards ----------
  Widget _bpCard(double w, double h, double s) {
    final sys = Vitals.I.bpSys != null ? Vitals.I.bpSys.toString() : '--';
    final dia = Vitals.I.bpDia != null ? Vitals.I.bpDia.toString() : '--';
    return _cardShell(
      title: 'BP', unit: 'bpm.',
      locked: false, // CHANGED: ไม่ล็อก
      w: w, h: h, s: s,
      onTap: () => _editBp(context),
      middle: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _valueText(sys, 42 * s), SizedBox(width: 4 * s),
          _slashText(42 * s), SizedBox(width: 4 * s),
          _valueText(dia, 42 * s),
        ],
      ),
    );
  }


  Widget _numCard(String title, {
    required String value, required String unit, required bool locked,
    required double w, required double h, required double s, required VoidCallback onTap,
  }) {
    return _cardShell(
      title: title, unit: unit, locked: locked, w: w, h: h, s: s, onTap: onTap,
      middle: _valueText(value, 42 * s),
    );
  }

  Widget _cardShell({
    required String title, required String unit, required bool locked,
    required double w, required double h, required double s,
    required Widget middle, required VoidCallback onTap,
  }) {
    final pad = EdgeInsets.fromLTRB(18 * s, 16 * s, 18 * s, 12 * s);
    final radius = 24.0 * s;
    final titleSize = 28.0 * s;
    final unitSize = 22.0 * s;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Container(
          width: w, height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: locked ? const Color(0xFF00BFA6) : Colors.transparent, width: 1),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 8))],
          ),
          padding: pad,
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w700)),
                   // CHANGED: locked=false → ไอคอนไม่ถูกแสดงโดยปริยาย
                    if (locked) SizedBox(width: 6 * s),
                    if (locked) Icon(Icons.lock, size: 18 * s, color: const Color(0xFF00BFA6)),
                  ],
                ),
              ),
              SizedBox(height: 12 * s),
              Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: middle))),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(unit, style: TextStyle(fontSize: unitSize, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _valueText(String t, double size) => Text(
        t, textAlign: TextAlign.center,
        style: TextStyle(fontSize: size, letterSpacing: 2, fontWeight: FontWeight.w700, color: const Color(0xFF1DB7A6)),
      );

  Widget _slashText(double size) => Text('/', style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: const Color(0xFF1DB7A6)));

  // ---------- editors ----------
  Future<void> _editBp(BuildContext context) async {
    final sysCtrl = TextEditingController(text: Vitals.I.bpSys?.toString() ?? '');
    final diaCtrl = TextEditingController(text: Vitals.I.bpDia?.toString() ?? '');
    await _showEditSheet(
      context,
      title: 'ความดัน (SYS/DIA)',
      fields: [
        _numField('SYS', sysCtrl), const SizedBox(width: 12),
        _numField('DIA', diaCtrl),
      ],
      locked: Vitals.I.lBp,
      onSave: () async {
        final s = int.tryParse(sysCtrl.text);
        final d = int.tryParse(diaCtrl.text);
        if (s != null && d != null) { await Vitals.I.putBp(sys: s, dia: d); }
      },
      onUnlock: () => Vitals.I.unlock('bp'),
      onClear: () => Vitals.I.clear('bp'),
    );
  }

  Future<void> _editNumber(BuildContext context, String title, String? current,
      Function(String) onSave, {required VoidCallback onUnlock, required VoidCallback onClear}) async {
    final c = TextEditingController(text: current ?? '');
    await _showEditSheet(
      context,
      title: title,
      fields: [_numField(title, c)],
      locked: false, // CHANGED
      onSave: () { if (c.text.trim().isNotEmpty) onSave(c.text.trim()); },
      onUnlock: () {}, // CHANGED
      onClear: onClear,
    );
  }

  Future<void> _editDecimal(BuildContext context, String title, String? current,
      Function(String) onSave, {required VoidCallback onUnlock, required VoidCallback onClear}) async {
    final c = TextEditingController(text: current ?? '');
    await _showEditSheet(
      context,
      title: title,
      fields: [_decField(title, c)],
      locked: false, // CHANGED
      onSave: () { if (c.text.trim().isNotEmpty) onSave(c.text.trim()); },
      onUnlock: () {}, // CHANGED
      onClear: onClear,
    );
  }

  // CHANGED: ยกเลิกระบบล็อกทั้งหมด
  bool _isLocked(String title) => false;

  Future<void> _showEditSheet(BuildContext context, {
    required String title, required List<Widget> fields, required bool locked,
    required VoidCallback onSave, required VoidCallback onUnlock, required VoidCallback onClear,
  }) async {
    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: fields),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: onClear, child: const Text('ล้างค่า'))),
            const SizedBox(width: 8),
            // CHANGED: ไม่แสดงปุ่มปลดล็อก เพราะ locked=false เสมอ
            // if (locked) Expanded(child: OutlinedButton(onPressed: onUnlock, child: const Text('ปลดล็อก'))),
            Expanded(child: ElevatedButton(onPressed: () { onSave(); Navigator.pop(context); }, child: const Text('บันทึก'))),
          ]),
        ]),
      ),
    );
  }

 Widget _numField(String label, TextEditingController c) => Expanded(
    child: TextField(
      controller: c, keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    ),
  );

  Widget _decField(String label, TextEditingController c) => Expanded(
    child: TextField(
      controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    ),
  );
}