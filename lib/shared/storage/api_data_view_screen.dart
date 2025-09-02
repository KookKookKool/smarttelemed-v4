import 'package:flutter/material.dart';
import 'dart:convert';
import 'storage.dart';

class ApiDataViewScreen extends StatefulWidget {
  const ApiDataViewScreen({Key? key}) : super(key: key);

  @override
  State<ApiDataViewScreen> createState() => _ApiDataViewScreenState();
}

class _ApiDataViewScreenState extends State<ApiDataViewScreen> {
  Map<String, dynamic>? _careUnitData;
  Map<String, dynamic>? _idCardData; // ข้อมูลบัตรอสม.
  Map<String, dynamic>? _patientIdCardData; // ข้อมูลบัตรผู้ป่วย
  List<Map<String, dynamic>> _vitalsData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final careUnitData = await CareUnitStorage.loadCareUnitData();
    final idCardData = await IdCardStorage.loadIdCardData(); // อสม.
    final patientIdCardData =
        await PatientIdCardStorage.loadPatientIdCardData(); // ผู้ป่วย
    final vitalsData = await VitalsStorage.loadVitalsData();
    setState(() {
      _careUnitData = careUnitData;
      _idCardData = idCardData;
      _patientIdCardData = patientIdCardData;
      _vitalsData = vitalsData;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลที่เก็บไว้'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_careUnitData == null &&
                _idCardData == null &&
                _patientIdCardData == null &&
                _vitalsData.isEmpty)
          ? const Center(
              child: Text(
                'ไม่มีข้อมูลที่เก็บไว้',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID Card Data Section (อสม.)
                    if (_idCardData != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  color: Colors.green.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ข้อมูลบัตรประชาชน อสม.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildIdCardInfo(_idCardData!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Patient ID Card Data Section (ผู้ป่วย)
                    if (_patientIdCardData != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_hospital,
                                  color: Colors.purple.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ข้อมูลบัตรประชาชนผู้ป่วย',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildIdCardInfo(_patientIdCardData!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Vitals Data Section
                    if (_vitalsData.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.monitor_heart,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ข้อมูลสัญญาณชีพ (${_vitalsData.length} รายการ)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildVitalsInfo(_vitalsData),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Care Unit API Data Section
                    if (_careUnitData != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.api, color: Colors.blue.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'ข้อมูล Care Unit API',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildJsonViewer(_careUnitData!),
                          ],
                        ),
                      ),
                    ],

                    // Refresh Button
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('รีเฟรชข้อมูล'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVitalsInfo(List<Map<String, dynamic>> vitalsDataList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // แสดงข้อมูลล่าสุด
        if (vitalsDataList.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อมูลล่าสุด',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSingleVitalInfo(vitalsDataList.last),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // รายการทั้งหมด
        ExpansionTile(
          title: Text(
            'ประวัติการส่งข้อมูลทั้งหมด (${vitalsDataList.length} รายการ)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          children: vitalsDataList.asMap().entries.map((entry) {
            final index = entry.key;
            final vitals = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รายการที่ ${vitalsDataList.length - index}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSingleVitalInfo(vitals),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSingleVitalInfo(Map<String, dynamic> vitals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // สัญญาณชีพ
        if (vitals['bpSys'] != null || vitals['bpDia'] != null)
          _buildInfoRow(
            'ความดันโลหิต',
            '${vitals['bpSys'] ?? '-'}/${vitals['bpDia'] ?? '-'} mmHg',
          ),

        if (vitals['pr'] != null)
          _buildInfoRow('อัตราการเต้นของหัวใจ', '${vitals['pr']} bpm'),

        if (vitals['rr'] != null)
          _buildInfoRow('อัตราการหายใจ', '${vitals['rr']} /min'),

        if (vitals['spo2'] != null)
          _buildInfoRow('ออกซิเจนในเลือด', '${vitals['spo2']} %'),

        if (vitals['bt'] != null)
          _buildInfoRow('อุณหภูมิร่างกาย', '${vitals['bt']} °C'),

        if (vitals['dtx'] != null)
          _buildInfoRow('ระดับน้ำตาลในเลือด', '${vitals['dtx']} mg/dL'),

        if (vitals['bw'] != null)
          _buildInfoRow('น้ำหนัก', '${vitals['bw']} kg'),

        if (vitals['h'] != null) _buildInfoRow('ส่วนสูง', '${vitals['h']} cm'),

        // ข้อมูลระบบ
        if (vitals['submitTime'] != null)
          _buildInfoRow('เวลาที่ส่งข้อมูล', vitals['submitTime']),

        if (vitals['careUnitId'] != null)
          _buildInfoRow('Care Unit ID', vitals['careUnitId']),

        // แสดงข้อมูลทั้งหมดในรูปแบบ JSON
        const SizedBox(height: 8),
        ExpansionTile(
          title: const Text(
            'ข้อมูลทั้งหมด (JSON)',
            style: TextStyle(fontSize: 12),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _prettyPrintJson(vitals),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdCardInfo(Map<String, dynamic> data) {
    // Extract common ID card fields
    final idCard = data['idCard'] ?? '';
    final prefix = data['prefix'] ?? '';
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final fullName = data['fullName'] ?? '$prefix $firstName $lastName'.trim();
    final address = data['address'] ?? '';
    final birthDate = data['birthDate'] ?? '';
    final saveTime = data['saveTime'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (idCard.isNotEmpty) _buildInfoRow('เลขบัตรประชาชน', idCard),
        if (fullName.isNotEmpty) _buildInfoRow('ชื่อ-นามสกุล', fullName),
        if (birthDate.isNotEmpty) _buildInfoRow('วันเกิด', birthDate),
        if (address.isNotEmpty) _buildInfoRow('ที่อยู่', address),
        if (saveTime.isNotEmpty) _buildInfoRow('วันที่บันทึก', saveTime),

        // Show raw data in expandable section
        const SizedBox(height: 12),
        ExpansionTile(
          title: const Text(
            'ข้อมูลทั้งหมด (JSON)',
            style: TextStyle(fontSize: 14),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _prettyPrintJson(data),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJsonViewer(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _prettyPrintJson(data),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    try {
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }
}
