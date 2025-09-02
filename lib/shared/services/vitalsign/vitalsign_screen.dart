// lib/shared/services/vitalsign/vitalsign_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/services/vitalsign/widgets/menu_section.dart';
import 'package:smarttelemed_v4/shared/themes/background.dart';
// import 'package:smarttelemed_v4/shared/widgets/manubar.dart';

// ค่าจาก vitals ที่คุณมีอยู่เดิม
import 'package:smarttelemed_v4/shared/services/device/dashboard/device_dashboard.dart';

// // ✅ ส่วนแสดงรายการอุปกรณ์แบบฝัง (ใช้โมดูลสั้น ๆ)
// import 'package:smarttelemed_v4/shared/services/device/widgets/connected_devices_section.dart';

// ✅ หน้าอุปกรณ์เต็มหน้า (แก้ path ให้ตรงกับไฟล์ที่คุณใช้อยู่)
// import 'package:smarttelemed_v4/shared/services/device/dashboard/devices_inline_section.dart';
import 'package:smarttelemed_v4/shared/services/device/widgets/devices_menu_section.dart';

import 'package:smarttelemed_v4/shared/services/vitalsign/widgets/submit_vitals_button.dart';

import 'package:smarttelemed_v4/shared/widgets/time/th_time_screen.dart';

class VitalSignScreen extends StatelessWidget {
  const VitalSignScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AppBar แบบกำหนดเอง ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ตรวจ',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),

                      // ปุ่มไปหน้าอุปกรณ์แบบเต็มหน้า
                      // TextButton.icon(
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(builder: (_) => const DeviceScreen()),
                      //     );
                      //   },
                      //   icon: const Icon(Icons.devices),
                      //   label: const Text('ดูอุปกรณ์ทั้งหมด'),
                      // ),
                    ],
                  ),
                ),
                //Time Stamp
                ThTimeText(
                  showThaiDate: true,
                  pattern: 'HH:mm:ss',
                  useBuddhistYear: true, // ค่าเริ่มต้นเป็น true อยู่แล้ว
                  dateTimeSeparator: ' เวลา ', // ดีฟอลต์
                  appendThaiNi: true, // ดีฟอลต์
                ),
                // ── เนื้อหาหลัก ───────────────────────────────────────
                const Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ค่าสัญญาณชีพ (แดชบอร์ด)
                        DeviceDashboardSection(),
                        SizedBox(height: 16),
                        SubmitVitalsButton(
                          height: 41,
                          minWidth: 80,
                          maxWidth: 114,
                          fontSize: 16,
                        ), // <<<<<< ปุ่มส่งไป EMR
                        SizedBox(height: 24),

                        // เมนูเดิมของคุณ
                        MenuSection(),
                        SizedBox(height: 16),

                        // ✅ แสดง “อุปกรณ์ที่เชื่อมต่ออยู่” แบบฝังหน้า (สั้น/เข้าใจง่าย)
                        //    - จะแสดงเมื่อเชื่อมต่อและมีค่าเข้ามา (ตามที่ widget นี้จัดการ)
                        //    - เก็บค่าและค้างการ์ดตาม logic ภายในโมดูล

                        // DevicesInlineSection(
                        //   title: 'Devices',
                        //   showHeader: true,
                        // ),แสดงหลังเชื่อมต่อและถูกใช้งาน
                        DevicesMenuSection(), //แสดงเป็นปุ่เพื่อเข้าชม video
                        SizedBox(
                          height: 16,
                        ), // เผื่อพื้นที่ใต้สุดสำหรับปุ่มนำทาง
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Bottom Navigation ที่แชร์ใช้ ──────────────────────────
            // const Positioned(
            //   left: 0, right: 0, bottom: 0,
            //   child: Manubar(),
            // ),
          ],
        ),
      ),
    );
  }
}
