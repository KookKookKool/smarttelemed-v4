// lib/core/notes/record_note_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';

class RecordNoteScreen extends StatefulWidget {
  const RecordNoteScreen({Key? key}) : super(key: key);

  @override
  State<RecordNoteScreen> createState() => _RecordNoteScreenState();
}

class _RecordNoteScreenState extends State<RecordNoteScreen> {
  final _noteCtrl = TextEditingController();
  final _careCtrl = TextEditingController();
  final _relativesCtrl = TextEditingController();

  int _mood = 4; // 0..4 (เศร้ามาก -> ยิ้มมาก), เริ่มต้นยิ้ม (index 4)

  @override
  void dispose() {
    _noteCtrl.dispose();
    _careCtrl.dispose();
    _relativesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF00B3A8);

    Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16),
      child: Text(t,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            color: Color(0xFF111827),
          )),
    );

    InputDecoration boxInput({String hint = ''}) => InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(16),
      ),
    );

    Widget photoBox() => Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.black26, size: 28),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('บันทึก',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            )),
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFFFFA), Color(0xFFF8FFFE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle('บันทึกข้อมูลคนไข้'),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 5,
                  decoration: boxInput(),
                ),

                sectionTitle('บันทึกอาการ/การพยาบาล'),
                TextField(
                  controller: _careCtrl,
                  maxLines: 5,
                  decoration: boxInput(),
                ),

                sectionTitle('รูปถ่าย/วิดีโอ'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      photoBox(),
                      const SizedBox(width: 12),
                      photoBox(),
                      const SizedBox(width: 12),
                      photoBox(),
                    ],
                  ),
                ),

                sectionTitle('สุขภาพจิต/อารมณ์'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (i) {
                      final icons = [
                        Icons.sentiment_very_dissatisfied_rounded,
                        Icons.sentiment_dissatisfied_rounded,
                        Icons.sentiment_neutral_rounded,
                        Icons.sentiment_satisfied_rounded,
                        Icons.sentiment_very_satisfied_rounded,
                      ];
                      final selected = _mood == i;
                      return InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _mood = i),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFE6FBF8) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? teal : Colors.transparent,
                              width: selected ? 2 : 0,
                            ),
                          ),
                          child: Icon(
                            icons[i],
                            size: 22,
                            color: selected ? teal : Colors.black45,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                sectionTitle('การดูแลผู้ป่วยของญาติ/ความยากลำบาก'),
                TextField(
                  controller: _relativesCtrl,
                  maxLines: 5,
                  decoration: boxInput(),
                ),

                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: บันทึกข้อมูลตามต้องการ
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 4,
                    ),
                    child: const Text('บันทึก',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const Manubar(currentIndex: 1),
    );
  }
}
