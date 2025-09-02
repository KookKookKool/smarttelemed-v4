import 'package:flutter/material.dart';
import '../device_detail_screen.dart';

class DeviceWidgets {
  // Ear Thermometer
  static DeviceDetailData getEarThermometerData() {
    return DeviceDetailData(
      title: 'Ear Thermometer',
      deviceName: 'เครื่องวัดอุณหภูมิ',
      model: 'Ear Thermometer',
      deviceImage: Container(
        width: 120,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.thermostat, size: 80, color: Colors.grey),
      ),
      statusText: 'กรุณาวัดอุณหภูมิ',
      description: 'กำลังเปิด วัดได้มิเนตต่อเนื่องน่ำเป็น เพื่อได้ผลที่แม่นยำ',
      statusColor: Colors.teal,
      measurements: [
        MeasurementField(
          label: 'BT',
          value: '',
          unit: 'oC.',
          valueColor: Colors.grey,
        ),
      ],
    );
  }

  // Jumper Pulse
  static DeviceDetailData getJumperPulseData() {
    return DeviceDetailData(
      title: 'Jumper Pulse',
      deviceName: 'เครื่องวัดออกซิเจนปลายนิ้ว',
      model: 'Jumper Pulse',
      deviceImage: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            '98\n70',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      statusText: 'กรุณาวัดออกซิเจน',
      description:
          'กำลังเปิด วัดออกซิเจนที่ปลายนิ้ว และอุณหภูมิปีปีวุ่นให้วัดใส่ปลายนิ้ว',
      statusColor: Colors.teal,
      measurements: [
        MeasurementField(
          label: 'SpO₂',
          value: '',
          unit: '%.',
          valueColor: Colors.grey,
        ),
        MeasurementField(
          label: 'PR',
          value: '',
          unit: 'bpm.',
          valueColor: Colors.grey,
        ),
      ],
    );
  }

  // MI scale 2
  static DeviceDetailData getMIScale2Data() {
    return DeviceDetailData(
      title: 'MI scale 2',
      deviceName: 'เครื่องชั่งน้ำหนัก',
      model: 'MI scale 2',
      deviceImage: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Icon(Icons.scale, size: 60, color: Colors.grey),
        ),
      ),
      statusText: 'ชั่งน้ำหนักสำเร็จ',
      description:
          'กำลังเปิด การบิคอมพิวดเมลทสำ 5 นาที และเบื่องส่องการกำจายขาว',
      statusColor: Colors.green,
      measurements: [
        MeasurementField(
          label: 'PR',
          value: '60',
          unit: 'bpm.',
          valueColor: Colors.teal,
        ),
      ],
    );
  }

  // Thermometer
  static DeviceDetailData getThermometerData() {
    return DeviceDetailData(
      title: 'Thermometer',
      deviceName: 'เครื่องวัดอุณหภูมิ',
      model: 'Thermometer',
      deviceImage: Container(
        width: 80,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '36.8',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.thermostat, size: 40, color: Colors.blue),
          ],
        ),
      ),
      statusText: 'อุณหภูมิปิจจัยกายปกติ',
      description:
          'กำลังเปิด ดันไว้ให้ความร้อน 8 นาที และเบื่องส่องการกำจายขาว',
      statusColor: Colors.green,
      measurements: [
        MeasurementField(
          label: 'BT',
          value: '36.7',
          unit: 'oC.',
          valueColor: Colors.teal,
        ),
      ],
    );
  }

  // Yuwell Glucometer
  static DeviceDetailData getYuwellGlucometerData() {
    return DeviceDetailData(
      title: 'Yuwell Glucometer',
      deviceName: 'เครื่องวัดค่าน้ำตาลในเลือด',
      model: 'Yuwell Glucometer',
      deviceImage: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '10.4',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.bloodtype, size: 30, color: Colors.red),
          ],
        ),
      ),
      statusText: 'ค่าน้ำตาลในเลือดปกติ',
      description: 'กำลังเปิด วางเซาะครื่องวัด หดมื่องการกำจายขาว',
      statusColor: Colors.green,
      measurements: [
        MeasurementField(
          label: 'DTX',
          value: '90',
          unit: 'mg%.',
          valueColor: Colors.teal,
        ),
      ],
    );
  }

  // Yuwell SpO2
  static DeviceDetailData getYuwellSpO2Data() {
    return DeviceDetailData(
      title: 'Yuwell SpO2',
      deviceName: 'เครื่องวัดออกซิเจนปลายนิ้ว',
      model: 'Yuwell SpO2',
      deviceImage: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            '99\n70',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      statusText: 'ออกซิเจนในเลือดปกติ',
      description: 'กำลังเปิด ความเมื่อมพจก์ ออกกำจายขาวส่งล่าเสื่อ',
      statusColor: Colors.green,
      measurements: [
        MeasurementField(
          label: 'SpO₂',
          value: '100',
          unit: '%.',
          valueColor: Colors.teal,
        ),
        MeasurementField(
          label: 'PR',
          value: '88',
          unit: 'bpm.',
          valueColor: Colors.teal,
        ),
      ],
    );
  }

  // Yuwell YE860A
  static DeviceDetailData getYuwellYE860AData() {
    return DeviceDetailData(
      title: 'Yuwell YE860A',
      deviceName: 'เครื่องวัดความดัน',
      model: 'Yuwell YE860A',
      deviceImage: Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(Icons.monitor_heart, size: 60, color: Colors.red),
        ),
      ),
      statusText: 'ความดันปกติ',
      description: 'กำลังเปิด ความเมื่อมพจก์ ออกกำจายขาวส่งล่าเสื่อ',
      statusColor: Colors.green,
      measurements: [
        MeasurementField(
          label: 'BP',
          value: '140 / 90',
          unit: 'mmHg.',
          valueColor: Colors.teal,
        ),
        MeasurementField(
          label: 'PR',
          value: '90',
          unit: 'bpm.',
          valueColor: Colors.teal,
        ),
      ],
    );
  }

  // Yuwell YE992
  static DeviceDetailData getYuwellYE992Data() {
    return DeviceDetailData(
      title: 'Yuwell YE992',
      deviceName: 'เครื่องวัดความดัน',
      model: 'Yuwell YE992',
      deviceImage: Container(
        width: 140,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(Icons.medical_services, size: 60, color: Colors.blue),
        ),
      ),
      statusText: 'ความดันปกติ',
      description: 'กำลังเปิด ความเมื่อมพจก์ ออกกำจายขาวส่งล่าเสื่อ',
      statusColor: Colors.green,
      measurements: [
        MeasurementField(
          label: 'BP',
          value: '140 / 90',
          unit: 'mmHg.',
          valueColor: Colors.teal,
        ),
        MeasurementField(
          label: 'PR',
          value: '90',
          unit: 'bpm.',
          valueColor: Colors.teal,
        ),
      ],
    );
  }

  // Get device data by name
  static DeviceDetailData? getDeviceData(String deviceName) {
    switch (deviceName) {
      case 'Ear Thermometer':
        return getEarThermometerData();
      case 'Jumper Pulse':
        return getJumperPulseData();
      case 'MI scale 2':
        return getMIScale2Data();
      case 'Thermometer':
        return getThermometerData();
      case 'Yuwell Glucometer':
        return getYuwellGlucometerData();
      case 'Yuwell SpO2':
        return getYuwellSpO2Data();
      case 'Yuwell YE860A':
        return getYuwellYE860AData();
      case 'Yuwell YE992':
        return getYuwellYE992Data();
      default:
        return null;
    }
  }
}
