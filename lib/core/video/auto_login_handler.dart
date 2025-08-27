// lib/core/video/auto_login_handler.dart
import 'dart:convert';
import 'package:smarttelemed_v4/core/video/video_config.dart';

class AutoLoginHandler {
  /// สร้าง URL พร้อม credentials แบบต่างๆ
  static String buildAuthenticatedUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final newUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'username': VideoConfig.defaultUserId,
      'password': VideoConfig.defaultPassword,
      'room': 'telemed_test',
    });
    return newUri.toString();
  }

  /// สร้าง headers สำหรับ Basic Auth
  static Map<String, String> buildAuthHeaders() {
    final credentials = base64Encode(utf8.encode(
        '${VideoConfig.defaultUserId}:${VideoConfig.defaultPassword}'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
  }

  /// JavaScript สำหรับ auto-login หลายแบบ
  static String get multiMethodAutoLoginScript {
    return '''
    console.log('Starting multi-method auto-login...');
    
    function tryFormLogin() {
      console.log('Trying form login...');
      
      const usernameSelectors = [
        'input[name="username"]',
        'input[name="email"]',
        'input[id="username"]',
        'input[id="email"]',
        'input[type="text"]'
      ];
      
      let usernameField = null;
      for (const selector of usernameSelectors) {
        usernameField = document.querySelector(selector);
        if (usernameField && usernameField.offsetParent !== null) break;
      }
      
      const passwordSelectors = [
        'input[name="password"]',
        'input[id="password"]',
        'input[type="password"]'
      ];
      
      let passwordField = null;
      for (const selector of passwordSelectors) {
        passwordField = document.querySelector(selector);
        if (passwordField && passwordField.offsetParent !== null) break;
      }
      
      const roomSelectors = [
        'input[name="room"]',
        'input[name="roomName"]',
        'input[id="room"]',
        'input[id="roomName"]'
      ];
      
      let roomField = null;
      for (const selector of roomSelectors) {
        roomField = document.querySelector(selector);
        if (roomField && roomField.offsetParent !== null) break;
      }
      
      if (usernameField && passwordField) {
        usernameField.value = '${VideoConfig.defaultUserId}';
        passwordField.value = '${VideoConfig.defaultPassword}';
        
        if (roomField) {
          roomField.value = 'telemed_test';
          roomField.dispatchEvent(new Event('input', { bubbles: true }));
        }
        
        usernameField.dispatchEvent(new Event('input', { bubbles: true }));
        passwordField.dispatchEvent(new Event('input', { bubbles: true }));
        
        console.log('Credentials filled');
        
        setTimeout(() => {
          const submitButton = document.querySelector('button[type="submit"], input[type="submit"], .submit-btn, .login-btn');
          if (submitButton) {
            submitButton.click();
            console.log('Submit button clicked');
          }
        }, 500);
        
        return true;
      }
      return false;
    }
    
    function tryStorageAuth() {
      console.log('Trying storage auth...');
      try {
        localStorage.setItem('username', '${VideoConfig.defaultUserId}');
        localStorage.setItem('password', '${VideoConfig.defaultPassword}');
        localStorage.setItem('roomName', 'telemed_test');
        sessionStorage.setItem('user', '${VideoConfig.defaultUserId}');
        sessionStorage.setItem('room', 'telemed_test');
        console.log('Storage auth set');
      } catch (e) {
        console.log('Storage auth failed:', e);
      }
    }
    
    setTimeout(() => {
      tryStorageAuth();
      if (!tryFormLogin()) {
        setTimeout(tryFormLogin, 1000);
        setTimeout(tryFormLogin, 2000);
      }
    }, 500);
    ''';
  }
}
