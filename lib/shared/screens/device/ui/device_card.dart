//device/ui/device_card.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/screens/device/session/device_session.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.session,
    required this.onOpen,
    required this.onDisconnect,
  });

  final DeviceSession session;
  final VoidCallback onOpen;
  final VoidCallback onDisconnect;

  int? _tryInt(String? s) => s == null ? null : int.tryParse(s.trim());
  int? _validSpo2(String? s) {
    final n = _tryInt(s); if (n == null) return null; return (n >= 70 && n <= 100) ? n : null;
  }
  int? _validPr(String? s) {
    final n = _tryInt(s); if (n == null) return null; return (n >= 30 && n <= 250) ? n : null;
  }

  @override
  Widget build(BuildContext context) {
    final title = session.title;
    final id    = session.device.remoteId.str;
    final data  = session.latestData;
    final error = session.error;

    final spo2 = _validSpo2(data['spo2'] ?? data['SpO2'] ?? data['SPO2']);
    final pr   = _validPr (data['pr']   ?? data['PR']   ?? data['pulse']);

    final tempTxt = data['temp'] ?? data['temp_c'];
    final weight  = data['weight_kg'];
    final bmi     = data['bmi'];

    final mgdl = data['mgdl'];
    final mmol = data['mmol'];

    final sys = data['sys'] ?? data['systolic'];
    final dia = data['dia'] ?? data['diastolic'];
    final bpPulse = data['pul'] ?? data['PR'] ?? data['pr'] ?? data['pulse'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Icon(Icons.devices),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: onOpen, child: const Text('เปิด')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: onDisconnect, child: const Text('ตัดการเชื่อมต่อ')),
            ],
          ),
          const SizedBox(height: 4),
          Text('ID: $id', style: const TextStyle(color: Colors.black54)),
          const Divider(),

          if (error != null) ...[
            Text('ผิดพลาด: $error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 6),
          ],

          // Glucose
          if (mgdl != null || mmol != null) ...[
            const Text('Glucose', style: TextStyle(fontSize: 13, color: Colors.black54)),
            Text('${mgdl ?? '-'} mg/dL', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            if (mmol != null) Text('$mmol mmol/L', style: const TextStyle(fontSize: 16)),
            if (data['seq'] != null || data['ts'] != null)
              Text(
                '${data['seq'] != null ? 'seq: ${data['seq']}   ' : ''}'
                '${data['ts'] != null ? 'เวลา: ${data['ts']}' : ''}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(onPressed: session.gluPrev == null ? null : () => session.gluPrev!.call(), icon: const Icon(Icons.chevron_left), label: const Text('ก่อนหน้า')),
                OutlinedButton.icon(onPressed: session.gluNext == null ? null : () => session.gluNext!.call(), icon: const Icon(Icons.chevron_right), label: const Text('ถัดไป')),
                TextButton(onPressed: session.gluLast == null ? null : () => session.gluLast!.call(), child: const Text('ล่าสุด')),
                TextButton(onPressed: session.gluAll == null ? null : () => session.gluAll!.call(), child: const Text('ทั้งหมด')),
                TextButton(onPressed: session.gluCount == null ? null : () => session.gluCount!.call(), child: const Text('นับจำนวน')),
              ],
            ),
            if (data['racp_num'] != null || data['seq'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'รายการ: ${data['seq'] ?? '-'}'
                  '${data['racp_num'] != null ? ' / ${data['racp_num']}' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            const Divider(),
          ],

          // Weight
          if (weight != null) ...[
            const Text('Weight', style: TextStyle(fontSize: 13, color: Colors.black54)),
            Text('$weight kg', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            if (bmi != null) Text('BMI: $bmi', style: const TextStyle(fontSize: 16)),
            const Divider(),
          ],

          // BP
          if (sys != null && dia != null) ...[
            const Text('Blood Pressure', style: TextStyle(fontSize: 13, color: Colors.black54)),
            Row(children: [
              Text('$sys / $dia', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Text('mmHg'),
            ]),
            if (bpPulse != null) ...[
              const SizedBox(height: 6),
              Text('Pulse: $bpPulse bpm', style: const TextStyle(fontSize: 16)),
            ],
            const Divider(),
          ],

          // Temp (show only when no SpO2/PR block to avoid clutter)
          if (tempTxt != null && tempTxt.isNotEmpty && !(spo2 != null || pr != null)) ...[
            const Text('Temperature', style: TextStyle(fontSize: 13, color: Colors.black54)),
            Text('$tempTxt °C', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(),
          ],

          // SpO2/PR
          if (spo2 != null || pr != null) ...[
            Text('SpO₂: ${spo2?.toString() ?? '-'} %', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Pulse: ${pr?.toString() ?? '-'} bpm', style: const TextStyle(fontSize: 18)),
            const Divider(),
          ],

          // Other fields
          if (data.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries
                  .where((e) => !{
                        'weight_kg','bmi','impedance_ohm',
                        'spo2','SpO2','SPO2','pr','PR','pulse',
                        'temp','temp_c','temperature',
                        'mgdl','mmol','seq','ts','time_offset',
                        'racp','racp_num','src','raw',
                        'sys','systolic','dia','diastolic','pul','map',
                      }.contains(e.key))
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
            )
          else
            const Text('ยังไม่มีข้อมูลจากอุปกรณ์'),

          if (data['racp_num'] != null)
            Text('บันทึกในเครื่อง: ${data['racp_num']} รายการ', style: const TextStyle(fontSize: 12)),
          if (data['racp'] != null)
            Text('RACP: ${data['racp']}', style: const TextStyle(fontSize: 12)),
          if (data['src'] != null)
            Text('src: ${data['src']}', style: const TextStyle(fontSize: 12)),
          if (data['raw'] != null)
            Text('raw: ${data['raw']}', style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}