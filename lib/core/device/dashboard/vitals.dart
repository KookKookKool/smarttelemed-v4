// lib/core/device/vitals.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Vitals extends ChangeNotifier {
  Vitals._();
  static final Vitals I = Vitals._();

  SharedPreferences? _prefs;
  bool get ready => _prefs != null;

  // ─── values ───
  int? bpSys, bpDia, pr, rr, spo2;
  double? bt, dtx, bw, h;

  // ─── locks (true = ไม่รับค่าใหม่ จนกว่าจะ unlock) ───
  bool lBp = false, lPr = false, lRr = false, lSpo2 = false, lBt = false, lDtx = false, lBw = false, lH = false;

  // ─── debounce save เพื่อไม่ให้เขียน prefs ถี่เกินไประหว่างสตรีม ───
  Timer? _saveDebounce;
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 120), _save);
  }

  Future<void> ensure() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    final p = _prefs!;
    bpSys = p.getInt('v.bpSys');
    bpDia = p.getInt('v.bpDia');
    pr    = p.getInt('v.pr');
    rr    = p.getInt('v.rr');
    spo2  = p.getInt('v.spo2');
    bt    = p.getDouble('v.bt');
    dtx   = p.getDouble('v.dtx');
    bw    = p.getDouble('v.bw');
    h     = p.getDouble('v.h');

    lBp   = p.getBool('l.bp')   ?? false;
    lPr   = p.getBool('l.pr')   ?? false;
    lRr   = p.getBool('l.rr')   ?? false;
    lSpo2 = p.getBool('l.spo2') ?? false;
    lBt   = p.getBool('l.bt')   ?? false;
    lDtx  = p.getBool('l.dtx')  ?? false;
    lBw   = p.getBool('l.bw')   ?? false;
    lH    = p.getBool('l.h')    ?? false;

    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;

    Future setV(String k, Object? v) async {
      if (v == null) { await p.remove(k); return; }
      if (v is int)    await p.setInt(k, v);
      if (v is double) await p.setDouble(k, v);
      if (v is bool)   await p.setBool(k, v);
    }

    await setV('v.bpSys', bpSys); await setV('v.bpDia', bpDia);
    await setV('v.pr', pr);       await setV('v.rr', rr);
    await setV('v.spo2', spo2);   await setV('v.bt', bt);
    await setV('v.dtx', dtx);     await setV('v.bw', bw);
    await setV('v.h', h);

    await setV('l.bp', lBp);   await setV('l.pr', lPr);
    await setV('l.rr', lRr);   await setV('l.spo2', lSpo2);
    await setV('l.bt', lBt);   await setV('l.dtx', lDtx);
    await setV('l.bw', lBw);   await setV('l.h', lH);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Updaters
  // - fromDevice: ใช้บอกว่าได้มาจากอุปกรณ์ (ไว้เผื่อ logging ภายนอก ถ้าต้องการ)
  // - finalize  : "จบการวัดแล้ว" → อัปเดต + ตั้งล็อกค่านั้น
  // - ขณะยังไม่ล็อก: อนุญาตให้อัปเดตต่อเนื่องเสมอ (แม้จะ fromDevice)
  // - เมื่อล็อกแล้ว: จะรับค่าใหม่เฉพาะกรณี finalize=true (ทับค่าเดิม) หรือปลดล็อกก่อน
  // ──────────────────────────────────────────────────────────────────────

  Future<void> putBp({
    int? sys,
    int? dia,
    int? pulse,
    bool fromDevice = false,
    bool finalize = false,
  }) async {
    // BP
    if (sys != null && dia != null) {
      if (!lBp || finalize) {
        bpSys = sys;
        bpDia = dia;
        if (finalize) lBp = true;
      }
    }
    // PR มากับเครื่องวัดความดัน
    if (pulse != null) {
      if (!lPr || finalize) {
        pr = pulse;
        if (finalize) lPr = true;
      }
    }
    _scheduleSave();
    notifyListeners();
  }

  Future<void> putSpo2(int v, {bool fromDevice = false, bool finalize = false}) async {
    if (!lSpo2 || finalize) {
      spo2 = v;
      if (finalize) lSpo2 = true;
      _scheduleSave();
      notifyListeners();
    }
  }

  Future<void> putPr(int v, {bool fromDevice = false, bool finalize = false}) async {
    if (!lPr || finalize) {
      pr = v;
      if (finalize) lPr = true;
      _scheduleSave();
      notifyListeners();
    }
  }

  Future<void> putBt(double v, {bool fromDevice = false, bool finalize = false}) async {
    if (!lBt || finalize) {
      bt = v;
      if (finalize) lBt = true;
      _scheduleSave();
      notifyListeners();
    }
  }

  Future<void> putDtx(num v, {bool fromDevice = false, bool finalize = false}) async {
    if (!lDtx || finalize) {
      dtx = v.toDouble();
      if (finalize) lDtx = true;
      _scheduleSave();
      notifyListeners();
    }
  }

  Future<void> putBw(double v, {bool fromDevice = false, bool finalize = false}) async {
    if (!lBw || finalize) {
      bw = v;
      if (finalize) lBw = true;
      _scheduleSave();
      notifyListeners();
    }
  }

  Future<void> putH(double v, {bool fromDevice = false, bool finalize = false}) async {
    if (!lH || finalize) {
      h = v;
      if (finalize) lH = true;
      _scheduleSave();
      notifyListeners();
    }
  }

  Future<void> putRr(int v, {bool fromDevice = false, bool finalize = false}) async {
    if (!lRr || finalize) {
      rr = v;
      if (finalize) lRr = true;
      _scheduleSave();
      notifyListeners();
    }
  }

  // ─── lock / clear ───
  Future<void> unlock(String key) async {
    switch (key) {
      case 'bp': lBp = false; break;
      case 'pr': lPr = false; break;
      case 'rr': lRr = false; break;
      case 'spo2': lSpo2 = false; break;
      case 'bt': lBt = false; break;
      case 'dtx': lDtx = false; break;
      case 'bw': lBw = false; break;
      case 'h': lH = false; break;
    }
    _scheduleSave();
    notifyListeners();
  }

  Future<void> clear(String key) async {
    switch (key) {
      case 'bp': bpSys = null; bpDia = null; break;
      case 'pr': pr = null; break;
      case 'rr': rr = null; break;
      case 'spo2': spo2 = null; break;
      case 'bt': bt = null; break;
      case 'dtx': dtx = null; break;
      case 'bw': bw = null; break;
      case 'h': h = null; break;
    }
    _scheduleSave();
    notifyListeners();
  }

  Future<void> clearAll() async {
    bpSys = bpDia = pr = rr = spo2 = null;
    bt = dtx = bw = h = null;
    _scheduleSave();
    notifyListeners();
  }
}
