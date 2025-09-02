import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// เปิดคีย์บอร์ดตัวเลขของเครื่อง (native) สำหรับแก้ไขค่าแล้วคืนค่าเป็น String
///
/// ตัวอย่างใช้:
/// final v = await showNativeNumPad(context,
///   title: 'RR', initial: '20', unit: 'bpm.', allowDecimal: false);
Future<String?> showNativeNumPad(
  BuildContext context, {
  String title = 'แก้ไขค่า',
  String unit = '',
  String initial = '',
  bool allowDecimal = true,
  bool allowSlash = false,   // สำหรับ BP (อนุญาต '/')
  bool allowSigned = false,
  int maxLength = 10,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final controller = TextEditingController(text: initial);
      final focusNode = FocusNode();

      // โฟกัสอัตโนมัติ + select ข้อความทั้งหมด
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (focusNode.canRequestFocus) {
          focusNode.requestFocus();
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        }
      });

      // อนุญาตเฉพาะตัวอักษรที่ต้องการ
      final regExp = allowSlash
          ? (allowDecimal
              ? RegExp(r'[0-9./-]')   // เลข, จุด, ลบ, สแลช
              : RegExp(r'[0-9/-]'))   // เลข, ลบ, สแลช
          : (allowDecimal
              ? RegExp(r'[0-9.-]')    // เลข, จุด, ลบ
              : RegExp(r'[0-9-]'));   // เลข, ลบ

      return SafeArea(
        top: false,
        child: Padding(
          // ดันให้พ้นคีย์บอร์ดเวลาแสดง
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // หัวข้อ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_note, color: Color.fromARGB(255, 53, 177, 138)),
                    const SizedBox(width: 8),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),

                // ช่องพิมพ์ (คีย์บอร์ดระบบจะเด้งขึ้นมา)
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: allowDecimal,
                    signed: allowSigned,
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(maxLength),
                    FilteringTextInputFormatter.allow(regExp),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF6F7F9),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixText: unit.isNotEmpty ? unit : null,
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('ยกเลิก'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, controller.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 32, 255, 185),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('ยืนยัน',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
