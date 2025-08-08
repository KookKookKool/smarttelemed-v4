import 'package:flutter/material.dart';

class DeviceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset('assets/logo.png', width: 50), // Replace with actual logo asset
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดี !',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'โรงพยาบาลอีเอสเอ็ม',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'E.S.M. Solution',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 40),

            // Circular Progress Indicator
            Column(
              children: [
                Text(
                  'จำนวนผู้ใช้บริการวันนี้',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Container(
                  child: CircularProgressIndicator(
                    value: 19 / 30, // Dynamic value
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  height: 100,
                  width: 100,
                  alignment: Alignment.center,
                ),
                SizedBox(height: 8),
                Text(
                  '19 / 30',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            SizedBox(height: 40),

            // Buttons
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Add your actions here
                  },
                  child: Text('เชื่อมต่อต่ออุปกรณ์'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Full width
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Add your actions here
                  },
                  child: Text('เข้าสู่ระบบใช้งาน'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Full width
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}