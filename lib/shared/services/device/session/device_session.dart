import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'package:smarttelemed_v4/shared/services/device/session/parser_binding.dart';

class DeviceSession {
  DeviceSession({
    required this.device,
    required this.onUpdate,
    required this.onError,
    required this.onDisconnected,
  });

  final BluetoothDevice device;
  final void Function() onUpdate;
  final void Function(Object error) onError;
  final Future<void> Function() onDisconnected;

  StreamSubscription? _dataSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  Future<void> Function()? _cleanup;

  Future<void> Function()? gluPrev, gluNext, gluLast, gluAll, gluCount;
  bool isThermo = false;

  Map<String, String> latestData = {};
  String? error;

  String get title =>
      device.platformName.isNotEmpty ? device.platformName : device.remoteId.str;

  Map<String, String> _normalizeData(Map m) {
    final out = <String, String>{};
    m.forEach((k, v) {
      if (v == null) return;
      if (v is num) {
        out[k.toString()] = v.toString();
      } else {
        out[k.toString()] = v.toString();
      }
    });
    if (out.containsKey('mgdL')) out['mgdl'] = out['mgdL']!;
    if (out.containsKey('mmolL')) out['mmol'] = out['mmolL']!;
    if (out.containsKey('timestamp')) out['ts'] = out['timestamp']!;
    try {
      if (out['mgdl'] != null) {
        final v = double.tryParse(out['mgdl']!);
        if (v != null) out['mgdl'] = v.toStringAsFixed(0);
      }
      if (out['mmol'] != null) {
        final v = double.tryParse(out['mmol']!);
        if (v != null) out['mmol'] = v.toStringAsFixed(1);
      }
    } catch (_) {}
    return out;
  }

  Future<void> start({
    required Future<ParserBinding> Function(
      BluetoothDevice device,
      List<BluetoothService> services,
    ) pickParser,
  }) async {
    _connSub = device.connectionState.listen((s) async {
      if (s == BluetoothConnectionState.disconnected) {
        await _cleanupBinding();
        latestData = {};
        onUpdate();
        await onDisconnected();
      }
    });

    try {
      try { await FlutterBluePlus.stopScan(); } catch (_) {}

      var st = await device.connectionState.first;
      if (st == BluetoothConnectionState.disconnected) {
        await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
        st = await device.connectionState
            .where((x) => x == BluetoothConnectionState.connected || x == BluetoothConnectionState.disconnected)
            .first
            .timeout(const Duration(seconds: 12));
        if (st != BluetoothConnectionState.connected) {
          throw 'เชื่อมต่อไม่สำเร็จ';
        }
      }

      final services = await device.discoverServices();

      await _cleanupBinding();
      final binding = await pickParser(device, services);
      _cleanup = binding.cleanup;

      isThermo = binding.isThermo;
      gluPrev  = binding.onPrev;
      gluNext  = binding.onNext;
      gluLast  = binding.onLast;
      gluAll   = binding.onAll;
      gluCount = binding.onCount;

      // CHANGED: mapStream เป็น Stream<Map> → normalize ก่อนอัปเดต
      _dataSub = binding.mapStream?.listen((m) {
        final nm = _normalizeData(m);

        // Guard °C จาก oximeter
        final src = (nm['src'] ?? '').toLowerCase();
        final looksLikeOxi =
            nm.containsKey('spo2') || nm.containsKey('SpO2') || nm.containsKey('SPO2') ||
            nm.containsKey('pr')   || nm.containsKey('PR')   || nm.containsKey('pulse') ||
            src.contains('yx110');
        if (looksLikeOxi) {
          latestData.remove('temp');
          latestData.remove('temp_c');
          latestData.remove('temperature');
        }

        latestData = {...latestData, ...nm};
        error = null;
        onUpdate();
      }, onError: (e) {
        error = '$e';
        onError(e);
        onUpdate();
      });

      // fallback streams (bp / temp)
      _dataSub ??= binding.bpStream?.listen((bp) {
        latestData = {
          'sys': bp.systolic.toStringAsFixed(0),
          'dia': bp.diastolic.toStringAsFixed(0),
          'map': bp.map.toStringAsFixed(0),
          if (bp.pulse != null) 'pul': bp.pulse!.toStringAsFixed(0),
          if (bp.timestamp != null) 'ts': bp.timestamp!.toIso8601String(),
        };
        error = null;
        onUpdate();
      }, onError: (e) {
        error = '$e';
        onError(e);
        onUpdate();
      });

      _dataSub ??= binding.tempStream?.listen((t) {
        latestData = {'temp': t.toStringAsFixed(2)};
        error = null;
        onUpdate();
      }, onError: (e) {
        error = '$e';
        onError(e);
        onUpdate();
      });
    } catch (e) {
      error = '$e';
      onError(e);
      onUpdate();
    }
  }

  Future<void> _cleanupBinding() async {
    await _dataSub?.cancel(); _dataSub = null;
    if (_cleanup != null) { try { await _cleanup!(); } catch (_) {} _cleanup = null; }
    gluPrev = gluNext = gluLast = gluAll = gluCount = null;
  }

  Future<void> dispose() async {
    await _cleanupBinding();
    await _connSub?.cancel();
  }
}
