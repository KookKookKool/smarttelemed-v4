import 'dart:async';
import 'package:smarttelemed_v4/shared/screens/device/add_device/A&D/ua_651ble.dart';

class ParserBinding {
  ParserBinding._({
    this.mapStream,
    this.bpStream,
    this.tempStream,
    this.cleanup,
    this.onPrev,
    this.onNext,
    this.onLast,
    this.onAll,
    this.onCount,
    this.isThermo = false,
  });

  /// ยอมรับเป็น Stream<Map> (dynamic key/value) เพื่อความยืดหยุ่น
  final Stream<Map>? mapStream;
  final Stream<BpReading>? bpStream;
  final Stream<double>? tempStream;
  final Future<void> Function()? cleanup;

  // Optional glucose control buttons
  final Future<void> Function()? onPrev, onNext, onLast, onAll, onCount;
  final bool isThermo;

  static ParserBinding map(
    Stream<Map> s, {
    Future<void> Function()? cleanup,
    Future<void> Function()? onPrev,
    Future<void> Function()? onNext,
    Future<void> Function()? onLast,
    Future<void> Function()? onAll,
    Future<void> Function()? onCount,
    bool isThermo = false,
  }) =>
      ParserBinding._(
        mapStream: s,
        cleanup: cleanup,
        onPrev: onPrev,
        onNext: onNext,
        onLast: onLast,
        onAll: onAll,
        onCount: onCount,
        isThermo: isThermo,
      );

  static ParserBinding bp(
    Stream<BpReading> s, {
    Future<void> Function()? cleanup,
  }) =>
      ParserBinding._(bpStream: s, cleanup: cleanup);

  static ParserBinding temp(
    Stream<double> s, {
    Future<void> Function()? cleanup,
  }) =>
      ParserBinding._(tempStream: s, cleanup: cleanup, isThermo: true);
}
