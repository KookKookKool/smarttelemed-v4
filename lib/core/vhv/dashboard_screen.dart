import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, color: Colors.teal),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, color: Colors.grey),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Colors.grey),
            label: '',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // โปรไฟล์และข้อมูลผู้ใช้
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // รูปโปรไฟล์
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/profile.jpg'), // ใส่รูปโปรไฟล์ใน assets
                  ),
                  const SizedBox(width: 12),

                  // ข้อมูลผู้ใช้
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hello !',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Mr.Jimmy S.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'อาสาสมัคร',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '#12345',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // การ์ดจำนวนผู้ใช้บริการ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.lightBlue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'จำนวนผู้ใช้บริการวันนี้',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '(ราย)',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    Text(
                      '19',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // การ์ดว่าง 2 ช่อง
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 5,
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
