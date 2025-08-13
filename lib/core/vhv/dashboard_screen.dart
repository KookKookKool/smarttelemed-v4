import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ วาง Bottom NavigationBar ไว้ตรง property ของ Scaffold
      bottomNavigationBar: Manubar(
        currentIndex: 0,
        onTap: (index) {
          // ตัวอย่างการนำทาง
          if (index == 0) {
            // หน้าเดิม
          } else if (index == 1) {
            Navigator.pushNamed(context, '/settings');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/about');
          }
        },
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ส่วนหัวโปรไฟล์
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/profile.jpg'),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hello !",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Mr.Jimmy S.",
                        style: TextStyle(fontSize: 16),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "อาสาสมัคร",
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                      const Text(
                        "#12345",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // การ์ดแดชบอร์ด
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "แดชบอร์ด",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // วงกลมสถิติ
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 19 / 30,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation(Colors.green),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "จำนวน\nผู้ใช้บริการวันนี้",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                "19",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "/30",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ Legend ไม่ต้องห่อ Row ชั้นนอกอีกแล้ว
                  const _LegendItem(
                    color: Colors.green,
                    text: "จำนวนที่คนไปเยี่ยมบ้านแล้ว (มีนัดวันนี้)",
                    value: "15 ราย",
                  ),
                  const SizedBox(height: 4),
                  const _LegendItem(
                    color: Colors.blue,
                    text: "จำนวนที่คนไปเยี่ยมบ้านแล้ว (ไม่นัดวันนี้)",
                    value: "4 ราย",
                  ),
                  const SizedBox(height: 4),
                  const _LegendItem(
                    color: Colors.grey,
                    text: "จำนวนที่ยังไม่ได้เยี่ยมบ้าน",
                    value: "11 ราย",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ปุ่ม รายชื่อ
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.description, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "รายชื่อมีนัดเยี่ยมบ้าน",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ✅ Legend ใหม่ จัด layout ให้ชิดซ้าย-ขวาและกันข้อความล้น
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final String value;

  const _LegendItem({
    Key? key,
    required this.color,
    required this.text,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // จุด + ข้อความ (ห่อด้วย Expanded กันล้น)
        Expanded(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
