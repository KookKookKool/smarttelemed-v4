import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/widgets/manubar.dart';

class DeviceDetailScreen extends StatelessWidget {
  final DeviceDetailData deviceData;

  const DeviceDetailScreen({Key? key, required this.deviceData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8FFF7), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      deviceData.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Device Image Container
                      Container(
                        width: double.infinity,
                        height: 250,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(child: deviceData.deviceImage),
                      ),

                      // Device Info
                      Text(
                        deviceData.deviceName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deviceData.model,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status Text
                      Text(
                        deviceData.statusText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: deviceData.statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deviceData.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Measurement Fields
                      ...deviceData.measurements
                          .map(
                            (measurement) =>
                                _buildMeasurementField(measurement),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation (if needed)
              // Use shared Manubar widget for bottom navigation
              Manubar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementField(MeasurementField measurement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              measurement.label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
          const SizedBox(width: 16),
          Text(
            measurement.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: measurement.valueColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            measurement.unit,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class DeviceDetailData {
  final String title;
  final String deviceName;
  final String model;
  final Widget deviceImage;
  final String statusText;
  final String description;
  final Color statusColor;
  final List<MeasurementField> measurements;

  DeviceDetailData({
    required this.title,
    required this.deviceName,
    required this.model,
    required this.deviceImage,
    required this.statusText,
    required this.description,
    required this.statusColor,
    required this.measurements,
  });
}

class MeasurementField {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  MeasurementField({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor = Colors.teal,
  });
}
