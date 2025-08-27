import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'video_config.dart';

class AutoLoginHandler {
  static String get apiAuthHeader {
    return base64Encode(
      utf8.encode(
        '${VideoConfig.defaultUserId}:${VideoConfig.defaultPassword}',
      ),
    );
  }

  String get multiMethodAutoLoginScript =>
      '''
    (function() {
      'use strict';
      console.log('🚀 Starting enhanced multi-method auto-login...');
      
      // Prevent script conflicts by using unique timestamp
      const currentTime = Date.now();
      if (window.autoLoginInitialized && (currentTime - window.autoLoginInitialized) < 15000) {
        console.log('🔄 Auto-login already initialized recently, skipping...');
        return;
      }
      window.autoLoginInitialized = currentTime;
      
      // Reset join status เมื่อเริ่มใหม่
      window.joinedSuccessfully = false;
      console.log('🔄 Reset join status for new attempt');
      
      // Enhanced auto-join function with join success detection
      function performAggressiveAutoJoin() {
        // ถ้าเข้าห้องสำเร็จแล้ว ไม่ต้องลอง join อีก
        if (window.joinedSuccessfully) {
          console.log('🎯 Already joined successfully, skipping auto-join...');
          return false;
        }
        
        // ตรวจสอบว่าอยู่ในห้องแล้วหรือไม่ (ตรวจให้แม่นยำมากขึ้น)
        // ต้องมีทั้ง video elements ที่มี srcObject และ UI ที่แสดงว่าเข้าสู่ session แล้ว
        const activeVideos = document.querySelectorAll('video[srcObject]:not([srcObject=""])');
        const participantContainers = document.querySelectorAll('.participant-container:not(:empty), .video-participant:not(:empty)');
        const sessionUI = document.querySelector('.session-active, .in-session, .room-joined');
        const callEndButton = document.querySelector('#leave-btn, button[id*="leave"], button[class*="leave"]');
        
        // ถ้ามีปุ่ม call_end แสดงว่าอยู่ในห้องแล้ว หรือมีวิดีโอที่ทำงานจริงๆ
        if (callEndButton || (activeVideos.length > 0 && (participantContainers.length > 0 || sessionUI))) {
          console.log('🎯 Detected active video session - already in room, skipping auto-join');
          window.joinedSuccessfully = true;
          if (window.VideoCallChannel) {
            window.VideoCallChannel.postMessage('room_joined_successfully');
          }
          return true;
        }
        
        console.log('🎯 ENHANCED aggressive auto-join attempt...');
        
        // Debug: ดูว่ามี element อะไรบ้าง
        const allElements = document.querySelectorAll('button, input[type="submit"], a, div[role="button"]');
        console.log('🔍 Found', allElements.length, 'clickable elements');
        
        // Strategy 1: Look for exact text matches
        const joinTexts = ['join room', 'join the room', 'เข้าร่วมห้อง', 'join', 'connect', 'start', 'enter room', 'join session'];
        for (const text of joinTexts) {
          const buttons = Array.from(allElements);
          for (const btn of buttons) {
            if (btn && btn.offsetParent !== null && 
                btn.textContent && btn.textContent.toLowerCase().includes(text.toLowerCase())) {
              console.log('✅ Found join button by text:', btn.textContent, 'attempting click...');
              
              // Multiple click strategies
              try {
                btn.disabled = false;
                btn.style.display = 'block';
                btn.style.visibility = 'visible';
                btn.style.pointerEvents = 'auto';
                
                btn.click();
                btn.dispatchEvent(new MouseEvent('click', {bubbles: true, cancelable: true}));
                btn.dispatchEvent(new Event('submit', {bubbles: true}));
                
                console.log('🎯 Join button clicked successfully!');
                if (window.VideoCallChannel) {
                  window.VideoCallChannel.postMessage('auto_join_success');
                }
                
                // รอสักพักแล้วตรวจสอบว่าเข้าห้องสำเร็จหรือไม่ (ตรวจให้แม่นยำมากขึ้น)
                setTimeout(() => {
                  const activeVideos = document.querySelectorAll('video[srcObject]:not([srcObject=""])');
                  const participantContainers = document.querySelectorAll('.participant-container:not(:empty), .video-participant:not(:empty)');
                  const sessionUI = document.querySelector('.session-active, .in-session, .room-joined');
                  const callEndButton = document.querySelector('#leave-btn, button[id*="leave"], button[class*="leave"]');
                  
                  // ถ้ามีปุ่ม call_end แสดงว่าอยู่ในห้องแล้ว
                  if ((activeVideos.length > 0 && (participantContainers.length > 0 || sessionUI)) || callEndButton) {
                    window.joinedSuccessfully = true;
                    console.log('🎯 Join successful, stopping auto-join attempts');
                    if (window.VideoCallChannel) {
                      window.VideoCallChannel.postMessage('room_joined_successfully');
                    }
                  }
                }, 5000); // เพิ่มเวลารอให้ session โหลดเสร็จ
                
                return true;
              } catch (error) {
                console.log('❌ Error clicking join button:', error);
              }
            }
          }
        }
        
        // Debug: แสดงปุ่มทั้งหมดที่เจอ
        console.log('🔍 All visible buttons:');
        allElements.forEach((btn, index) => {
          if (btn && btn.offsetParent !== null) {
            console.log(\`Button \${index}: "\${btn.textContent}" class="\${btn.className}" id="\${btn.id}"\`);
          }
        });
        
        // Strategy 2: Look for largest visible button (แต่ห้าม click ปุ่มวางสาย)
        const allButtons = Array.from(allElements);
        let largestButton = null;
        let largestSize = 0;
        
        for (const btn of allButtons) {
          if (btn && btn.offsetParent !== null && !btn.disabled) {
            // ห้าม click ปุ่มวางสาย/leave
            const isLeaveButton = btn.textContent.toLowerCase().includes('call_end') ||
                                 btn.textContent.toLowerCase().includes('leave') ||
                                 btn.textContent.toLowerCase().includes('end') ||
                                 btn.textContent.toLowerCase().includes('disconnect') ||
                                 btn.id.includes('leave') ||
                                 btn.id.includes('end') ||
                                 btn.className.includes('leave') ||
                                 btn.className.includes('end');
            
            if (!isLeaveButton) {
              const rect = btn.getBoundingClientRect();
              const size = rect.width * rect.height;
              if (size > largestSize) {
                largestSize = size;
                largestButton = btn;
              }
            }
          }
        }
        
        if (largestButton && largestSize > 1000) {
          console.log('✅ Found largest button, attempting click:', largestButton.textContent);
          try {
            largestButton.click();
            return true;
          } catch (error) {
            console.log('❌ Error clicking largest button:', error);
          }
        }
        
        console.log('❌ No join buttons found in this attempt');
        return false;
      }
      
      // ลบการตรวจจับการจบสายออก เพื่อไม่ให้วางสายเอง
      
      // Form login functionality
      function tryFormLogin() {
        console.log('📝 Trying form login...');
        
        // Find username/email fields
        const usernameSelectors = [
          'input[name="username"]', 'input[name="email"]', 'input[id="username"]',
          'input[id="email"]', 'input[type="text"]', 'input[placeholder*="user" i]'
        ];
        
        let usernameField = null;
        for (const selector of usernameSelectors) {
          usernameField = document.querySelector(selector);
          if (usernameField && usernameField.offsetParent !== null) break;
        }
        
        // Find password fields
        const passwordSelectors = [
          'input[name="password"]', 'input[id="password"]', 'input[type="password"]'
        ];
        
        let passwordField = null;
        for (const selector of passwordSelectors) {
          passwordField = document.querySelector(selector);
          if (passwordField && passwordField.offsetParent !== null) break;
        }
        
        if (usernameField && passwordField) {
          usernameField.value = '${VideoConfig.defaultUserId}';
          passwordField.value = '${VideoConfig.defaultPassword}';
          
          // Trigger events
          usernameField.dispatchEvent(new Event('input', { bubbles: true }));
          passwordField.dispatchEvent(new Event('input', { bubbles: true }));
          
          console.log('✅ Credentials filled');
          
          // Find and click submit button
          setTimeout(() => {
            const submitButtons = document.querySelectorAll('button[type="submit"], input[type="submit"], button');
            for (const btn of submitButtons) {
              if (btn && btn.offsetParent !== null && 
                  (btn.textContent.toLowerCase().includes('login') ||
                   btn.textContent.toLowerCase().includes('submit') ||
                   btn.textContent.toLowerCase().includes('join') ||
                   btn.type === 'submit')) {
                console.log('✅ Form submitted');
                btn.click();
                
                // Wait and try auto-join after form submission
                setTimeout(performAggressiveAutoJoin, 2000);
                break;
              }
            }
          }, 500);
        }
      }
      
      // Storage authentication
      function tryStorageAuth() {
        console.log('💾 Trying storage auth...');
        try {
          localStorage.setItem('username', '${VideoConfig.defaultUserId}');
          localStorage.setItem('password', '${VideoConfig.defaultPassword}');
          sessionStorage.setItem('username', '${VideoConfig.defaultUserId}');
          sessionStorage.setItem('password', '${VideoConfig.defaultPassword}');
          console.log('✅ Storage auth set');
        } catch (error) {
          console.log('❌ Storage auth failed:', error);
        }
      }
      
      // Execute all methods
      tryStorageAuth();
      
      // Try form login multiple times
      setTimeout(tryFormLogin, 1000);
      setTimeout(tryFormLogin, 3000);
      setTimeout(tryFormLogin, 5000);
      
      // Multiple auto-join attempts with increasing delays (เพิ่มการรอให้หน้าโหลดเสร็จ)
      const joinAttempts = [5000, 8000, 12000, 16000, 20000]; // เพิ่มเวลารอ
      joinAttempts.forEach((delay, index) => {
        setTimeout(() => {
          console.log(\`🎯 Auto-join attempt \${index + 1}...\`);
          performAggressiveAutoJoin();
        }, delay);
      });
      
      // Continuous monitoring เฉพาะ auto-join เท่านั้น (ไม่ตรวจจับการจบสาย)
      setInterval(() => {
        // Only try to join if not already joined และยังไม่พ้นเวลา timeout
        if (!window.joinedSuccessfully && (Date.now() - currentTime) < 60000) { // timeout 60 วินาที
          // ตรวจสอบอีกครั้งว่าอยู่ในห้องแล้วหรือไม่
          const callEndButton = document.querySelector('#leave-btn, button[id*="leave"], button[class*="leave"]');
          if (callEndButton) {
            console.log('🎯 Detected call end button - already in room, stopping auto-join');
            window.joinedSuccessfully = true;
            if (window.VideoCallChannel) {
              window.VideoCallChannel.postMessage('room_joined_successfully');
            }
            return;
          }
          
          performAggressiveAutoJoin();
        } else if (window.joinedSuccessfully) {
          console.log('🎯 Already joined successfully - auto-join stopped');
        }
        // ลบการตรวจจับการจบสายออกเพื่อไม่ให้วางสายเอง
      }, 3000);
      
    })();
  ''';

  Future<void> aggressiveAutoJoin() async {
    if (kDebugMode) {
      print('🎯 Starting aggressive auto-join...');
    }
  }
}
