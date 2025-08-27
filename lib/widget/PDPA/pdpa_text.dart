// lib/core/legal/pdpa_text.dart
//
// PDPA Consent Dialog for Smarttelemed_v4 (Compact, clean UI)
// - Scrollable PDPA content
// - Must scroll to bottom + check "accept" to enable "Confirm"
// - Minimal UI: no % text, no status pills, no "scroll to end" button
// - Thin progress line on header (2px), soft header gradient, roomy reading area
//
// Usage:
// final accepted = await showPdpaDialog(context);
// if (accepted) { /* persist consent, continue */ }

import 'package:flutter/material.dart';

/// Public function to show the PDPA dialog.
/// Returns true if user confirms (accepted), false if canceled / closed.
Future<bool> showPdpaDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const _PdpaConsentDialog(),
  );
  return result == true;
}

class _PdpaConsentDialog extends StatefulWidget {
  const _PdpaConsentDialog();

  @override
  State<_PdpaConsentDialog> createState() => _PdpaConsentDialogState();
}

class _PdpaConsentDialogState extends State<_PdpaConsentDialog> {
  final ScrollController _scroll = ScrollController();

  bool _accepted = false;      // เช็กบ็อกซ์ยอมรับ
  bool _readAll = false;       // เลื่อนถึงท้ายเอกสารแล้ว
  double _readProgress = 0.0;  // 0..1 (ไม่แสดงข้อความ)

  static const String _projectName = 'Smarttelemed_v4';
  static const String _companyName = 'E.S.M. Solution Co. Ltd';
  static const String _policyVersion = 'PDPA v1.0 – อัปเดต 28 ส.ค. 2568';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialProgress());
  }

  @override
  void dispose() {
    _scroll.removeListener(_handleScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _ensureInitialProgress() {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 8) {
      setState(() {
        _readAll = true;
        _readProgress = 1.0;
      });
    } else {
      _handleScroll();
    }
  }

  void _handleScroll() {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
    final pos = _scroll.position;
    final max = pos.maxScrollExtent <= 0 ? 1.0 : pos.maxScrollExtent;
    final progress = (pos.pixels / max).clamp(0.0, 1.0);

    // ถึงท้ายเอกสารเมื่อเกือบสุด (กัน jitter เล็กน้อยด้วยระยะ 12px)
    final atEnd = pos.pixels >= (pos.maxScrollExtent - 12);

    if ((progress - _readProgress).abs() > 0.005 || atEnd != _readAll) {
      setState(() {
        _readProgress = progress;
        _readAll = atEnd;
      });
    }
  }

  void _onConfirm() => Navigator.of(context).pop(true);
  void _onCancel() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = 22.0;

    final canConfirm = _accepted && _readAll;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          // ปรับขนาดใหม่: กว้างขึ้นเล็กน้อย สูงขึ้น แต่ยังปลอดภัยบนจอเล็ก
          maxWidth: 840,
          maxHeight: 720,
          minWidth: 320,
          minHeight: 380,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 8, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.08),
                      theme.colorScheme.primaryContainer.withOpacity(0.18),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.privacy_tip_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('นโยบายคุ้มครองข้อมูลส่วนบุคคล (PDPA)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              )),
                          const SizedBox(height: 2),
                          Text('$_projectName • $_policyVersion',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'ปิด',
                      onPressed: _onCancel,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              // Thin progress line under header (2px)
              SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: _readProgress.clamp(0.0, 1.0),
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                ),
              ),

              const Divider(height: 1),

              // ── Body: Scrollable + subtle bottom fade (space-friendly) ─────
              Expanded(
                child: Stack(
                  children: [
                    Scrollbar(
                      thumbVisibility: true,
                      controller: _scroll,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: const _PdpaContent(
                          projectName: _projectName,
                          companyName: _companyName,
                        ),
                      ),
                    ),
                    // Subtle bottom fade hint (height small เพื่อไม่กินพื้นที่)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: _readAll ? 0.0 : 1.0,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.colorScheme.surface.withOpacity(0.0),
                                  theme.colorScheme.surface.withOpacity(0.85),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Footer (checkbox + actions) ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        value: _accepted,
                        onChanged: (v) => setState(() => _accepted = v ?? false),
                        title: const Text(
                          'ฉันได้อ่านและยอมรับตามนโยบายคุ้มครองข้อมูลส่วนบุคคล (PDPA)',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onCancel,
                        child: const Text('ยกเลิก'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: canConfirm ? _onConfirm : null,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('ยืนยัน'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdpaContent extends StatelessWidget {
  const _PdpaContent({
    required this.projectName,
    required this.companyName,
  });

  final String projectName;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    Widget h(String text) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 3.5,
                height: 18,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Expanded(
                child: Text(text,
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    )),
              ),
            ],
          ),
        );

    Widget p(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(text, style: t.bodyMedium, textAlign: TextAlign.start),
        );

    Widget li(String text) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7),
                width: 5.5,
                height: 5.5,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: t.bodyMedium)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intro card (compact)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: scheme.onSecondaryContainer, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'บริษัท $companyName (“บริษัท”) เป็นผู้ควบคุมข้อมูลสำหรับโครงการ/แอป $projectName '
                  'บริษัทตระหนักถึงความสำคัญของการคุ้มครองข้อมูลส่วนบุคคลตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA) '
                  'โปรดอ่านรายละเอียดต่อไปนี้อย่างรอบคอบ ก่อนกด “ยืนยัน” เพื่อให้ความยินยอม',
                  style: t.bodyMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        h('1) ข้อมูลที่เก็บรวบรวม'),
        li('ข้อมูลระบุตัวตน เช่น ชื่อ–นามสกุล เลขอ้างอิงผู้ใช้ รหัสผู้ป่วย (ถ้ามี)'),
        li('ข้อมูลติดต่อ เช่น เบอร์โทร อีเมล'),
        li('ข้อมูลเชิงเทคนิคของอุปกรณ์ เช่น รุ่นอุปกรณ์ ระบบปฏิบัติการ รหัสเครื่อง (Device ID), Log การใช้งาน'),
        li('ข้อมูลสุขภาพ/ชีววัดที่คุณกรอกหรือยินยอมให้เชื่อมต่อกับอุปกรณ์ที่รองรับ (เช่น สัญญาณชีพ ค่าชีววัดจากอุปกรณ์)'),
        li('คุกกี้และเทคโนโลยีติดตามการใช้งานภายในแอป'),

        h('2) วัตถุประสงค์ในการประมวลผล'),
        li('ให้บริการฟังก์ชันของ $projectName เช่น การบันทึก/แสดงผลข้อมูลสุขภาพ การเชื่อมต่ออุปกรณ์ และการสนับสนุนการแพทย์ทางไกล'),
        li('ปรับปรุงคุณภาพบริการ ความเสถียร และความปลอดภัยของระบบ'),
        li('การปฏิบัติตามกฎหมาย ระเบียบ ข้อบังคับที่เกี่ยวข้อง'),

        h('3) ฐานทางกฎหมาย'),
        li('ความยินยอมของท่าน'),
        li('การปฏิบัติตามสัญญา/คำขอบริการที่ท่านร้องขอ'),
        li('ประโยชน์โดยชอบด้วยกฎหมายของบริษัท โดยคำนึงถึงสิทธิของท่าน'),

        h('4) การเปิดเผยและโอนข้อมูล'),
        li('ผู้ประมวลผลข้อมูลที่เป็นคู่สัญญากับบริษัท เพื่อให้บริการระบบและโครงสร้างพื้นฐาน'),
        li('บุคลากรทางการแพทย์/หน่วยงานที่เกี่ยวข้องเมื่อเป็นส่วนหนึ่งของบริการที่ท่านร้องขอ'),
        li('หน่วยงานรัฐตามที่กฎหมายกำหนด'),
        p('หากมีการโอนข้อมูลไปต่างประเทศ บริษัทจะดำเนินการตามมาตรการคุ้มครองที่เหมาะสม.'),

        h('5) ระยะเวลาเก็บรักษา'),
        p('บริษัทจะเก็บรักษาข้อมูลเท่าที่จำเป็นตามวัตถุประสงค์ข้างต้น หรือเท่าที่กฎหมายกำหนด '
            'เมื่อพ้นความจำเป็น ข้อมูลจะถูกลบ ทำให้นิรนาม หรือเก็บต่อด้วยมาตรการจำกัดอย่างเหมาะสม.'),

        h('6) สิทธิของเจ้าของข้อมูล'),
        li('สิทธิขอเข้าถึง/รับสำเนาข้อมูล'),
        li('สิทธิให้โอนย้ายข้อมูล'),
        li('สิทธิคัดค้าน/ขอให้ระงับการประมวลผล'),
        li('สิทธิขอให้ลบ/ทำลาย/ทำให้เป็นข้อมูลนิรนาม'),
        li('สิทธิแก้ไขให้ถูกต้องเป็นปัจจุบัน'),
        li('สิทธิถอนความยินยอม โดยไม่กระทบต่อการประมวลผลก่อนถอน'),
        p('คุณสามารถใช้สิทธิดังกล่าวผ่านเมนูการตั้งค่าในแอปหรือช่องทางติดต่อของบริษัท.'),

        h('7) ความปลอดภัยของข้อมูล'),
        p('บริษัทใช้มาตรการความมั่นคงปลอดภัยที่เหมาะสมทั้งทางเทคนิคและองค์กร '
            'เพื่อป้องกันการเข้าถึง ใช้ หรือเปิดเผยข้อมูลโดยไม่ได้รับอนุญาต.'),

        h('8) การติดต่อ'),
        p('สำหรับข้อสงสัย คำร้องขอใช้สิทธิ หรือเรื่องร้องเรียนเกี่ยวกับ PDPA '
            'โปรดติดต่อบริษัท $companyName ผ่านช่องทางที่ระบุไว้ภายในแอป.'),

        h('การให้ความยินยอม'),
        Text(
          'โดยการทำเครื่องหมาย “ฉันยอมรับ” และกด “ยืนยัน” '
          'ท่านรับทราบว่าได้อ่านและเข้าใจนโยบายนี้ และยินยอมให้บริษัทประมวลผลข้อมูลของท่านตามที่ระบุไว้ข้างต้น',
          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 10),
        Text('หมายเหตุ: คุณสามารถถอนความยินยอมได้ภายหลังในเมนูการตั้งค่า',
            style: t.bodySmall?.copyWith(color: muted)),
        const SizedBox(height: 2),
        Text('เอกสารฉบับนี้มีผลกับการใช้งาน $projectName', style: t.bodySmall),
      ],
    );
  }
}
