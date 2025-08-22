import 'dart:convert';
import 'package:http/http.dart' as http;

class CareUnitApi {
  static const String apiUrl =
      'https://emr-life.com/clinic_master/clinic/Api/list_care_unit';

  // ส่ง code ไปยัง API และรับข้อมูลกลับ
  static Future<Map<String, dynamic>?> fetchCareUnit(String code) async {
    final trimmed = code.trim();
    Map<String, dynamic>? lastDecoded;
    try {
      final attempts = <Map<String, dynamic>>[
        {
          'note': 'exact web simulation with session/cookie headers',
          'headers': {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'X-Requested-With': 'XMLHttpRequest',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/115.0.0.0 Safari/537.36',
            'Referer': 'https://expert.emr-life.com/telemed/Mobile/client',
            'Origin': 'https://expert.emr-life.com',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'cross-site',
            // Note: Add actual session cookies here if you can get them from browser dev tools
            // 'Cookie': 'PHPSESSID=abc123; other_session=xyz',
          },
          'rawBody': 'code=$trimmed',
        },
        {
          'note': 'raw x-www-form-urlencoded with full browser headers',
          'headers': {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'X-Requested-With': 'XMLHttpRequest',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/115.0.0.0 Safari/537.36',
            'Referer': 'https://emr-life.com/clinic_master/clinic',
            'Origin': 'https://emr-life.com',
            'Accept-Language': 'en-US,en;q=0.9',
            // If you need to copy cookies from the browser, add them here when testing
            // 'Cookie': 'session=...'
          },
          // send as raw string instead of a Map so encoding/format exactly matches browser
          'rawBody': 'code=$trimmed',
        },
        {
          'note': 'simple x-www-form-urlencoded',
          'headers': {'Content-Type': 'application/x-www-form-urlencoded'},
          'body': {'code': trimmed},
        },
        {
          'note': 'with X-Requested-With and User-Agent',
          'headers': {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-Requested-With': 'XMLHttpRequest',
            'User-Agent': 'Mozilla/5.0',
          },
          'body': {'code': trimmed},
        },
        {
          'note': 'with Referer',
          'headers': {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-Requested-With': 'XMLHttpRequest',
            'User-Agent': 'Mozilla/5.0',
            'Referer': 'https://emr-life.com/clinic_master/clinic',
          },
          'body': {'code': trimmed},
        },
      ];

      for (var i = 0; i < attempts.length; i++) {
        final a = attempts[i];
        print('Attempt ${i + 1}: ${a['note']}');
        print('Headers: ${a['headers']}');
        print('Body: code=$trimmed');
        // decide whether to send raw string body or Map body
        final headers = Map<String, String>.from(a['headers'] as Map);
        final bodyObj = a.containsKey('rawBody')
            ? (a['rawBody'] as String)
            : (a['body'] as Map<String, String>);

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: bodyObj,
        );
        print('HTTP ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
        if (response.statusCode == 200) {
          try {
            final decoded = json.decode(response.body) as Map<String, dynamic>;
            lastDecoded = decoded;
            if (decoded['message'] == 'success' &&
                decoded['data'] is List &&
                (decoded['data'] as List).isNotEmpty) {
              print('Got success on attempt ${i + 1}');
              return decoded;
            }
          } catch (e) {
            print('JSON decode error: $e');
          }
        }
      }

      // Fallback: try GET with query param
      print('Fallback: trying GET with query param');
      final getUri = Uri.parse(
        '$apiUrl?code=${Uri.encodeQueryComponent(trimmed)}',
      );
      print('GET $getUri');
      final getResp = await http.get(
        getUri,
        headers: {'Accept': 'application/json'},
      );
      print('HTTP ${getResp.statusCode}');
      print('Response body: ${getResp.body}');
      if (getResp.statusCode == 200) {
        try {
          final decoded = json.decode(getResp.body) as Map<String, dynamic>;
          lastDecoded = decoded;
          if (decoded['message'] == 'success' &&
              decoded['data'] is List &&
              (decoded['data'] as List).isNotEmpty) {
            print('Got success from GET fallback');
            return decoded;
          }
        } catch (e) {
          print('JSON decode error (GET): $e');
        }
      }

      return lastDecoded;
    } catch (e) {
      print('API error: $e');
      return null;
    }
  }
}
