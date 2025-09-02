import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttelemed_v4/shared/services/device/dashboard/vitals.dart';
import 'package:smarttelemed_v4/shared/services/device/api/clinic_api.dart';
import 'package:smarttelemed_v4/shared/storage/storage.dart';

class SubmitVitalsButton extends StatefulWidget {
  const SubmitVitalsButton({
    super.key,
    this.addHrUrl =
        'https://emr-life.com/expert/telemed/StmsApi/add_visit', // TODO: เปลี่ยนเป็น emr-life.com
    this.careUnitId,
    this.publicId,
    this.recepPublicId,
    this.cc,
    this.compact = false,
    this.height,
    this.minWidth,
    this.maxWidth,
    this.fontSize,
  });

  final String addHrUrl;
  final String? careUnitId;
  final String? publicId;
  final String? recepPublicId;
  final String? cc;
  final bool compact;

  // ปรับขนาดปุ่ม
  final double? height, minWidth, maxWidth, fontSize;

  @override
  State<SubmitVitalsButton> createState() => _SubmitVitalsButtonState();
}

class _SubmitVitalsButtonState extends State<SubmitVitalsButton> {
  bool _sending = false;
  String? _careUnitId, _publicId, _recepPublicId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Vitals.I.ensure();
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _careUnitId = widget.careUnitId ?? p.getString('cu.care_unit_id');
      _publicId = widget.publicId ?? p.getString('cu.public_id');
      _recepPublicId =
          widget.recepPublicId ?? p.getString('cu.recep_public_id');
    });
  }

  bool get _hasAny =>
      Vitals.I.bpSys != null ||
      Vitals.I.bpDia != null ||
      Vitals.I.pr != null ||
      Vitals.I.rr != null ||
      Vitals.I.spo2 != null ||
      Vitals.I.bt != null ||
      Vitals.I.dtx != null ||
      Vitals.I.bw != null ||
      Vitals.I.h != null;

  Future<void> _submit() async {
    if (_sending) return;
    setState(() => _sending = true);

    // เตรียมข้อมูล Vitals สำหรับบันทึก
    final vitalsData = {
      'bpSys': Vitals.I.bpSys,
      'bpDia': Vitals.I.bpDia,
      'pr': Vitals.I.pr,
      'rr': Vitals.I.rr,
      'spo2': Vitals.I.spo2,
      'bt': Vitals.I.bt,
      'dtx': Vitals.I.dtx,
      'bw': Vitals.I.bw,
      'h': Vitals.I.h,
      'careUnitId': _careUnitId,
      'publicId': _publicId,
      'recepPublicId': _recepPublicId,
      'cc': widget.cc,
      'addHrUrl': widget.addHrUrl,
    };

    // บันทึกข้อมูลลง Storage ก่อนส่ง API
    try {
      await VitalsStorage.saveVitalsData(vitalsData);
      print('✅ Vitals data saved to storage successfully');
    } catch (e) {
      print('❌ Error saving vitals to storage: $e');
    }

    final res = await ClinicApi.addHealthRecord(
      url: widget.addHrUrl,
      vitals: Vitals.I,
      careUnitId: _careUnitId,
      publicId: _publicId,
      recepPublicId: _recepPublicId,
      cc: widget.cc,
    );

    if (!mounted) return;
    final text = res.ok
        ? 'ส่งข้อมูลสำเร็จ (${res.status})'
        : 'ส่งไม่สำเร็จ (${res.status})';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _hasAny && !_sending;

    // ขนาด/สไตล์
    final h = widget.height ?? (widget.compact ? 44.0 : 72.0);
    final fs = widget.fontSize ?? (widget.compact ? 16.0 : 28.0);
    final r = h / 2 + 6; // โค้งแบบแคปซูล
    final minW = widget.minWidth ?? 220.0;
    final maxW = widget.maxWidth ?? 360.0;

    const gradOn = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10B981), Color(0xFF06B6D4)], // เขียว > ฟ้า
    );
    const gradOff = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)], // เทาอ่อน
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minW, maxWidth: maxW),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(r),
          child: InkWell(
            borderRadius: BorderRadius.circular(r),
            onTap: enabled ? _submit : null,
            child: Ink(
              height: h,
              decoration: BoxDecoration(
                gradient: enabled ? gradOn : gradOff,
                borderRadius: BorderRadius.circular(r),
                boxShadow: enabled
                    ? const [
                        BoxShadow(
                          color: Color(0x3300A47A),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : const [],
              ),
              child: Center(
                child: _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.compact) ...[
                            const Icon(Icons.send, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            'ส่งข้อมูล',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fs,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: const [
                                Shadow(
                                  color: Color(0x40000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
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
