// lib/core/setting/setting_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';
import 'package:smarttelemed_v4/storage/api_data_view_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const divider = Divider(height: 1, color: Color(0xFFE5E7EB));
    const iconColor = Color(0xFF9CA3AF);
    const arrow = Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Setting',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // กล่องเมนูตั้งค่า
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _Tile(
                    leading: const Icon(Icons.link_rounded, color: iconColor),
                    title: 'เชื่อมต่ออุปกรณ์',
                    trailing: arrow,
                    onTap: () => Navigator.pushNamed(context, '/deviceConnect'),
                  ),
                  divider,
                  _Tile(
                    leading: const Icon(
                      Icons.storage_rounded,
                      color: iconColor,
                    ),
                    title: 'ดูข้อมูล API ที่เก็บไว้',
                    trailing: arrow,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const ApiDataViewScreen(),
                        ),
                      );
                    },
                  ),
                  divider,
                  _Tile(
                    leading: const Icon(
                      Icons.error_outline_rounded,
                      color: iconColor,
                    ),
                    title: 'ช่วยเหลือ',
                    trailing: arrow,
                    onTap: () {
                      // Navigator.pushNamed(context, '/help');
                      _snack(context, 'เปิดหน้าช่วยเหลือ');
                    },
                  ),
                  divider,
                  const _Tile(
                    leading: Icon(Icons.system_update, color: iconColor),
                    title: 'เวอร์ชันล่าสุด 4.0.0',
                    trailing: arrow,
                  ),
                  divider,
                  _Tile(
                    leading: const Icon(Icons.logout_rounded, color: iconColor),
                    title: 'ลงชื่อออก',
                    trailing: arrow,
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('ยืนยันการลงชื่อออก'),
                          content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('ยกเลิก'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('ลงชื่อออก'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        _snack(context, 'ออกจากระบบแล้ว');
                        // TODO: ล้าง session และนำทางไปหน้าเข้าสู่ระบบ
                      }
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ลิงก์นโยบาย/เงื่อนไขด้านล่าง
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  TextButton(
                    onPressed: () =>
                        _snack(context, 'เปิดนโยบายความเป็นส่วนตัว'),
                    child: const Text(
                      'นโยบายความเป็นส่วนตัว',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _snack(context, 'เปิดเงื่อนไข และข้อตกลง'),
                    child: const Text(
                      'เงื่อนไข และข้อตกลง',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Manubar(currentIndex: 2),
    );
  }
}

class _Tile extends StatelessWidget {
  final Widget leading;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    Key? key,
    required this.leading,
    required this.title,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
