import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const Manubar(),
      backgroundColor: const Color(0xFFF6F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Profile",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Picture + Edit Button
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 60,
                          // backgroundImage: NetworkImage(
                          //     "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d"), // ตัวอย่าง
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              // TODO: ฟังก์ชันแก้ไขรูป
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.edit, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // User ID
                    const Text(
                      "#12345",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 6),

                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "อาสาสมัคร",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // First Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ชื่อ",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: "Jimmy",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Last Name
                          const Text("นามสกุล",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: "Jimmy",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
