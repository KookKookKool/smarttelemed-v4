// Test WebView camera permissions
import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/core/video/webview_video_call.dart';

class TestWebViewCameraPage extends StatelessWidget {
  const TestWebViewCameraPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test WebView Camera'),
        backgroundColor: Colors.blue,
      ),
      body: WebViewVideoCall(
        webViewUrl:
            'https://conference.pcm-life.com/?sessionName=Telemed-Test&user=minadadmin&password=minadadmin',
        onCallEnded: () {
          print('Call ended from test page');
          Navigator.pop(context);
        },
        onError: (error) {
          print('WebView error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      ),
    );
  }
}
