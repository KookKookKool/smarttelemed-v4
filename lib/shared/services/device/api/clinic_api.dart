import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smarttelemed_v4/core/device/dashboard/vitals.dart';

class ClinicResponse {
  final bool ok;
  final int status;
  final String body;
  ClinicResponse(this.ok, this.status, this.body);
}

class ClinicApi {
  /// ส่งรายการเดียวไปที่ /add_hr (form-url-encoded เหมือนฟอร์มในรูป)
  static Future<ClinicResponse> addHealthRecord({
    required String url,            // e.g. https://emr-life.com/clinic_master/clinicApi/add_hr
    required Vitals vitals,
    String? careUnitId,
    String? publicId,
    String? recepPublicId,
    String? cc,
  }) async {
    // คำนวน BMI ถ้าไม่ได้กรอก
    double? bmi;
    final bw = vitals.bw;
    final hCm = vitals.h;
    if (bw != null && hCm != null && hCm > 0) {
      final hM = hCm / 100.0;
      bmi = double.parse((bw / (hM * hM)).toStringAsFixed(1));
    }

    String? bpCombined;
    if (vitals.bpSys != null && vitals.bpDia != null) {
      bpCombined = '${vitals.bpSys}/${vitals.bpDia}';
    }

    Map<String, String> body = {};
    void put(String k, Object? v) { if (v != null && v.toString().isNotEmpty) body[k] = v.toString(); }

    // meta
    put('care_unit_id',  careUnitId);
    put('public_id',     publicId);
    put('recep_public_id', recepPublicId);
    put('cc', cc);

    // vitals
    put('temp',     vitals.bt);
    put('pulse_rate', vitals.pr);
    put('rr',       vitals.rr);
    put('spo2',     vitals.spo2);
    put('bp_sys',   vitals.bpSys);
    put('bp_dia',   vitals.bpDia);
    put('bp',       bpCombined);
    put('weight',   vitals.bw);
    put('height',   vitals.h);
    put('bmi',      bmi);
    put('fbs',      vitals.dtx);   // ใช้ dtx เป็นน้ำตาลปลายนิ้ว (mg/dL)

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    return ClinicResponse(res.statusCode >= 200 && res.statusCode < 300, res.statusCode, res.body);
  }

  /// (เผื่อใช้ทีหลัง) ส่งแบบลิสต์ ไป /add_hr_list  โดยใส่ key 'records' เป็น JSON string
  static Future<ClinicResponse> addHealthRecordList({
    required String url,            // https://emr-life.com/clinic_master/clinicApi/add_hr_list
    required List<Map<String, dynamic>> records,
  }) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'records': jsonEncode(records)},
    );
    return ClinicResponse(res.statusCode >= 200 && res.statusCode < 300, res.statusCode, res.body);
  }
}
