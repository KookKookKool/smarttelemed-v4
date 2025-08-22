import 'dart:convert';
import 'package:http/http.dart' as http;

class CareUnitApi {
  static const String apiUrl =
      'https://emr-life.com/clinic_master/clinic/Api/list_care_unit';

  // ทดสอบส่งแบบง่ายๆ เหมือนหน้าเว็บ
  static Future<Map<String, dynamic>?> fetchCareUnitSimple(String code) async {
    final trimmed = code.trim();
    print('=== Simple Web-like Request ===');
    print('URL: $apiUrl');
    print('Method: POST');
    print('Body: code=$trimmed');
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': '*/*',
        },
        body: 'code=$trimmed',
      );
      
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return decoded;
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  // ส่ง code ไปยัง API และรับข้อมูลกลับ - พยายามทุกวิธี
  static Future<Map<String, dynamic>?> fetchCareUnit(String code) async {
    final trimmed = code.trim();
    print('=== CareUnit API Call ===');
    print('Code: $trimmed');
    
    // ลองหลายวิธี เพื่อให้ได้ข้อมูล
    final attempts = [
      {
        'name': 'Simple POST',
        'headers': {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        'body': 'code=$trimmed',
      },
      {
        'name': 'Browser-like with Session',
        'headers': {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://expert.emr-life.com/telemed/Mobile/client',
          'Origin': 'https://expert.emr-life.com',
          'Accept-Language': 'th-TH,th;q=0.9,en;q=0.8',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        'body': 'code=$trimmed',
      },
      {
        'name': 'Alternative Origin',
        'headers': {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://emr-life.com/clinic_master/clinic',
          'Origin': 'https://emr-life.com',
        },
        'body': 'code=$trimmed',
      },
    ];
    
    try {
      for (int i = 0; i < attempts.length; i++) {
        final attempt = attempts[i];
        print('\n--- Attempt ${i + 1}: ${attempt['name']} ---');
        print('Headers: ${attempt['headers']}');
        print('Body: ${attempt['body']}');
        
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: Map<String, String>.from(attempt['headers'] as Map),
          body: attempt['body'] as String,
        );
        
        print('HTTP Status: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          try {
            final decoded = json.decode(response.body) as Map<String, dynamic>;
            print('Parsed JSON: $decoded');
            
            // ถ้าเป็น success ให้ return ทันที
            if (decoded['message'] == 'success') {
              print('🎉 SUCCESS on attempt ${i + 1}!');
              return decoded;
            }
            
            // ถ้าไม่ success แต่มีข้อมูล ให้เก็บไว้
            if (i == attempts.length - 1) {
              print('⚠️ All attempts done, returning last result');
              return decoded;
            }
          } catch (e) {
            print('JSON Parse Error: $e');
          }
        } else {
          print('HTTP Error: ${response.statusCode}');
        }
        
        // รอหน่อยก่อนลองใหม่
        if (i < attempts.length - 1) {
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
      
      print('❌ All attempts failed');
      return null;
    } catch (e) {
      print('Network Error: $e');
      return null;
    }
  }
}
