// lib/core/device/dashboard/device_hub.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // ChangeNotifier / Listenable
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

// โมดูลใหม่ที่แยกไว้
import 'package:smarttelemed_v4/core/device/session/device_session.dart';
import 'package:smarttelemed_v4/core/device/session/pick_parser.dart';

// ที่เก็บค่าสัญญาณชีพของคุณ (มี putBp/putPr/... อยู่แล้ว)
import 'package:smarttelemed_v4/core/device/dashboard/vitals.dart';

/// DeviceHub: ตัวกลางเชื่อม BLE -> DeviceSession -> Vitals
/// - เป็น ChangeNotifier (Listenable) เพื่อให้ DeviceDashboardSection ฟังร่วมกับ Vitals.I ได้
/// - auto-start เองตั้งแต่ถูก import (ไม่ต้องแก้ UI)
class DeviceHub extends ChangeNotifier {
  DeviceHub._internal() {
    // เริ่มระบบแบบอัตโนมัติทันทีที่ถูกโหลด ไม่รอ UI เรียก
    scheduleMicrotask(() => ensure());
  }

  static final DeviceHub I = DeviceHub._internal();

  final Map<String, DeviceSession> _sessions = {};
  Timer? _poll;
  bool _started = false;
  bool _refreshing = false;

  /// รองรับโค้ดเก่าที่เรียก ensureStarted()
  Future<void> ensureStarted() => ensure();

  /// เริ่มระบบ (idempotent) — เรียกซ้ำได้โดยไม่กระทบ
  Future<void> ensure() async {
    if (_started) return;
    _started = true;

    await _refreshConnected(); // ครั้งแรก
    _poll = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_refreshing) return;
      _refreshing = true;
      try {
        await _refreshConnected();
      } finally {
        _refreshing = false;
      }
    });
  }

  Future<void> _refreshConnected() async {
    try {
      final devs = await fbp.FlutterBluePlus.connectedDevices;

      // เพิ่ม session สำหรับ device ใหม่
      for (final d in devs) {
        final id = d.remoteId.str;
        if (!_sessions.containsKey(id)) {
          await _createAndStartSession(d);
        }
      }

      // เก็บกวาด session ที่หลุดการเชื่อมต่อไปแล้ว
      final alive = devs.map((e) => e.remoteId.str).toSet();
      final stale = _sessions.keys.where((k) => !alive.contains(k)).toList();
      for (final id in stale) {
        await _sessions[id]?.dispose();
        _sessions.remove(id);
      }
    } catch (_) {
      // เงียบไว้: dashboard ไม่ควรเด้ง error banner จาก hub
    } finally {
      // แจ้งเปลี่ยนแปลง (จำนวน session/สถานะรวม)
      notifyListeners();
    }
  }

  Future<void> _createAndStartSession(BluetoothDevice d) async {
    final id = d.remoteId.str;

    // หลีกเลี่ยงการอ้างถึงตัวแปร 'sess' ระหว่างกำลังกำหนดค่า
    final sess = DeviceSession(
      device: d,
      onUpdate: () {
        final s = _sessions[id];
        if (s != null) {
          _applySessionToVitals(s);
        }
        notifyListeners();
      },
      onError: (_) {
        // ไม่รบกวน UI—Vitals จะยังคงค่าล่าสุดไว้
        notifyListeners();
      },
      onDisconnected: () async {
        await _refreshConnected();
      },
    );

    _sessions[id] = sess;
    await sess.start(pickParser: pickParser);
  }

  // ---------- Mapping: Session.latestData -> Vitals ----------
  void _applySessionToVitals(DeviceSession s) {
    final m = s.latestData;
    if (m.isEmpty) return;

    // Helpers
    int? _asInt(String? v) => v == null ? null : int.tryParse(v.trim());
    double? _asDouble(String? v) => v == null ? null : double.tryParse(v.trim());

    bool _in(int x, int lo, int hi) => x >= lo && x <= hi;
    bool _inD(double x, double lo, double hi) => x >= lo && x <= hi;

    // ----- Blood Pressure -----
    final sys = _asInt(m['sys'] ?? m['systolic']);
    final dia = _asInt(m['dia'] ?? m['diastolic']);
    if (sys != null && dia != null && _in(sys, 60, 260) && _in(dia, 30, 200)) {
      Vitals.I.putBp(sys: sys, dia: dia);
    }

    // Pulse (PR) — จาก oximeter/bp
    final pr = _asInt(m['pul'] ?? m['PR'] ?? m['pr'] ?? m['pulse']);
    if (pr != null && _in(pr, 30, 250)) {
      Vitals.I.putPr(pr);
    }

    // SpO₂
    final spo2 = _asInt(m['spo2'] ?? m['SpO2'] ?? m['SPO2']);
    if (spo2 != null && _in(spo2, 70, 100)) {
      Vitals.I.putSpo2(spo2);
    }

    // Temperature (°C) — เกราะกัน °C จาก YX110 อยู่ใน DeviceSession แล้ว
    final src = (m['src'] ?? '').toLowerCase();
    final temp = _asDouble(m['temp'] ?? m['temp_c']);
    if (temp != null && !src.contains('yx110') && _inD(temp, 30.0, 45.0)) {
      Vitals.I.putBt(temp);
    }

    // Glucose → ใช้ช่อง DTX (หน่วย mg% บน UI แต่เราใส่ mg/dL เดิม)
    final mgdl = _asDouble(m['mgdl'] ?? m['mgdL']);
    if (mgdl != null && _inD(mgdl, 10, 1000)) {
      Vitals.I.putDtx(mgdl); // แผง DTX จะโชว์เป็น mg% ตาม UI ของคุณ
    }

    // Weight (kg)
    final bw = _asDouble(m['weight_kg'] ?? m['weight'] ?? m['bw']);
    if (bw != null && _inD(bw, 1, 400)) {
      Vitals.I.putBw(bw);
    }

    // Height (cm) — เผื่อมีอุปกรณ์ส่งความสูง
    final h = _asDouble(m['height_cm'] ?? m['h']);
    if (h != null && _inD(h, 30, 250)) {
      Vitals.I.putH(h);
    }
  }

  // ---------- Public helpers (optional) ----------
  int get connectedCount => _sessions.length;

  Future<void> disposeHub() async {
    _poll?.cancel(); _poll = null;
    for (final s in _sessions.values) { await s.dispose(); }
    _sessions.clear();
  }
}
