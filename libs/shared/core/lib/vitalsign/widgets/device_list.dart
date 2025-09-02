import 'package:flutter/material.dart';
import '../device/device_detail_screen.dart';
import '../device/widgets/device_widgets.dart';

class DeviceList extends StatelessWidget {
  const DeviceList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final devices = [
      DeviceData(
        name: 'เครื่องวัดความดัน',
        model: 'Yuwell YE860A',
        value: '140 / 90',
        unit: '(65) mmHg',
        secondValue: '76',
        secondUnit: 'bpm',
        image: 'assets/yuwell_ye860a.png',
        detailKey: 'Yuwell YE860A',
      ),
      DeviceData(
        name: 'เครื่องวัดออกซิเจนปลายนิ้ว',
        model: 'Yuwell spo2',
        value: '99',
        unit: '%',
        secondValue: '76',
        secondUnit: 'bpm',
        image: 'assets/yuwell_spo2.png',
        detailKey: 'Yuwell SpO2',
      ),
      DeviceData(
        name: 'เครื่องวัดอุณหภูมิ',
        model: 'Thermometer',
        value: '36.7',
        unit: '°C',
        secondValue: '',
        secondUnit: '',
        image: 'assets/thermometer.png',
        detailKey: 'Thermometer',
      ),
      DeviceData(
        name: 'เครื่องวัดอุณหภูมิ',
        model: 'Temp',
        value: '90',
        unit: 'mg%',
        secondValue: '',
        secondUnit: '',
        image: 'assets/temp_device.png',
        detailKey: 'Yuwell Glucometer',
      ),
      DeviceData(
        name: 'เครื่องชั่งน้ำหนัก',
        model: 'MI scale 2',
        value: '66',
        unit: 'Kg',
        secondValue: '',
        secondUnit: '',
        image: 'assets/mi_scale2.png',
        detailKey: 'MI scale 2',
      ),
      DeviceData(
        name: 'เครื่องวัดความดัน',
        model: 'Aquarius',
        value: '140 / 90',
        unit: '(65) mmHg',
        secondValue: '76',
        secondUnit: 'bpm',
        image: 'assets/aquarius.png',
        detailKey: 'Yuwell YE860A',
      ),
      DeviceData(
        name: 'เครื่องวัดความดัน',
        model: 'Yuwell YE992',
        value: '140 / 90',
        unit: '(65) mmHg',
        secondValue: '76',
        secondUnit: 'bpm',
        image: 'assets/yuwell_ye992.png',
        detailKey: 'Yuwell YE992',
      ),
      DeviceData(
        name: 'เครื่องวัดอุณหภูมิ',
        model: 'Temp',
        value: '99',
        unit: '%',
        secondValue: '76',
        secondUnit: 'bpm',
        image: 'assets/temp2.png',
        detailKey: 'Jumper Pulse',
      ),
      DeviceData(
        name: 'เครื่องวัดอุณหภูมิ',
        model: 'Ear Thermometer',
        value: '36.7',
        unit: '°C',
        secondValue: '',
        secondUnit: '',
        image: 'assets/ear_thermometer.png',
        detailKey: 'Ear Thermometer',
      ),
      DeviceData(
        name: 'เครื่องชั่งน้ำหนัก/วัดส่วนสูง',
        model: 'WHT',
        value: '',
        unit: '',
        secondValue: '',
        secondUnit: '',
        image: 'assets/wht.png',
        detailKey: 'MI scale 2',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            top: 16,
            bottom: 8,
            right: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(Icons.add, color: Colors.teal, size: 24),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            return DeviceCard(device: devices[index]);
          },
        ),
      ],
    );
  }
}

class DeviceData {
  final String name;
  final String model;
  final String value;
  final String unit;
  final String secondValue;
  final String secondUnit;
  final String image;
  final String detailKey;

  DeviceData({
    required this.name,
    required this.model,
    required this.value,
    required this.unit,
    required this.secondValue,
    required this.secondUnit,
    required this.image,
    required this.detailKey,
  });
}

class DeviceCard extends StatelessWidget {
  final DeviceData device;

  const DeviceCard({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final deviceDetailData = DeviceWidgets.getDeviceData(
            device.detailKey,
          );
          if (deviceDetailData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DeviceDetailScreen(deviceData: deviceDetailData),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Device Image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.devices_other,
                  color: Colors.grey[400],
                  size: 24,
                ),
                // TODO: Replace with actual image
                // child: Image.asset(device.image, fit: BoxFit.contain),
              ),
              const SizedBox(width: 16),
              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.model,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Values
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (device.value.isNotEmpty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          device.value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (device.secondValue.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            device.secondValue,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (device.unit.isNotEmpty)
                          Text(
                            device.unit,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        if (device.secondUnit.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            device.secondUnit,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
