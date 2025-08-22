import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/style/background.dart';
import 'package:smarttelemed_v4/widget/manubar.dart';
import 'package:smarttelemed_v4/core/device/device_dashboard.dart';
import 'package:smarttelemed_v4/core/device/widgets/connected_devices_section.dart';
// import 'widgets/vital_sign_cards.dart';
import 'widgets/menu_section.dart';
// import 'widgets/device_list.dart';

class VitalSignScreen extends StatelessWidget {
  const VitalSignScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ตรวจ',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                const Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vital Sign Cards Section
                        // VitalSignCards(),
                        DeviceDashboardSection(),
                        SizedBox(height: 16),

                        // Menu Section
                        MenuSection(),
                        SizedBox(height: 16),

                        // Device List Section
                        ConnectedDevicesSection(),
                        SizedBox(height: 80), // Bottom padding for navigation
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Use shared Manubar widget for bottom navigation
            Positioned(left: 0, right: 0, bottom: 0, child: Manubar()),
          ],
        ),
      ),
    );
  }
}
