// lib/core/video/README.md

# Video Call System with OpenVidu

ระบบ Video Call ที่ใช้ OpenVidu สำหรับ SmartTelemed V4

## ไฟล์ที่สำคัญ

### 1. `videocall_screen.dart`

หน้าจอหลักสำหรับ Video Call ที่มีคุณสมบัติ:

- เชื่อมต่อกับ OpenVidu server
- ควบคุมไมโครโฟนและกล้อง
- แสดงสถานะการเชื่อมต่อ
- จัดการ error และ retry

### 2. `openvidu_service.dart`

Service สำหรับจัดการการเชื่อมต่อกับ OpenVidu:

- สร้าง session และ token
- ตรวจสอบการเชื่อมต่อ
- สร้าง URL สำหรับ WebView

### 3. `video_call_manager.dart`

Manager สำหรับจัดการสถานะ Video Call:

- ตัวจัดการสถานะการโทร (idle, connecting, connected, etc.)
- ควบคุมการเปิด/ปิดเสียงและวิดีโอ
- Notify listeners เมื่อสถานะเปลี่ยน

### 4. `webview_video_call.dart`

Widget WebView สำหรับแสดง OpenVidu interface:

- โหลด OpenVidu web application
- จัดการ JavaScript communication
- แสดง loading และ error states

### 5. `video_config.dart`

Configuration และ constants:

- URL ของ OpenVidu server
- ข้อความ error ภาษาไทย
- การตั้งค่าต่างๆ

### 6. `video_utils.dart`

Utility functions:

- สร้าง participant name ที่ unique
- เข้า/ถอดรหัส token
- แปลง error messages
- ตรวจสอบการเชื่อมต่อ

## การใช้งาน

```dart
// เปิดหน้า Video Call
Navigator.pushNamed(context, '/videoCall');
```

## Configuration

แก้ไขค่าใน `video_config.dart`:

```dart
static const String openViduUrl = 'https://conference.pcm-life.com';
static const String sessionName = 'Telemed_Test';
```

## Dependencies ที่ต้องการ

```yaml
dependencies:
  webview_flutter: ^4.4.2
  http: ^1.5.0
  permission_handler: ^11.3.1
  app_settings: ^5.1.1
```

## Permissions ที่จำเป็น

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>แอปต้องการใช้กล้องสำหรับการ Video Call กับแพทย์</string>
<key>NSMicrophoneUsageDescription</key>
<string>แอปต้องการใช้ไมโครโฟนสำหรับการสื่อสารกับแพทย์</string>
```

## การทำงาน

1. ตรวจสอบและขอ permissions (กล้อง, ไมโครโฟน)
2. ผู้ใช้เปิดหน้า Video Call
3. ระบบเชื่อมต่อกับ OpenVidu server
4. สร้าง session และ token
5. โหลด OpenVidu web interface ใน WebView
6. ผู้ใช้สามารถควบคุมเสียง/วิดีโอได้
7. วางสายและกลับไปหน้าเดิม

### 10. `auto_login_handler.dart`

จัดการ auto-login สำหรับ OpenVidu:

- สร้าง authenticated URLs
- Multi-method auto-login script
- Basic auth headers และ cookies
- ตรวจสอบ login success indicators

## Auto-Login Configuration

ระบบจะล็อกอินอัตโนมัติด้วย:

- **Username**: `user`
- **Password**: `minadadmin`

### วิธีการ Auto-Login:

1. **URL Parameters** - ส่ง credentials ผ่าน query parameters
2. **Basic Auth Headers** - ส่ง Authorization header
3. **Form Auto-Fill** - กรอกฟอร์มล็อกอินอัตโนมัติ
4. **Storage Auth** - เซ็ต localStorage/sessionStorage
5. **API Authentication** - เรียก login API

### การตรวจสอบ Login Success:

- ตรวจสอบ video container elements
- ตรวจสอบ URL changes (dashboard, room)
- Monitor JavaScript events

## การทดสอบ Permissions

```dart
// เปิดหน้าทดสอบ permissions
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PermissionTestScreen(),
  ),
);
```

## การพัฒนาต่อ

- เพิ่ม authentication กับ OpenVidu server
- เชื่อมต่อกับระบบนัดหมายแพทย์
- บันทึกประวัติการโทร
- เพิ่มฟีเจอร์ chat
- การแชร์หน้าจอ
