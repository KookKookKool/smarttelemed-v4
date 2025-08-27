import 'dart:convert';
import 'dart:io';

void main() async {
  final openViduUrl = 'https://conference.pcm-life.com';
  final credentials = [
    'OPENVIDUAPP:MY_SECRET',
    'OPENVIDUAPP:minadadmin',
    'admin:admin',
    'admin:minadadmin',
    'minadadmin:minadadmin',
    'openviduapp:MY_SECRET',
    'admin:MY_SECRET',
    'admin:password',
    'root:password',
    'user:password',
  ];

  print('🔍 กำลังทดสอบ OpenVidu authentication...');
  print('🌐 Server: $openViduUrl');
  print('');

  for (String credential in credentials) {
    final username = credential.split(':')[0];
    print('🔑 ลอง credential: $username');

    try {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) =>
          true; // ถ้าเป็น self-signed cert

      final request = await client.postUrl(
        Uri.parse('$openViduUrl/openvidu/api/sessions'),
      );

      final authString = base64Encode(utf8.encode(credential));
      request.headers.set('Authorization', 'Basic $authString');
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({'customSessionId': 'test-session-auth'});
      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('   📡 Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 409) {
        print('   ✅ สำเร็จ! credential ที่ใช้ได้: $credential');
        print('   📝 Response: $responseBody');
        print('');
        print('🎉 เจอ credential ที่ใช้ได้แล้ว!');
        break;
      } else if (response.statusCode == 401) {
        print('   ❌ Unauthorized');
      } else {
        print('   ⚠️  Status ${response.statusCode}: $responseBody');
      }

      client.close();
    } catch (e) {
      print('   💥 Error: $e');
    }

    print('');
  }

  print('🏁 เสร็จสิ้นการทดสอบ');
}
