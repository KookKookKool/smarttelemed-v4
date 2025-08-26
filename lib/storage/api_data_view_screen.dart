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
  Map<String, dynamic>? _idCardData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final careUnitData = await CareUnitStorage.loadCareUnitData();
    final idCardData = await IdCardStorage.loadIdCardData();
    setState(() {
      _careUnitData = careUnitData;
      _idCardData = idCardData;
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
          : (_careUnitData == null && _idCardData == null)
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
                    // ID Card Data Section
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
                                  'ข้อมูลบัตรประชาชน',
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
