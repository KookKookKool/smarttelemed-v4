import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/style/background_2.dart';
import 'package:smarttelemed_v4/style/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smarttelemed_v4/widget/PDPA/pdpa_text.dart'; // ⬅️ สำคัญ: ต้องมีฟังก์ชัน showPdpaDialog

class IdCardLoginScreen extends StatelessWidget {
  const IdCardLoginScreen({Key? key}) : super(key: key);

  void _onInsertCard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เสียบบัตรประชาชน'),
        content: const Text('ฟีเจอร์นี้จะเชื่อมต่อกับเครื่องอ่านบัตรประชาชนในอนาคต'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PdpaOnOpen( // ⬅️ หุ้มทั้งหน้าให้เด้ง PDPA อัตโนมัติ
      redirectRoute: '/device', // ผู้ใช้กดยกเลิก → เด้งออก
      child: CircleBackground2(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              '',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // โลโก้กลาง
                    SvgPicture.asset(
                      'assets/logo.svg',
                      width: (160),
                      height: (160),
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 35),

                    // หัวข้อ
                    const Text(
                      'เข้าสู่ระบบการใช้งาน',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 60),

                    // ───────── กล่องกรอกเลขบัตรประชาชน (w:250, h:45)
                    SizedBox(
                      width: 250,
                      height: 45,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          maxLength: 13,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: 'เลขบัตรประชาชน',
                            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                            prefixIcon: const Icon(Icons.credit_card, size: 18, color: AppColors.gradientStart),
                            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            isDense: true,
                            isCollapsed: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            counterText: '',
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ───────── กล่องกรอกวันเดือนปีเกิด (w:250, h:45)
                    SizedBox(
                      width: 250,
                      height: 45,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          keyboardType: TextInputType.datetime,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: 'วันเดือนปีเกิด',
                            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                            prefixIcon: const Icon(Icons.cake, size: 18, color: AppColors.gradientEnd),
                            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            isDense: true,
                            isCollapsed: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ปุ่มยืนยัน
                    SizedBox(
                      width: 114,
                      height: 38,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.mainGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gradientStart.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: const Text('ยืนยัน', style: TextStyle(fontSize: 14, color: Colors.white)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 150),

                    // ปุ่มเสียบบัตรประชาชน
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/idcardinsert'),
                      child: const Text(
                        'เสียบบัตรประชาชน',
                        style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ตัวบูตสแตรปเล็กๆ ที่จะเด้ง PDPA หลังเฟรมแรก
class _PdpaOnOpen extends StatefulWidget {
  const _PdpaOnOpen({required this.child, this.redirectRoute});

  final Widget child;
  final String? redirectRoute; // ถ้าผู้ใช้กดยกเลิก → จะเด้งไป route นี้

  @override
  State<_PdpaOnOpen> createState() => _PdpaOnOpenState();
}

class _PdpaOnOpenState extends State<_PdpaOnOpen> {
  bool _asked = false; // กันเปิดซ้ำหาก build หลายครั้ง

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _asked) return;
      _asked = true;

      final ok = await showPdpaDialog(context); // ⬅️ เรียก dialog ที่คุณมีอยู่แล้ว
      if (!ok && mounted && widget.redirectRoute != null) {
        Navigator.pushNamedAndRemoveUntil(context, widget.redirectRoute!, (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
