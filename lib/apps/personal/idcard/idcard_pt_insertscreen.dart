import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/shared/style/background.dart';
import 'package:smarttelemed_v4/shared/style/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smarttelemed_v4/shared/screens/auth/idcard_reader.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smarttelemed_v4/storage/storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class IdCardPtInsertScreen extends StatefulWidget {
  const IdCardPtInsertScreen({Key? key}) : super(key: key);

  @override
  State<IdCardPtInsertScreen> createState() => _IdCardPtInsertScreenState();
}

class _IdCardPtInsertScreenState extends State<IdCardPtInsertScreen> {
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
    // Just initialize - don't set up stream yet
    debugPrint('🏁 IdCardPtInsertScreen initialized - ready for user action');
  }

  Future<void> _initializeReaderIfNeeded() async {
    try {
      if (reader == null) {
        debugPrint('🚀 Setting up reader for patient card reading');
        reader = ESMIDCard.instance;
        entry = reader?.getEntry();
        debugPrint('📡 Got entry stream: ${entry != null}');
      }
    } catch (e) {
      debugPrint('❌ Error setting up reader: $e');
      rethrow;
    }
  }

  void _setupStreamListener() {
    try {
      // Cancel any existing subscription first
      _entrySubscription?.cancel();
      _entrySubscription = null;

      debugPrint('🔧 Setting up new stream listener...');

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

          // Cancel timeout timer immediately when data arrives
          _actionTimeoutTimer?.cancel();
          _actionTimeoutTimer = null;
          debugPrint('⏰ Timer cancelled - data received successfully');

          // Update UI to hide loading
          if (mounted) {
            setState(() {
              _loading = false;
              _isReading = false;
            });
          }

          if (_isHandling) {
            debugPrint('⚠️ Ignoring data because _isHandling=true');
            return;
          }
          _isHandling = true;
          debugPrint('✅ Processing data, set _isHandling=true');

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

          debugPrint('� Parsed patient data:');
          debugPrint('   fullName: $fullName');
          debugPrint('   idCard: $idCard');
          debugPrint('   address: $address');

          // Auto-save patient data
          try {
            final dataToSave = {
              'fullName': fullName,
              'idCard': idCard,
              'address': address,
              'timestamp': DateTime.now().toIso8601String(),
              'source': 'patient_card_reader',
              'type': 'patient_id_card',
            };
            await PatientIdCardStorage.savePatientIdCardData(dataToSave);
            debugPrint('💾 Auto-saved Patient ID card data to storage');

            Fluttertoast.showToast(
              msg: '✅ บันทึกข้อมูลบัตรผู้ป่วยแล้ว',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.purple,
              textColor: Colors.white,
            );
          } catch (e) {
            debugPrint('❌ Error auto-saving Patient ID card: $e');
          }

          // Show dialog
          if (mounted) {
            debugPrint('🎬 Showing patient dialog...');
            await _showIdCardDialog(fullName, idCard, address);
            debugPrint('✅ Patient Dialog completed');
          } else {
            _isHandling = false;
          }
        },
        onError: (error) {
          debugPrint('❌ Stream error: $error');
          _actionTimeoutTimer?.cancel();
          _actionTimeoutTimer = null;

          _isReading = false;
          _isHandling = false;
          if (mounted) setState(() => _loading = false);
        },
        onDone: () {
          debugPrint('🔚 Stream closed!');
          _actionTimeoutTimer?.cancel();
          _actionTimeoutTimer = null;

          _isReading = false;
          _isHandling = false;
          if (mounted) setState(() => _loading = false);
        },
      );

      debugPrint('✅ Stream listener setup completed');
    } catch (e) {
      debugPrint('❌ Error setting up stream listener: $e');
      throw e;
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

  void checkCard() {
    // Disabled automatic card checking
    // Card reading now only happens when user presses the "อ่าน" button
    debugPrint('🚫 checkCard disabled - use manual reading only');
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
    debugPrint('⏰ Setting 15-second timeout timer for patient card reading');
    _actionTimeoutTimer = Timer(const Duration(seconds: 15), () {
      debugPrint('⏰ TIMEOUT: 15 seconds elapsed without patient card data');
      if (mounted)
        setState(() {
          _isReading = false;
          _loading = false; // Hide loader on timeout
          _isHandling = false;
        });
      Fluttertoast.showToast(
        msg: 'หมดเวลาการอ่านบัตรผู้ป่วย โปรดลองอีกครั้ง',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      // Don't restart polling - wait for user action
    });
  }

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
        builder: (context) => PatientIdCardInfoDialog(
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
                  'source': 'patient_card_reader',
                  'type': 'patient_id_card',
                };
                await PatientIdCardStorage.savePatientIdCardData(dataToSave);

                Fluttertoast.showToast(
                  msg: 'บันทึกข้อมูลผู้ป่วยเรียบร้อย',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
              }

              // Navigate to idcardptloader screen
              Navigator.of(context).pop(); // close dialog
              Navigator.pushReplacementNamed(context, '/profilept');
            } catch (e) {
              debugPrint('Error saving patient id card: $e');
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

  // ฟังก์ชันใช้ข้อมูลจำลองผู้ป่วย
  Future<void> _useMockPatientData() async {
    try {
      debugPrint('🎭 Using mock patient ID card data...');

      // Mock data สำหรับทดสอบผู้ป่วย - แยกจาก VHV
      final List<Map<String, String>> mockDataList = [
        {
          'fullName': 'นาย คนไข้ ทดสอบ',
          'idCard': '1111111111117',
          'address': '234/56 หมู่ที่ 7 ตำบลคนไข้ อำเภอทดสอบ จังหวัดผู้ป่วย',
        },
      ];

      // เลือกข้อมูลแบบสุ่ม
      final randomIndex = DateTime.now().millisecond % mockDataList.length;
      final selectedMockData = mockDataList[randomIndex];

      final mockFullName = selectedMockData['fullName']!;
      final mockIdCard = selectedMockData['idCard']!;
      final mockAddress = selectedMockData['address']!;

      // บันทึกข้อมูล Mock ผู้ป่วย
      final mockDataToSave = {
        'fullName': mockFullName,
        'idCard': mockIdCard,
        'address': mockAddress,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'patient_mock_data', // ระบุว่าเป็นข้อมูลจำลองผู้ป่วย
        'type': 'patient_id_card',
      };

      await PatientIdCardStorage.savePatientIdCardData(mockDataToSave);
      debugPrint(
        '💾 Saved mock patient ID card data to storage: $mockFullName',
      );

      // แสดง Toast แจ้งเตือน
      Fluttertoast.showToast(
        msg: '🧪 ใช้ข้อมูลจำลองผู้ป่วย: $mockFullName',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.purple,
        textColor: Colors.white,
      );

      // แสดง Dialog ข้อมูลจำลองผู้ป่วย
      if (mounted) {
        await _showIdCardDialog(
          mockFullName,
          mockIdCard,
          mockAddress,
          isFromStorage: false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error using mock patient data: $e');
      Fluttertoast.showToast(
        msg: 'เกิดข้อผิดพลาดในการใช้ข้อมูลจำลองผู้ป่วย',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // ฟังก์ชันสำหรับปุ่มอ่านบัตรผู้ป่วย
  Future<void> _startPatientCardReading() async {
    if (_loading || _isReading || _isHandling) {
      debugPrint('⚠️ Patient card reading already in progress');
      return;
    }

    debugPrint('🎯 Starting patient card reading process...');

    // Show loader immediately
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
      // Initialize reader if needed
      await _initializeReaderIfNeeded();

      if (reader == null || entry == null) {
        throw Exception('การเริ่มต้นเครื่องอ่านไม่สำเร็จ');
      }

      // Setup stream listener only when user presses button
      if (_entrySubscription == null) {
        debugPrint('🔧 Setting up stream listener for card reading...');
        _setupStreamListener();
      }

      // Find and connect to reader
      debugPrint('🔍 Finding reader for patient...');
      await reader?.findReader();

      if (reader?.isReaderConnected != true) {
        throw Exception('ไม่พบเครื่องอ่านบัตรหรือเชื่อมต่อไม่ได้');
      }

      Fluttertoast.showToast(
        msg: '✅ เชื่อมต่อเครื่องอ่านบัตรสำหรับผู้ป่วยสำเร็จ',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.purple,
        textColor: Colors.white,
      );

      // Start reading process
      debugPrint('📖 Starting patient card read...');
      await _handleConnectedRead();
    } catch (e) {
      debugPrint('❌ Error in patient card reading: $e');

      // Hide loader and reset flags on error
      if (mounted) {
        setState(() {
          _loading = false;
          _isReading = false;
          _isHandling = false;
        });
      }

      Fluttertoast.showToast(
        msg: 'เกิดข้อผิดพลาดในการอ่านบัตรผู้ป่วย: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
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
                        'กรุณาเสียบบัตรประชาชน\nผู้เข้ารับการรักษา',
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
                      // บัตรประชาชน
                      Transform.rotate(
                        angle: 0,
                        child: Image.asset('assets/card.png', height: 250),
                      ),
                      const SizedBox(height: 28),
                      // ปุ่มอ่านบัตรผู้ป่วย
                      SizedBox(
                        width: 114,
                        height: 41,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade400,
                                Colors.purple.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
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
                              // เรียกใช้ฟังก์ชันอ่านบัตรผู้ป่วย
                              await _startPatientCardReading();
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
                      const SizedBox(height: 8),
                      // text for no ID card - เปลี่ยนเป็น TextButton ที่คลิกได้
                      TextButton(
                        onPressed: () async {
                          await _useMockPatientData();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple.shade600,
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
                              '(คลิกเพื่อใช้ข้อมูลจำลองผู้ป่วย)',
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
                                              Colors.purple.shade600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Loading text with icon
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_hospital,
                                          color: Colors.purple.shade600,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isReading
                                              ? 'กำลังอ่านบัตรประชาชนผู้ป่วย'
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
                                          ? 'โปรดใส่บัตรผู้ป่วยในเครื่องอ่าน...'
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

class PatientIdCardInfoDialog extends StatelessWidget {
  final String fullName;
  final String idCard;
  final String address;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isFromStorage;

  const PatientIdCardInfoDialog({
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
    debugPrint('🏗️ PatientIdCardInfoDialog.build() called with:');
    debugPrint('   fullName: "$fullName"');
    debugPrint('   idCard: "$idCard"');
    debugPrint('   address: "$address"');

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.local_hospital, color: Colors.purple.shade600, size: 24),
          const SizedBox(width: 8),
          const Text(
            'ข้อมูลบัตรประชาชนผู้ป่วย',
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
            backgroundColor: Colors.purple.shade600,
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
        Icon(icon, size: 20, color: Colors.purple.shade600),
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
