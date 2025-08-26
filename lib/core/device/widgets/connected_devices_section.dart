// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide FlutterBluePlus;
// import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
// // หน้าเชื่อมต่อ/หน้าเดี่ยว (มีอยู่แล้วในโปรเจ็กต์)
// import 'package:smarttelemed_v4/core/device/device_connect.dart';
// import 'package:smarttelemed_v4/core/device/device_page.dart';

// class ConnectedDevicesSection extends StatefulWidget {
//   const ConnectedDevicesSection({Key? key, this.showHeader = true}) : super(key: key);
//   final bool showHeader;

//   @override
//   State<ConnectedDevicesSection> createState() => _ConnectedDevicesSectionState();
// }

// class _ConnectedDevicesSectionState extends State<ConnectedDevicesSection> {
//   final List<BluetoothDevice> _devices = [];
//   bool _loading = false;
//   Timer? _timer;
//   bool _refreshing = false;

//   @override
//   void initState() {
//     super.initState();
//     _refresh();
//     _timer = Timer.periodic(const Duration(seconds: 2), (_) {
//       if (!_refreshing) _refresh();
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   Future<void> _refresh() async {
//     _refreshing = true;
//     if (mounted) setState(() => _loading = true);
//     try {
//       final devs = await FlutterBluePlus.connectedDevices;
//       if (!mounted) return;
//       _devices
//         ..clear()
//         ..addAll(devs..sort((a, b) {
//           final an = a.platformName.isNotEmpty ? a.platformName : a.remoteId.str;
//           final bn = b.platformName.isNotEmpty ? b.platformName : b.remoteId.str;
//           return an.compareTo(bn);
//         }));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('ดึงรายชื่ออุปกรณ์ล้มเหลว: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _loading = false);
//       _refreshing = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ใช้ Column เพื่อให้ฝังใน SingleChildScrollView ได้ปลอดภัย
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           if (widget.showHeader) ...[
//             const Text('อุปกรณ์ที่เชื่อมต่อ',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
//             const SizedBox(height: 8),
//           ],
//           if (_loading && _devices.isEmpty)
//             const Center(child: Padding(
//               padding: EdgeInsets.symmetric(vertical: 24),
//               child: CircularProgressIndicator(),
//             )),
//           if (!_loading && _devices.isEmpty) ...[
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white, borderRadius: BorderRadius.circular(16),
//                 boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 4))],
//               ),
//               child: Column(
//                 children: [
//                   const Text('ยังไม่มีอุปกรณ์ที่เชื่อมต่อ',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
//                   const SizedBox(height: 8),
//                   OutlinedButton.icon(
//                     icon: const Icon(Icons.add_link),
//                     label: const Text('เชื่อมต่ออุปกรณ์'),
//                     onPressed: () async {
//                       await Navigator.push(context,
//                         MaterialPageRoute(builder: (_) => const DeviceConnectPage()));
//                       if (!mounted) return;
//                       await _refresh();
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//           // รายการอุปกรณ์ (ใช้ Column เพื่อไม่ชนกับ ScrollView ด้านนอก)
//           for (final d in _devices) ...[
//             _DeviceCardInline(
//               device: d,
//               onOpen: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => DevicePage(device: d)),
//                 );
//               },
//               onDisconnect: () async {
//                 try { await d.disconnect(); } catch (_) {}
//                 await _refresh();
//               },
//             ),
//             const SizedBox(height: 12),
//           ],
//           if (_devices.isNotEmpty)
//             Align(
//               alignment: Alignment.centerRight,
//               child: TextButton.icon(
//                 onPressed: _refresh,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('รีเฟรช'),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class _DeviceCardInline extends StatelessWidget {
//   const _DeviceCardInline({
//     required this.device,
//     required this.onOpen,
//     required this.onDisconnect,
//   });

//   final BluetoothDevice device;
//   final VoidCallback onOpen;
//   final VoidCallback onDisconnect;

//   @override
//   Widget build(BuildContext context) {
//     final title = device.platformName.isNotEmpty ? device.platformName : device.remoteId.str;
//     final id    = device.remoteId.str;

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white, borderRadius: BorderRadius.circular(16),
//         boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 4))],
//       ),
//       padding: const EdgeInsets.all(12),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Row(
//           children: [
//             const Icon(Icons.devices),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(title,
//                 maxLines: 1, overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(width: 8),
//             OutlinedButton(onPressed: onOpen, child: const Text('เปิด')),
//             const SizedBox(width: 8),
//             ElevatedButton(onPressed: onDisconnect, child: const Text('ตัดการเชื่อมต่อ')),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Text('ID: $id', style: const TextStyle(color: Colors.black54)),
//       ]),
//     );
//   }
// }
