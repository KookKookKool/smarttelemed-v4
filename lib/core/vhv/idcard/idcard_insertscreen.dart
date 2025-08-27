import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/style/background_2.dart';
import 'package:smarttelemed_v4/style/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smarttelemed_v4/core/auth/idcard_reader.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smarttelemed_v4/storage/storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class IdCardInsertScreen extends StatefulWidget {
  const IdCardInsertScreen({Key? key}) : super(key: key);

  @override
  State<IdCardInsertScreen> createState() => _IdCardInsertScreenState();
}

class _IdCardInsertScreenState extends State<IdCardInsertScreen> {
  ESMIDCard? reader;
  Stream<String>? entry;
  StreamSubscription<String>? _entrySubscription;
  Timer? readingtime;
  Timer? reading;
  bool _isHandling = false;
  bool _isReading = false;
  bool _loading = false;
  bool shownumpad = false;
  Timer? _timer;
  Timer? timerreadIDCard;
  Timer? _actionTimeoutTimer;

  @override
  void initState() {
    super.initState();
    // Remove automatic reader initialization
    // User will need to press "อ่าน" button to start
    debugPrint('🏁 IdCardInsertScreen initialized - waiting for user action');
  }

  Future<void> readerID() async {
    // Ensure runtime permissions first
    final ok = await _ensurePermissions();
    if (!ok) return;

    // Reset flags at start
    _isHandling = false;
    _isReading = false;
    _loading = false;
    debugPrint('🚀 Starting readerID with clean flags');

    try {
      Future.delayed(const Duration(seconds: 1), () {
        debugPrint('🏁 readerID delayed execution starting');
        reader = ESMIDCard.instance;

        entry = reader?.getEntry();
        debugPrint('📡 Got entry stream: ${entry != null}');

        debugPrint('->initstate');
        if (entry != null) {
          debugPrint('->prepare stream subscription');

          // Cancel previous subscription if exists
          _entrySubscription?.cancel();

          _entrySubscription = entry?.listen(
            (String data) async {
              debugPrint('📩 Stream received data: $data');
              debugPrint(
                '📊 Current flags: _isReading=$_isReading, _isHandling=$_isHandling, _loading=$_loading',
              );
              debugPrint('🏠 Widget mounted: $mounted');

              if (!mounted) {
                debugPrint('⚠️ Widget not mounted, ignoring data');
                return;
              }

              // native layer replied with data -> allow further native calls
              _isReading = false;
              // IMPORTANT: Cancel timeout timer immediately when data arrives
              _actionTimeoutTimer?.cancel();
              _actionTimeoutTimer = null;
              debugPrint('⏰ Timer cancelled - data received successfully');

              if (mounted)
                setState(() {
                  _loading = false;
                });

              if (_isHandling) {
                debugPrint('⚠️ Ignoring data because _isHandling=true');
                return; // ignore subsequent events while handling
              }
              _isHandling = true;
              debugPrint('✅ Processing data, set _isHandling=true');
              List<String> splitted = data.split('#');
              debugPrint("IDCard $data");

              // Fluttertoast.showToast(
              //   msg: "" + data,
              //   toastLength: Toast.LENGTH_SHORT, // or Toast.LENGTH_LONG
              //   gravity: ToastGravity.BOTTOM, // TOP, CENTER, BOTTOM
              //   backgroundColor: Colors.black54,
              //   textColor: Colors.white,
              //   fontSize: 16.0,
              // );

              //
              final idCard = splitted.isNotEmpty ? splitted[0] : '';
              final prefix = splitted.length > 1 ? splitted[1] : '';
              final firstName = splitted.length > 2 ? splitted[2] : '';
              final lastName = splitted.length > 4 ? splitted[4] : '';

              // Build full name: prefix + first + last
              final fullName = [
                prefix,
                firstName,
                lastName,
              ].where((s) => s.isNotEmpty).join(' ').trim();

              // Address parts start around index 9-10, extract relevant parts
              final addressParts = <String>[];
              if (splitted.length > 9 && splitted[9].isNotEmpty)
                addressParts.add(splitted[9]); // 73/6
              if (splitted.length > 10 && splitted[10].isNotEmpty)
                addressParts.add(splitted[10]); // หมู่ที่ 4
              if (splitted.length > 14 && splitted[14].isNotEmpty)
                addressParts.add(splitted[14]); // ตำบล
              if (splitted.length > 15 && splitted[15].isNotEmpty)
                addressParts.add(splitted[15]); // อำเภอ
              if (splitted.length > 16 && splitted[16].isNotEmpty)
                addressParts.add(splitted[16]); // จังหวัด

              final address = addressParts.join(' ').trim();

              debugPrint('🎯 Parsed data:');
              debugPrint('   fullName: $fullName');
              debugPrint('   idCard: $idCard');
              debugPrint('   address: $address');

              // 🔥 บันทึกข้อมูลทันทีเมื่ออ่านได้ (ไม่รอ Dialog)
              try {
                final dataToSave = {
                  'fullName': fullName,
                  'idCard': idCard,
                  'address': address,
                  'timestamp': DateTime.now().toIso8601String(),
                  'source': 'card_reader', // ระบุแหล่งที่มา
                };
                await IdCardStorage.saveIdCardData(dataToSave);
                debugPrint('💾 Auto-saved ID card data to storage');

                // แสดง Toast แจ้งว่าบันทึกแล้ว
                Fluttertoast.showToast(
                  msg: '✅ บันทึกข้อมูลบัตรแล้ว',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
              } catch (e) {
                debugPrint('❌ Error auto-saving ID card: $e');
              }

              // Show confirm dialog to user
              if (mounted) {
                debugPrint('🎬 Showing dialog...');
                await _showIdCardDialog(fullName, idCard, address);
                debugPrint('✅ Dialog completed');
              } else {
                _isHandling = false;
                if (mounted)
                  setState(() {
                    _loading = false;
                  });
              }

              // context.read<DataProvider>().id = splitted[0].toString();
              // context.read<DataProvider>().regter_data = splitted;
              // setState(() {
              //   context.read<DataProvider>().regter_data = splitted;
              //   context.read<DataProvider>().id = splitted[0].toString();
              // });
              // debugPrint(
              //     "${context.read<DataProvider>().id} / ${splitted[0].toString()}");

              // idcard.setValue(splitted[0]);
              // if (context.read<DataProvider>().id == splitted[0].toString()) {
              //   check2();
              // } else {}
            },
            onError: (error) {
              debugPrint('❌ Stream error: $error');
              // Cancel timeout timer on error
              _actionTimeoutTimer?.cancel();
              _actionTimeoutTimer = null;
              debugPrint('⏰ Timer cancelled due to stream error');

              // allow future attempts
              _isReading = false;
              _isHandling = false;
              if (mounted)
                setState(() {
                  _loading = false;
                });
            },
            onDone: () {
              debugPrint('🔚 Stream closed!');
              _actionTimeoutTimer?.cancel();
              _actionTimeoutTimer = null;
              debugPrint('⏰ Timer cancelled - stream closed');

              _isReading = false;
              _isHandling = false;
              if (mounted)
                setState(() {
                  _loading = false;
                });
            },
          );
        } else {
          // no entry stream available yet
          debugPrint('❌ No entry stream available');
          Fluttertoast.showToast(
            msg: 'ไม่พบการเชื่อมต่อเครื่องอ่าน โปรดกด "อ่าน" เพื่อเลือกอุปกรณ์',
          );
        }
        // Don't start automatic card checking - wait for user action
        debugPrint(
          '✅ readerID setup complete - waiting for user to press Read button',
        );
      });
    } on Exception catch (e) {
      debugPrint('error');
      debugPrint(e.toString());
    }
  }

  Future<bool> _ensurePermissions() async {
    try {
      if (Platform.isAndroid) {
        // Request BLE permissions (Android 12+) and location as fallback
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
          Permission.location,
        ].request();

        final ok = statuses.values.every((s) => s.isGranted);
        if (!ok) {
          Fluttertoast.showToast(
            msg: 'โปรดอนุญาตสิทธิ์ Bluetooth/Location ในแอป',
          );
          // open settings so user can allow
          openAppSettings();
        }
        return ok;
      } else {
        // iOS: request bluetooth permission
        final status = await Permission.bluetooth.request();
        if (!status.isGranted) {
          Fluttertoast.showToast(msg: 'โปรดอนุญาตสิทธิ์ Bluetooth ในแอป');
          openAppSettings();
          return false;
        }
        return true;
      }
    } catch (e) {
      debugPrint('Permission check error: $e');
      return false;
    }
  }

  void getIdCard() async {
    // timerreadIDCard = Timer.periodic(const Duration(seconds: 4), (timer) async {
    //   var url = Uri.parse('http://localhost:8189/api/smartcard/read');
    //   var res = await http.get(url);
    //   var resTojson = json.decode(res.body);
    //   debugPrint("Crde Reader--------------------------------=");
    //   debugPrint(resTojson.toString());
    //   if (res.statusCode == 200) {
    //     context.read<DataProvider>().updateuserinformation(resTojson);
    //     context.read<DataProvider>().upcorrelationId(resTojson);
    //     debugPrint(resTojson["claimTypes"][0].toString());
    //     context
    //         .read<DataProvider>()
    //         .updateclaimType(resTojson["claimTypes"][0]);
    //     check2();
    //     timerreadIDCard?.cancel();
    //   }
    // });
  }

  void checkCard() {
    // Disabled automatic card checking
    // Card reading now only happens when user presses the "อ่าน" button
    debugPrint('� checkCard disabled - use manual reading only');
    return;
  }

  // Helper: when a reader is connected, check card status then trigger readAuto with timeout
  Future<void> _handleConnectedRead() async {
    // stop periodic polling to avoid overlapping reads
    reading?.cancel();

    int? status;
    try {
      status = await reader?.getCardStatusDF();
    } catch (e) {
      debugPrint('getCardStatusDF error: $e');
    }

    if (status == null) {
      Fluttertoast.showToast(msg: 'ไม่สามารถตรวจสอบสถานะบัตรได้');
      if (mounted)
        setState(() {
          _isReading = false;
          _loading = false;
          _isHandling = false; // Reset this flag too
        });
      // Don't restart polling - wait for user action
      return;
    }

    if (status != 1) {
      final err = reader?.checkException(status);
      Fluttertoast.showToast(msg: 'สถานะบัตร: ${err ?? status.toString()}');
      if (mounted)
        setState(() {
          _isReading = false;
          _loading = false;
          _isHandling = false; // Reset this flag too
        });
      // Don't restart polling - wait for user action
      return;
    }

    // trigger a single read attempt - keep loader showing
    try {
      // Fluttertoast.showToast(msg: 'เริ่มอ่านบัตร กรุณารอสักครู่');
      reader?.readAuto();
      // Note: loader will remain showing until stream receives data or timeout
    } catch (e) {
      debugPrint('readAuto error: $e');
      // Reset flags on readAuto error
      if (mounted)
        setState(() {
          _isReading = false;
          _loading = false;
          _isHandling = false;
        });
      Fluttertoast.showToast(msg: 'เกิดข้อผิดพลาดในการอ่านบัตร');
      // Don't restart polling - wait for user action
      return;
    }

    // safety timeout: clear flags if no stream response
    // Timer สำหรับ timeout การอ่านบัตร
    debugPrint('⏰ Setting 15-second timeout timer for card reading');
    _actionTimeoutTimer = Timer(const Duration(seconds: 15), () {
      debugPrint('⏰ TIMEOUT: 15 seconds elapsed without card data');
      if (mounted)
        setState(() {
          _isReading = false;
          _loading = false; // Hide loader on timeout
          _isHandling = false;
        });
      Fluttertoast.showToast(
        msg: 'หมดเวลาการอ่านบัตร โปรดลองอีกครั้ง',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      // Don't restart polling - wait for user action
    });
  }

  // @override
  // void dispose() {
  //   readingtime?.cancel();
  //   reading?.cancel();
  //   _timer?.cancel();
  //   timerreadIDCard?.cancel();
  //   super.dispose();
  // }

  @override
  void dispose() {
    _entrySubscription?.cancel();
    readingtime?.cancel();
    reading?.cancel();
    _timer?.cancel();
    timerreadIDCard?.cancel();
    _actionTimeoutTimer?.cancel();

    // Reset flags on dispose
    _isReading = false;
    _isHandling = false;
    _loading = false;

    super.dispose();
  }

  Future<void> _showIdCardDialog(
    String fullName,
    String idCard,
    String address, {
    bool isFromStorage = false,
  }) async {
    debugPrint('🎭 _showIdCardDialog called with:');
    debugPrint('   fullName: "$fullName"');
    debugPrint('   idCard: "$idCard"');
    debugPrint('   address: "$address"');

    if (!mounted) {
      debugPrint('❌ Context not mounted, cannot show dialog');
      return;
    }

    try {
      debugPrint('🎪 About to call showDialog...');
      await showDialog<void>(
        context: context,
        barrierDismissible: false, // prevent dismiss by tapping outside
        builder: (context) => IdCardInfoDialog(
          fullName: fullName,
          idCard: idCard,
          address: address,
          isFromStorage: isFromStorage,
          onConfirm: () async {
            try {
              // Cancel any remaining timers
              _actionTimeoutTimer?.cancel();
              _actionTimeoutTimer = null;
              debugPrint('⏰ Timer cancelled on confirm');

              // ถ้าข้อมูลมาจาก storage แล้ว ไม่ต้องบันทึกใหม่
              if (!isFromStorage) {
                final dataToSave = {
                  'fullName': fullName,
                  'idCard': idCard,
                  'address': address,
                  'timestamp': DateTime.now().toIso8601String(),
                };
                await IdCardStorage.saveIdCardData(dataToSave);

                Fluttertoast.showToast(
                  msg: 'บันทึกข้อมูลเรียบร้อย',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
              }

              // Navigate to dashboard screen
              Navigator.of(context).pop(); // close dialog
              Navigator.pushReplacementNamed(
                context,
                '/dashboard',
              ); // go to dashboard
            } catch (e) {
              debugPrint('Error saving id card: $e');
              Fluttertoast.showToast(
                msg: 'เกิดข้อผิดพลาดในการบันทึก',
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
            }

            // Reset flags
            Future.delayed(const Duration(milliseconds: 500), () {
              debugPrint('🔄 Resetting flags after confirm');
              _isHandling = false;
              _isReading = false;
              debugPrint(
                '📊 Flags reset: _isReading=$_isReading, _isHandling=$_isHandling',
              );
            });
          },
          onCancel: () {
            // Cancel any remaining timers
            _actionTimeoutTimer?.cancel();
            _actionTimeoutTimer = null;
            debugPrint('⏰ Timer cancelled on cancel');

            Navigator.of(context).pop();
            // allow next read after short delay (onCancel)
            Future.delayed(const Duration(milliseconds: 500), () {
              debugPrint('🔄 Resetting flags after cancel');
              _isHandling = false;
              _isReading = false; // Reset this too
              debugPrint(
                '📊 Flags reset: _isReading=$_isReading, _isHandling=$_isHandling',
              );
              // Don't restart automatic polling - wait for user action
            });
          },
        ),
      );
      debugPrint('✅ Dialog completed successfully');
    } catch (e) {
      debugPrint('❌ Error showing dialog: $e');
    }
  }

  // ฟังก์ชันใช้ข้อมูลจำลอง
  Future<void> _useMockData() async {
    try {
      debugPrint('🎭 Using mock ID card data...');

      // Mock data สำหรับทดสอบ - มีหลายชุดให้เลือกแบบสุ่ม
      final List<Map<String, String>> mockDataList = [
        {
          'fullName': 'นาย ทดสอบ ระบบ',
          'idCard': '1234567890123',
          'address': '123/45 หมู่ที่ 6 ตำบลตัวอย่าง อำเภอทดสอบ จังหวัดตัวอย่าง',
        },
        {
          'fullName': 'นางสาว จำลอง ข้อมูล',
          'idCard': '9876543210987',
          'address': '789/12 หมู่ที่ 3 ตำบลจำลอง อำเภอข้อมูล จังหวัดทดสอบ',
        },
        {
          'fullName': 'นาง ตัวอย่าง ใช้งาน',
          'idCard': '5555666677778',
          'address': '456/78 หมู่ที่ 9 ตำบลใช้งาน อำเภอตัวอย่าง จังหวัดระบบ',
        },
      ];

      // เลือกข้อมูลแบบสุ่ม
      final randomIndex = DateTime.now().millisecond % mockDataList.length;
      final selectedMockData = mockDataList[randomIndex];

      final mockFullName = selectedMockData['fullName']!;
      final mockIdCard = selectedMockData['idCard']!;
      final mockAddress = selectedMockData['address']!;

      // บันทึกข้อมูล Mock
      final mockDataToSave = {
        'fullName': mockFullName,
        'idCard': mockIdCard,
        'address': mockAddress,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'mock_data', // ระบุว่าเป็นข้อมูลจำลอง
      };

      await IdCardStorage.saveIdCardData(mockDataToSave);
      debugPrint('💾 Saved mock ID card data to storage: $mockFullName');

      // แสดง Toast แจ้งเตือน
      Fluttertoast.showToast(
        msg: '🧪 ใช้ข้อมูลจำลองสำหรับทดสอบ: $mockFullName',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );

      // แสดง Dialog ข้อมูลจำลอง
      if (mounted) {
        await _showIdCardDialog(
          mockFullName,
          mockIdCard,
          mockAddress,
          isFromStorage: false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error using mock data: $e');
      Fluttertoast.showToast(
        msg: 'เกิดข้อผิดพลาดในการใช้ข้อมูลจำลอง',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // ฟังก์ชันแสดงข้อมูลบัตรที่บันทึกไว้แล้ว
  Future<void> _showStoredIdCardData() async {
    try {
      debugPrint('📂 Loading stored ID card data...');
      final storedData = await IdCardStorage.loadIdCardData();

      if (storedData == null) {
        Fluttertoast.showToast(
          msg: 'ไม่พบข้อมูลบัตรที่บันทึกไว้',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }

      final fullName = storedData['fullName'] ?? 'ไม่มีข้อมูล';
      final idCard = storedData['idCard'] ?? 'ไม่มีข้อมูล';
      final address = storedData['address'] ?? 'ไม่มีข้อมูล';

      debugPrint('📄 Showing stored data: $fullName, $idCard');

      // แสดง Dialog จากข้อมูลที่บันทึกไว้ (ข้อมูลจาก storage)
      await _showIdCardDialog(fullName, idCard, address, isFromStorage: true);
    } catch (e) {
      debugPrint('❌ Error loading stored ID card data: $e');
      Fluttertoast.showToast(
        msg: 'เกิดข้อผิดพลาดในการโหลดข้อมูล',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // ฟังก์ชันสำหรับปุ่มอ่านบัตร
  Future<void> _startCardReading() async {
    if (_loading || _isReading || _isHandling) {
      debugPrint('⚠️ Reading already in progress');
      return;
    }

    debugPrint('🎯 Starting card reading process...');

    // Show loader immediately when button is pressed
    setState(() {
      _loading = true;
      _isReading = true;
    });

    // Check permissions first
    final ok = await _ensurePermissions();
    if (!ok) {
      setState(() {
        _loading = false;
        _isReading = false;
      });
      return;
    }

    try {
      // Step 1: Initialize reader completely if needed
      if (reader == null) {
        debugPrint('🔧 Initializing reader...');
        await readerID(); // Call full initialization

        // Wait a bit for initialization to complete
        await Future.delayed(const Duration(seconds: 2));

        if (reader == null) {
          throw Exception('การเริ่มต้นเครื่องอ่านไม่สำเร็จ');
        }
      }

      // Setup stream if needed
      if (entry == null) {
        entry = reader?.getEntry();
        debugPrint('� Got entry stream: ${entry != null}');

        if (entry != null) {
          // Cancel previous subscription if exists
          _entrySubscription?.cancel();

          _entrySubscription = entry?.listen(
            (String data) async {
              debugPrint('📩 Stream received data: $data');
              if (!mounted) return;

              // Reset flags when data arrives
              _isReading = false;
              _actionTimeoutTimer?.cancel();
              if (mounted) setState(() => _loading = false);

              if (_isHandling) {
                debugPrint('⚠️ Ignoring data because _isHandling=true');
                return;
              }
              _isHandling = true;

              // Parse data (same logic as before)
              List<String> splitted = data.split('#');
              debugPrint("IDCard $data");

              final idCard = splitted.isNotEmpty ? splitted[0] : '';
              final prefix = splitted.length > 1 ? splitted[1] : '';
              final firstName = splitted.length > 2 ? splitted[2] : '';
              final lastName = splitted.length > 4 ? splitted[4] : '';

              final fullName = [
                prefix,
                firstName,
                lastName,
              ].where((s) => s.isNotEmpty).join(' ').trim();

              final addressParts = <String>[];
              if (splitted.length > 9 && splitted[9].isNotEmpty)
                addressParts.add(splitted[9]);
              if (splitted.length > 10 && splitted[10].isNotEmpty)
                addressParts.add(splitted[10]);
              if (splitted.length > 14 && splitted[14].isNotEmpty)
                addressParts.add(splitted[14]);
              if (splitted.length > 15 && splitted[15].isNotEmpty)
                addressParts.add(splitted[15]);
              if (splitted.length > 16 && splitted[16].isNotEmpty)
                addressParts.add(splitted[16]);

              final address = addressParts.join(' ').trim();

              // Step 4: Auto-save data to storage
              try {
                final dataToSave = {
                  'fullName': fullName,
                  'idCard': idCard,
                  'address': address,
                  'timestamp': DateTime.now().toIso8601String(),
                  'source': 'card_reader',
                };
                await IdCardStorage.saveIdCardData(dataToSave);
                debugPrint('💾 Auto-saved ID card data to storage');

                Fluttertoast.showToast(
                  msg: '✅ บันทึกข้อมูลบัตรแล้ว',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
              } catch (e) {
                debugPrint('❌ Error auto-saving ID card: $e');
              }

              // Step 5: Show dialog with data (อ่านจาก storage เพื่อให้แน่ใจว่าข้อมูลตรงกัน)
              if (mounted) {
                await _showStoredIdCardData(); // ใช้ข้อมูลจาก storage
              } else {
                _isHandling = false;
              }
            },
            onError: (error) {
              debugPrint('❌ Stream error: $error');
              _actionTimeoutTimer?.cancel();
              _isReading = false;
              _isHandling = false;
              if (mounted) setState(() => _loading = false);
            },
            onDone: () {
              debugPrint('🔚 Stream closed!');
              _actionTimeoutTimer?.cancel();
              _isReading = false;
              _isHandling = false;
              if (mounted) setState(() => _loading = false);
            },
          );
        }
      }

      // Find and connect to reader
      debugPrint('🔍 Finding reader...');
      // Fluttertoast.showToast(msg: 'กำลังค้นหาเครื่องอ่านบัตร...');

      // Add extra delay to ensure native is fully ready
      debugPrint('⏳ Waiting for native initialization...');
      await Future.delayed(const Duration(seconds: 1));

      try {
        await reader?.findReader();
      } catch (e) {
        debugPrint('❌ Error in findReader: $e');
        throw Exception('ไม่สามารถค้นหาเครื่องอ่านได้: $e');
      }

      if (reader?.isReaderConnected != true) {
        throw Exception('ไม่พบเครื่องอ่านบัตรหรือเชื่อมต่อไม่ได้');
      }

      // Show success message
      Fluttertoast.showToast(
        msg: '✅ เชื่อมต่อเครื่องอ่านบัตรสำเร็จ',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Start reading process with loading
      debugPrint('📖 Starting card read...');
      // Fluttertoast.showToast(msg: 'กำลังอ่านบัตร กรุณาใส่บัตรประชาชน');

      await _handleConnectedRead();
    } catch (e) {
      debugPrint('❌ Error in card reading: $e');

      // Hide loader and reset flags on error
      if (mounted) {
        setState(() {
          _loading = false;
          _isReading = false;
          _isHandling = false;
        });
      }

      // Show error message
      Fluttertoast.showToast(
        msg: 'เกิดข้อผิดพลาด: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleBackground2(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // ...existing code...
              // ปุ่ม Back ซ้ายบน
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: ShaderMask(
                    shaderCallback: (rect) =>
                        AppColors.mainGradient.createShader(rect),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // เนื้อหา
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // โลโก้กลาง
                      SvgPicture.asset(
                        'assets/logo.svg',
                        width: (160),
                        height: (160),
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      // ข้อความ
                      const Text(
                        'กรุณาเสียบบัตรประชาชน\nเพื่อเข้าสู่ระบบ อสม.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ลูกศรชี้ขึ้น
                      ShaderMask(
                        shaderCallback: (rect) =>
                            AppColors.mainGradient.createShader(rect),
                        child: const Icon(
                          Icons.arrow_upward,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ช่องอ่านบัตร
                      Container(
                        width: 200,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0),
                      // บัตรประชาชน (หมุน 90 องศา)
                      Transform.rotate(
                        angle: 0,
                        child: Image.asset('assets/card.png', height: 250),
                      ),
                      const SizedBox(height: 40),

                      // ปุ่มสำเร็จ
                      // SizedBox(
                      //   width: 114,
                      //   height: 41,
                      //   child: DecoratedBox(
                      //     decoration: BoxDecoration(
                      //       gradient: AppColors.mainGradient,
                      //       borderRadius: BorderRadius.circular(30),
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: AppColors.gradientStart.withOpacity(0.2),
                      //           blurRadius: 8,
                      //           offset: Offset(0, 4),
                      //         ),
                      //       ],
                      //     ),
                      //     child: ElevatedButton(
                      //       style: ElevatedButton.styleFrom(
                      //         backgroundColor: Colors.transparent,
                      //         shadowColor: Colors.transparent,
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(30),
                      //         ),
                      //         elevation: 0,
                      //       ),
                      //       onPressed: () {
                      //         Navigator.pushNamed(context, '/idcardloader');
                      //       },
                      //       child: const Text(
                      //         'สำเร็จ',
                      //         style: TextStyle(
                      //           fontSize: 16,
                      //           color: Colors.white,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(height: 40),
                      // ปุ่มสำเร็จ
                      SizedBox(
                        width: 114,
                        height: 41,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.mainGradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gradientStart.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              // เรียกใช้ฟังก์ชันอ่านบัตรใหม่
                              await _startCardReading();
                            },

                            child: const Text(
                              'อ่าน',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ปุ่มใช้ข้อมูลจำลอง
                      // SizedBox(
                      //   width: 180,
                      //   height: 45,
                      //   child: DecoratedBox(
                      //     decoration: BoxDecoration(
                      //       gradient: LinearGradient(
                      //         colors: [
                      //           Colors.orange.shade400,
                      //           Colors.orange.shade600,
                      //         ],
                      //       ),
                      //       borderRadius: BorderRadius.circular(25),
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: Colors.orange.withOpacity(0.3),
                      //           blurRadius: 8,
                      //           offset: Offset(0, 4),
                      //         ),
                      //       ],
                      //     ),
                      //     child: ElevatedButton.icon(
                      //       style: ElevatedButton.styleFrom(
                      //         backgroundColor: Colors.transparent,
                      //         shadowColor: Colors.transparent,
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(25),
                      //         ),
                      //         elevation: 0,
                      //       ),
                      //       onPressed: () async {
                      //         await _useMockData();
                      //       },
                      //       icon: Icon(
                      //         Icons.science,
                      //         color: Colors.white,
                      //         size: 18,
                      //       ),
                      //       label: const Text(
                      //         'ใช้ข้อมูลจำลอง',
                      //         style: TextStyle(
                      //           fontSize: 14,
                      //           color: Colors.white,
                      //           fontWeight: FontWeight.w600,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(height: 16),

                      // const SizedBox(height: 24),
                      // SizedBox(
                      //   width: 180,
                      //   height: 41,
                      //   child: DecoratedBox(
                      //     decoration: BoxDecoration(
                      //       gradient: LinearGradient(
                      //         colors: [
                      //           Colors.blue.shade400,
                      //           Colors.blue.shade600,
                      //         ],
                      //       ),
                      //       borderRadius: BorderRadius.circular(30),
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: Colors.blue.withOpacity(0.2),
                      //           blurRadius: 8,
                      //           offset: Offset(0, 4),
                      //         ),
                      //       ],
                      //     ),
                      //     child: ElevatedButton(
                      //       style: ElevatedButton.styleFrom(
                      //         backgroundColor: Colors.transparent,
                      //         shadowColor: Colors.transparent,
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(30),
                      //         ),
                      //         elevation: 0,
                      //       ),
                      //       onPressed: () async {
                      //         await _showStoredIdCardData();
                      //       },
                      //       child: const Text(
                      //         'แสดงข้อมูลล่าสุด',
                      //         style: TextStyle(
                      //           fontSize: 14,
                      //           color: Colors.white,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(height: 24),
                      // text for no ID card - เปลี่ยนเป็น TextButton ที่คลิกได้
                      TextButton(
                        onPressed: () async {
                          await _useMockData();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade600,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ไม่มีบัตรประชาชน',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(คลิกเพื่อใช้ข้อมูลจำลอง)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Beautiful animated loader overlay covering entire screen
              if (_loading)
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.9),
                        ],
                      ),
                    ),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 500),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Animated circular progress indicator with gradient
                                    Container(
                                      width: 60,
                                      height: 60,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.gradientStart,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Loading text with icon
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.credit_card,
                                          color: AppColors.gradientStart,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isReading
                                              ? 'กำลังอ่านบัตรประชาชน'
                                              : 'กำลังเตรียมเครื่องอ่านบัตร',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isReading
                                          ? 'โปรดใส่บัตรในเครื่องอ่าน...'
                                          : 'โปรดรอสักครู่...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
}

class IdCardInfoDialog extends StatelessWidget {
  final String fullName;
  final String idCard;
  final String address;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isFromStorage;

  const IdCardInfoDialog({
    Key? key,
    required this.fullName,
    required this.idCard,
    required this.address,
    required this.onConfirm,
    required this.onCancel,
    this.isFromStorage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ IdCardInfoDialog.build() called with:');
    debugPrint('   fullName: "$fullName"');
    debugPrint('   idCard: "$idCard"');
    debugPrint('   address: "$address"');

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.credit_card, color: AppColors.gradientStart, size: 24),
          const SizedBox(width: 8),
          const Text(
            'ข้อมูลบัตรประชาชน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('ชื่อ-นามสกุล', fullName, Icons.person),
            const SizedBox(height: 12),
            _buildInfoRow('รหัสบัตรประชาชน', idCard, Icons.badge),
            const SizedBox(height: 12),
            _buildInfoRow('ที่อยู่', address, Icons.home),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gradientStart,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('ยืนยัน'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.gradientStart),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'ไม่มีข้อมูล',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value.isNotEmpty ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
