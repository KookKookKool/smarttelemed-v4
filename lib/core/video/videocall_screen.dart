// lib/core/doctor/videocall_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({Key? key}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool muted = false;
  bool frontCam = true;

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00B3A8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'พบแพทย์',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6FFFB), Colors.white],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // วิดีโอหลัก (พื้นหลังเทาเข้ม)
            Positioned.fill(
              child: Container(color: const Color(0xFF525252)),
            ),

            // ชื่อแพทย์ด้านบนขวา
            Positioned(
              top: 8,
              right: 12,
              child: Text(
                'พญ.ลลิตา สมอง #11111',
                style: TextStyle(
                  color: Colors.white.withOpacity(.9),
                  fontSize: 12,
                ),
              ),
            ),

            // กล้องตนเองแบบ PiP มุมล่างขวา
            Positioned(
              right: 16,
              bottom: 110, // เผื่อพื้นที่ให้ปุ่มวิดีโอและแถบเมนูด้านล่าง
              child: Container(
                width: 96,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // แผงควบคุมวิดีโอคอล (ไมค์–วางสาย–สลับกล้อง)
            Positioned(
              left: 0,
              right: 0,
              bottom: 60, // ให้ลอยเหนือ manubar
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ปิด/เปิดไมค์
                  _roundIconButton(
                    background: Colors.black.withOpacity(.35),
                    icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    iconColor: Colors.white,
                    onTap: () => setState(() => muted = !muted),
                  ),
                  // วางสาย (ปุ่มใหญ่สีแดง)
                  _roundIconButton(
                    size: 64,
                    background: Colors.black45,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white),
                    ),
                    onTap: () {
                      // TODO: จัดการวางสายจริง
                      Navigator.pushReplacementNamed(context, '/doctorPending');
                    },
                  ),
                  // สลับกล้อง/รีเฟรช
                  _roundIconButton(
                    background: Colors.black.withOpacity(.35),
                    icon: Icons.cameraswitch_rounded,
                    iconColor: Colors.white,
                    onTap: () => setState(() => frontCam = !frontCam),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Manubar(currentIndex: 1),
    );
  }

  /// ปุ่มกลม ๆ สำหรับคอนโทรลวิดีโอคอล
  Widget _roundIconButton({
    double size = 52,
    Color background = const Color(0x33000000),
    Color? iconColor,
    IconData? icon,
    Widget? child,
    required VoidCallback onTap,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: size,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: child ??
            Icon(
              icon,
              color: iconColor ?? Colors.white,
              size: size * 0.46,
            ),
      ),
    );
  }
}
