// device_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// หน้ารับค่าจาก Pulse Oximeter
/// - รองรับอุปกรณ์ 2 แบบที่คุณใช้งานจริง:
///   1) Yuwell : characteristic tail = ffe4  (vendor-specific)
///      เฟรมตัวอย่าง: fe 0a 55 00 52 5f 17 70 cf 64
///      => pulse = data[4], spo2 = data[5]
///   2) อุปกรณ์ที่ใช้ UUID เต็ม: cdeacb81-5235-4c07-8846-93a37ee6b86d (vendor-specific)
///      บ่อยครั้งส่งเฟรม "idle" เป็น 0x2d ('-') ซ้ำ ๆ จนเริ่มวัดจริง
///
/// ฟังก์ชันหลัก:
///  - ค้นหา services/characteristics
///  - subscribe characteristic ที่ notify ได้ (เจาะจง ffe4 และ service ที่มี cdeacb81… ก่อน)
///  - แปลง payload เป็น SpO2/Pulse แบบ heuristic
///  - แสดง RAW ต่อ characteristic เพื่อดีบัก
class DevicePage extends StatefulWidget {
  final BluetoothDevice device;
  const DevicePage({Key? key, required this.device}) : super(key: key);

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  // เป้าหมายที่รู้จัก
  static const String kTailFfe4 = 'ffe4';
  static const String kFullCustom = 'cdeacb81-5235-4c07-8846-93a37ee6b86d';

  bool _busy = false;
  String? _error;

  List<BluetoothService> _services = [];
  final List<BluetoothCharacteristic> _subs = [];
  final List<StreamSubscription<List<int>>> _valueSubs = [];

  // readings
  double? _spo2;
  double? _pulse;
  DateTime? _ts;

  // raw cache
  final Map<Guid, List<int>> _lastRawByChar = {};

  @override
  void initState() {
    super.initState();
    _discoverAndBind();
  }

  @override
  void dispose() {
    for (final s in _valueSubs) {
      s.cancel();
    }
    _disableAllNotifySafely();
    super.dispose();
  }

  Future<void> _discoverAndBind() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // ให้แน่ใจว่าต่อสำเร็จ
      final st = await widget.device.connectionState.first;
      if (st != BluetoothConnectionState.connected) {
        await widget.device.connect(timeout: const Duration(seconds: 10));
      }

      _services = await widget.device.discoverServices();

      // 1) ถ้าพบ characteristic = cdeacb81… ให้ subscribe "ทุก notify-char ใน service เดียวกัน" ก่อน
      final targets = <BluetoothCharacteristic>[];
      Guid? cdeaServiceUuid;
      for (final s in _services) {
        for (final c in s.characteristics) {
          if (c.uuid.str.toLowerCase() == kFullCustom) {
            cdeaServiceUuid = s.uuid;
            break;
          }
        }
        if (cdeaServiceUuid != null) break;
      }
      if (cdeaServiceUuid != null) {
        final svc = _services.firstWhere((s) => s.uuid == cdeaServiceUuid);
        for (final c in svc.characteristics) {
          if (c.properties.notify) targets.add(c);
        }
      }

      // 2) เพิ่มเป้าหมาย tail = ffe4 (เช่น Yuwell)
      for (final s in _services) {
        for (final c in s.characteristics) {
          if (!c.properties.notify) continue;
          final u = c.uuid.str.toLowerCase();
          final tail = u.length >= 4 ? u.substring(u.length - 4) : u;
          if (tail == kTailFfe4 && !targets.contains(c)) {
            targets.add(c);
          }
        }
      }

      // 3) ถ้ายังไม่เจออะไรเลย ให้ subscribe ทุก notify ทั้งอุปกรณ์ (เพื่อดู RAW)
      if (targets.isEmpty) {
        for (final s in _services) {
          for (final c in s.characteristics) {
            if (c.properties.notify) targets.add(c);
          }
        }
        if (targets.isEmpty) {
          setState(() {
            _error = 'ไม่พบ characteristic แบบ Notify บนอุปกรณ์นี้';
          });
        }
      }

      await _subscribeMany(targets);
    } catch (e) {
      setState(() => _error = 'ค้นหาบริการ/สมัครรับค่าไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _subscribeMany(List<BluetoothCharacteristic> chars) async {
    await _disableAllNotifySafely();
    _subs.clear();
    for (final s in _valueSubs) {
      await s.cancel();
    }
    _valueSubs.clear();
    _lastRawByChar.clear();

    for (final ch in chars) {
      try {
        await ch.setNotifyValue(true);
        _subs.add(ch);

        final sub = ch.lastValueStream.listen((data) {
          // เก็บ raw
          _lastRawByChar[ch.uuid] = List<int>.from(data);

          // อัปเดต readings
          _tryParseAndUpdate(ch.uuid, data);

          if (mounted) setState(() {});
        });
        _valueSubs.add(sub);

        // บางรุ่นต้อง read ครั้งแรกเพื่อ trigger notify
        try {
          await ch.read();
        } catch (_) {}
      } catch (e) {
        _error = 'เปิด notify ไม่ได้ที่ ${_shortUuid(ch.uuid)}: $e';
      }
    }
  }

  Future<void> _disableAllNotifySafely() async {
    for (final ch in _subs) {
      try {
        await ch.setNotifyValue(false);
      } catch (_) {}
    }
  }

  // -------------------- Parsing --------------------
  void _tryParseAndUpdate(Guid uuid, List<int> data) {
    if (data.isEmpty) return;

    // 0) เพิกเฉยเฟรมว่าง เช่น 0x2d ('-') ซ้ำ ๆ หรือค่าซ้ำทั้งหมด
    final allSame = data.every((b) => b == data[0]);
    final mostlyDash = data.where((b) => b == 0x2d).length >= (data.length * 0.8);
    if (allSame || mostlyDash) {
      return; // ยังไม่อัปเดต จนกว่าจะมีเฟรมจริง
    }

    // A) เฟรม vendor ที่ขึ้นต้น 0xFE (เช่น Yuwell)
    // ตัวอย่าง: fe 0a 55 00 52 5f 17 70 cf 64
    // index:     0  1  2  3  4  5  6  7  8  9
    // pulse = data[4], SpO2 = data[5]
    if (data.length >= 6 && data[0] == 0xFE) {
      final spo2Byte = data[5];
      final pulseByte = data[4];

      // เผื่อบางเฟรมใช้ pulse 16-bit LE ที่ index 2..3
      int pulse16 = data[2] | ((data.length > 3 ? data[3] : 0) << 8);
      final usePulse = _looksValidPulse(pulseByte)
          ? pulseByte.toDouble()
          : (_looksValidPulse(pulse16) ? pulse16.toDouble() : null);

      if (_looksValidSpo2(spo2Byte) && usePulse != null) {
        _setReading(spo2Byte.toDouble(), usePulse);
        return;
      }
    }

    // B) ASCII เช่น "98,75" หรือ "SpO2=98,P=75"
    final ascii = _maybeAscii(data);
    if (ascii != null) {
      final parsed = _parseAsciiPayload(ascii);
      if (parsed != null) {
        _setReading(parsed.spo2, parsed.pulse);
        return;
      }
    }

    // C) โครงง่าย: [spo2(uint8), pulse(uint8), ...]
    if (data.length >= 2) {
      final v1 = data[0], v2 = data[1];
      if (_looksValidSpo2(v1) && _looksValidPulse(v2)) {
        _setReading(v1.toDouble(), v2.toDouble());
        return;
      }
    }

    // D) Header 0xAA: [0xAA, len, spo2, pulse]
    if (data.length >= 4 && data[0] == 0xAA) {
      final s = data[2], p = data[3];
      if (_looksValidSpo2(s) && _looksValidPulse(p)) {
        _setReading(s.toDouble(), p.toDouble());
        return;
      }
    }

    // E) Header 0x55 0xAA
    if (data.length >= 6 && data[0] == 0x55 && data[1] == 0xAA) {
      final s = data[2], p = data[3];
      if (_looksValidSpo2(s) && _looksValidPulse(p)) {
        _setReading(s.toDouble(), p.toDouble());
        return;
      }
    }

    // F) SFLOAT layout (คล้ายมาตรฐาน): [flags?, spo2 sfloat, pulse sfloat]
    if (data.length >= 6) {
      final s = _decodeSfloat16(data[2], data[3]);
      final p = _decodeSfloat16(data[4], data[5]);
      if (s != null && p != null && _looksValidSpo2(s) && _looksValidPulse(p)) {
        _setReading(s, p);
        return;
      }
    }
  }

  void _setReading(double? newSpo2, double? newPulse) {
    bool changed = false;
    if (newSpo2 != null && newSpo2 != _spo2) {
      _spo2 = newSpo2;
      changed = true;
    }
    if (newPulse != null && newPulse != _pulse) {
      _pulse = newPulse;
      changed = true;
    }
    if (changed) _ts = DateTime.now();
  }

  bool _looksValidSpo2(num v) => v >= 50 && v <= 100;
  bool _looksValidPulse(num v) => v >= 20 && v <= 250;

  String? _maybeAscii(List<int> data) {
    // ไบต์ต้อง printable เกือบทั้งหมด
    if (data.any((b) => b < 0x20 || b > 0x7E)) return null;
    try {
      final s = String.fromCharCodes(data);
      if (s.contains(',') || s.toLowerCase().contains('spo') || s.contains('=')) {
        return s.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// รองรับ: "98,75", "SpO2=98,P=75", "SPO2:98 PULSE:75"
  _Reading? _parseAsciiPayload(String s) {
    final lower = s.toLowerCase();

    // รูปแบบ "98,75"
    final csv = lower.split(',');
    if (csv.length >= 2) {
      final sp = double.tryParse(csv[0].replaceAll(RegExp(r'[^0-9.]'), ''));
      final pr = double.tryParse(csv[1].replaceAll(RegExp(r'[^0-9.]'), ''));
      if (sp != null && pr != null && _looksValidSpo2(sp) && _looksValidPulse(pr)) {
        return _Reading(spo2: sp, pulse: pr);
      }
    }

    // คีย์เวิร์ด
    final spMatch = RegExp(r'(spo2|sp):?\s*([0-9]+(\.[0-9]+)?)').firstMatch(lower);
    final prMatch = RegExp(r'(pulse|pr|hr):?\s*([0-9]+(\.[0-9]+)?)').firstMatch(lower);
    if (spMatch != null && prMatch != null) {
      final sp = double.tryParse(spMatch.group(2)!);
      final pr = double.tryParse(prMatch.group(2)!);
      if (sp != null && pr != null && _looksValidSpo2(sp) && _looksValidPulse(pr)) {
        return _Reading(spo2: sp, pulse: pr);
      }
    }

    return null;
  }

  /// IEEE‑11073 16‑bit SFLOAT: value = mantissa(12-bit signed) * 10^exponent(4-bit signed)
  double? _decodeSfloat16(int b0, int b1) {
    int raw = (b1 << 8) | b0;
    int mantissa = raw & 0x0FFF;
    int exponent = (raw & 0xF000) >> 12;
    if ((mantissa & 0x0800) != 0) mantissa |= ~0x0FFF;
    if ((exponent & 0x8) != 0) exponent |= ~0xF;
    final val = mantissa * math.pow(10, exponent);
    return val.toDouble();
  }

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

  String _shortUuid(Guid u) {
    final s = u.str.toLowerCase();
    return s.length >= 4 ? s.substring(s.length - 4) : s;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.device.platformName.isNotEmpty
        ? widget.device.platformName
        : widget.device.remoteId.str;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pulse Oximeter • $name'),
        actions: [
          IconButton(
            tooltip: 'ค้นหา/สมัครรับค่าใหม่',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _busy = true;
                _error = null;
                _spo2 = null;
                _pulse = null;
                _ts = null;
                _lastRawByChar.clear();
              });
              await _discoverAndBind();
            },
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),

                  const Text('ค่าที่ตีความได้',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _metric('SpO₂', _spo2 != null ? '${_spo2!.toStringAsFixed(1)} %' : '-'),
                      const SizedBox(width: 12),
                      _metric('Pulse', _pulse != null ? '${_pulse!.toStringAsFixed(0)} bpm' : '-'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('อัปเดตล่าสุด: ${_ts != null ? _ts!.toLocal().toString().split(".").first : "-"}'),

                  const Divider(height: 32),

                  const Text('RAW ต่อ characteristic (ล่าสุด)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Expanded(
                    child: _lastRawByChar.isEmpty
                        ? const Text('ยังไม่มีข้อมูล (รออุปกรณ์ส่งค่า/ลองกด Refresh)')
                        : ListView(
                            children: _lastRawByChar.entries.map((e) {
                              final uuid = e.key;
                              final raw = e.value;
                              return Card(
                                child: ListTile(
                                  title: Text('Char ${_shortUuid(uuid)} • ${uuid.str}'),
                                  subtitle: Text(_hex(raw)),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _metric(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reading {
  final double spo2;
  final double pulse;
  _Reading({required this.spo2, required this.pulse});
}
