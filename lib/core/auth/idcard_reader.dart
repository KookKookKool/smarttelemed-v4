// import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:io' as IO;

class ESMIDCard {
  static const platform = const MethodChannel('flutter.native/helper');

  //  static const platform = MethodChannel('esm.flutter.dev/idcard');

  static const channelName =
      'channel'; // this channel name needs to match the one in Native method channel

  MethodChannel? methodChannel;

  static final ESMIDCard instance = ESMIDCard();
  //  ESMIDCard._init();

  // void configureChannel() {
  //   methodChannel = MethodChannel(channelName);
  //   methodChannel?.setMethodCallHandler(this.methodHandler); // set method handler

  // }

  static const int NA_POPUP = 0x80;
  // ignore: unused_field
  static const int NA_FIRST = 0x40;
  static const int NA_SCAN = 0x10;
  static const int NA_BLE1 = 0x08;
  static const int NA_BLE0 = 0x04;
  static const int NA_BT = 0x02;
  static const int NA_USB = 0x01;

  static const int NA_SUCCESS = 0;
  static const int NA_INTERNAL_ERROR = -1;
  static const int NA_INVALID_LICENSE = -2;
  static const int NA_READER_NOT_FOUND = -3;
  static const int NA_CONNECTION_ERROR = -4;
  static const int NA_GET_PHOTO_ERROR = -5;
  static const int NA_GET_TEXT_ERROR = -6;
  static const int NA_INVALID_CARD = -7;
  static const int NA_UNKNOWN_CARD_VERSION = -8;
  static const int NA_DISCONNECTION_ERROR = -9;
  static const int NA_INIT_ERROR = -10;
  static const int NA_READER_NOT_SUPPORTED = -11;
  static const int NA_LICENSE_FILE_ERROR = -12;
  static const int NA_PARAMETERS_ERROR = -13;
  static const int NA_INTERNET_ERROR = -15;
  static const int NA_CARD_NOT_FOUND = -16;
  static const int NA_BLUETOOTH_DISABLED = -17;
  static const int NA_LICENSE_UPDATE_ERROR = -18;
  static const int NA_STORAGE_PERMISSION_ERROR = -31;
  static const int NA_LOCATION_PERMISSION_ERROR = -32;
  static const int NA_BLUETOOTH_PERMISSION_ERROR = -33;
  static const int NA_LOCATION_SERVICE_ERROR = -41;

  late Uint8List bytesPhoto = Uint8List.fromList([]);
  late Uint8List bytesAppPhoto = Uint8List.fromList([]);
  // Map<Permission, PermissionStatus> statuses = new Map();

  String sAppName = "";
  String readerName = 'Reader: ';
  String textResult = "";
  String sLicenseInfo = "";
  String sSoftwareInfo = "";
  String folder = "";
  String sLICFileName = "";
  String rootFolder = "";
  String sLicFile = "";
  String parameterOpenLib = "";
  bool isEnabled = true;
  bool isVisible = false;
  bool isReaderConnected = false;
  bool isReading = false;
  bool isBusy = false;

  StreamController<String> entry = StreamController<String>();

  //  _currentEntries.listen((listOfStrings) {
  //     // From this point you can use listOfStrings as List<String> object
  //     // and do all other business logic you want

  //     for (String myString in listOfStrings) {
  //       print(myString);
  //     }
  //  });

  Future<void> methodHandler(MethodCall call) async {
    final String idea = call.arguments;

    switch (call.method) {
      case "showNewIdea": // this method name needs to be the same from invokeMethod in Android
        print("call init reader ${idea}");
        // DataService.instance.addIdea(
        //     idea); // you can handle the data here. In this example, we will simply update the view via a data service
        break;
      default:
        print('no method handler for method ${call.method}');
    }
  }

  ESMIDCard() {
    print("call init reader");

    platform.setMethodCallHandler(_fromNative);

    initAndroid();
  }

  void read() async {
    print("call read");
    buttonRead();
  }

  void readAuto() async {
    print(
      "call readAuto - isEnabled: $isEnabled, isReaderConnected: $isReaderConnected",
    );
    if (isEnabled && isReaderConnected) {
      print("calling buttonRead() for full read process");
      buttonRead(); // Call the full read process instead of autoReadProcess
    } else {
      print("Reader not ready - trying to reconnect...");
      // Try to reconnect reader
      if (!isReaderConnected) {
        print("🔄 Attempting reader reconnection...");
        try {
          await findReader();
        } catch (e) {
          print("❌ Reconnection failed: $e");
        }
      }
    }
  }

  //////////////////////////////// Initialize for Android ////////////////////////////////
  void initAndroid() async {
    // Android-specific code/UI Component
    folder = "/" + "NAiFlutter";
    sLICFileName = "/" + "rdnidlib.dls";
    await getFilesDirDF();
    // await setAppLogo();
    print("call setListenerDF");
    if (await setListenerDF() == false) return;
    if (await getSoftwareInfoDF() == false) return;
    if (await writeLicFileDF() == false) return;
    print("call setPermissionsDF");
    if (await setPermissionsDF() == false) return;
    print("call openLibDF");
    if (await openLibDF() == false) return;
    if (await getLicenseInfoDF() == false) return;

    requestPermission();

    // setState(() {
    isEnabled = true;
    // });
    print(
      "✅ Android initialization complete - ready for manual findReader call",
    );
    // Don't auto-call findReader - wait for user action
  }

  ///////////////////////////////// Response from native /////////////////////////////////
  Future<void> _fromNative(MethodCall call) async {
    if (call.method == 'callTestResuls') {
      print('callTest result = ${call.arguments}');
    }
  }

  ///////////////////////////////// Exit App /////////////////////////////////
  Future<void> exitApp() {
    deselectReaderDF();
    closeLibDF();
    exit(0);
  }

  //////////////////////////////// Get File Directory ////////////////////////////////
  Future<void> getFilesDirDF() async {
    try {
      String sFilesDirectory = await platform.invokeMethod(
        'getFilesDirMC',
      ); // Call native method getFilesDirMC
      rootFolder =
          sFilesDirectory +
          folder; // you can change path of license files at here
      sLicFile = rootFolder + sLICFileName;
      parameterOpenLib = sLicFile;
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      // setState(() {
      textResult = text;
      // });
    }
  }

  //////////////////////////////// Generate Photo to UI ////////////////////////////////
  Future<void> setAppLogo() async {
    try {
      ByteData data = await rootBundle.load(
        'assets/flutter_logo.png',
      ); // you can set assets path at pubspec.yaml
      bytesAppPhoto = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // setState(() {
      bytesPhoto = bytesAppPhoto;
      isVisible = true;
      // });
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";

      // setState(() {
      isVisible = true;
      textResult = text;
      // });
    }
  }

  //////////////////////////////// Set Listener ////////////////////////////////
  Future<bool> setListenerDF() async {
    try {
      int returnCode = await platform.invokeMethod(
        'setListenerMC',
      ); // Call native method setListenerMC
      if (returnCode == NA_SUCCESS) {
        return true;
      } else {
        // setState(() {
        textResult = this.checkException(returnCode);
        // });
        return false;
      }
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      // setState(() {
      textResult = text;
      // });
      return false;
    }
  }

  //////////////////////////////// Request Permission Function ////////////////////////////////
  void requestPermission() async {
    // var androidInfo = await DeviceInfoPlugin().androidInfo;
    // var sdkInt = androidInfo.version.sdkInt;
    // Permissions are now handled in the UI layer
    print('📋 Permissions handled by UI layer');
  }

  //////////////////////////////// Write File Function ////////////////////////////////
  Future<bool> writeLicFileDF() async {
    String text = "";
    try {
      int returnCode = await platform.invokeMethod(
        'writeLicFileMC',
        sLicFile,
      ); // Call native method writeLicFileMC

      if (returnCode == 1) {
        text = "License file is already has been.";

        // setState(() {
        textResult = text;
        // });
        return true;
      } else if (returnCode != 0) {
        text = "Write License file failed.";
        // setState(() {
        textResult = text;
        // });
        return false;
      } else {
        return true;
      }
    } on PlatformException catch (e) {
      text += "\n" + "Failed to Invoke: '${e.message}'.";
      // setState(() {
      textResult = text;
      // });
      return false;
    }
  }

  //////////////////////////////// Set Permission ////////////////////////////////
  Future<bool> setPermissionsDF() async {
    try {
      int pms = 1;
      int returnCode = await platform.invokeMethod(
        'setPermissionsMC',
        pms,
      ); // Call native method setPermissionsMC
      if (returnCode < 0) {
        // setState(() {
        textResult = checkException(returnCode);
        // });
        return false;
      }
      return true;
    } on PlatformException catch (e) {
      String result = "\n" + "Failed to Invoke: '${e.message}'.";
      // setState(() {
      textResult = result;
      // });
      return false;
    }
  }

  //////////////////////////////// Open Lib ////////////////////////////////
  Future<bool> openLibDF() async {
    String text = "";
    try {
      int returnCode = await platform.invokeMethod(
        'openLibMC',
        parameterOpenLib,
      ); // Call native method openLibMC
      if (returnCode == 0) {
        text = text + "\n" + "Opened the library successfully.";
        // setState(() {
        textResult = text;
        readerName = 'Reader: ';
        // });
        return true;
      } else {
        text = "Opened the library failed, Please restart app.";
        // setState(() {
        textResult = text;
        readerName = 'Reader: ';
        // });
        return false;
      }
    } on PlatformException catch (e) {
      text = "Failed to Invoke: '${e.message}'.";
      // setState(() {
      textResult = text;
      readerName = 'Reader: ';
      // });
      return false;
    }
  }

  //////////////////////////////// get Reader List ////////////////////////////////
  Future<dynamic> getReaderListDF() async {
    var result;

    try {
      print("🔧 Starting getReaderListDF...");

      if (IO.Platform.isAndroid) {
        int listOption =
            NA_SCAN +
            NA_BLE1 +
            NA_BLE0 +
            NA_BT +
            NA_USB; // Remove NA_POPUP to avoid popup dialog

        print("📋 Using listOption: $listOption");

        // var androidInfo = await DeviceInfoPlugin().androidInfo;
        // var sdkInt = androidInfo.version.sdkInt;
        var sdkInt = 31;
        if (sdkInt >= 31) {
          if ((listOption & NA_SCAN) != 0 &&
              ((listOption & NA_BT) != 0 ||
                  (listOption & NA_BLE1) != 0 ||
                  (listOption & NA_BLE0) != 0)) {
            // Bluetooth permission checks commented out for now
          }
        } else {
          if ((listOption & NA_SCAN) != 0 &&
              ((listOption & NA_BT) != 0 ||
                  (listOption & NA_BLE1) != 0 ||
                  (listOption & NA_BLE0) != 0)) {
            // Location permission checks commented out for now
          }
        }

        print(
          "📞 About to call native getReaderListMC with option: $listOption",
        );

        // Add small delay to ensure native is ready
        await Future.delayed(Duration(milliseconds: 100));

        result = await platform.invokeMethod(
          'getReaderListMC',
          listOption,
        ); // Call native method getReaderListMC

        print("✅ Native call completed successfully, result: $result");
      } else if (IO.Platform.isIOS) {
        result = await platform.invokeMethod(
          'getReaderListMC',
        ); // Call native method getReaderListMC
      }

      if (result == null) {
        print("❌ Native method returned null");
        return null;
      }

      var parts = result.split(';');
      print("📋 Split result: $parts");
      return parts;
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      print("❌ PlatformException in getReaderListDF: $text");
      print("❌ PlatformException details: ${e.details}");
      print("❌ PlatformException code: ${e.code}");

      // setState(() {
      textResult = text;
      isEnabled = true;
      // });
      return null;
    } catch (e) {
      print("❌ General exception in getReaderListDF: $e");
      print("❌ Exception type: ${e.runtimeType}");
      textResult = "Unexpected error: $e";
      isEnabled = true;
      return null;
    }
  }

  //////////////////////////////// Select Reader ////////////////////////////////
  Future<bool> selectReaderDF(String textReaderName) async {
    try {
      int returnCode = await platform.invokeMethod(
        'selectReaderMC',
        textReaderName,
      ); // Call native method selectReaderMC

      if (returnCode != NA_SUCCESS) {
        // setState(() {
        textResult = checkException(returnCode);
        // });

        if (returnCode != NA_INVALID_LICENSE &&
            returnCode != NA_LICENSE_FILE_ERROR) {
          // setState(() {
          isEnabled = true;
          readerName = 'Reader: ';
          // });
        } else if (returnCode == NA_INVALID_LICENSE ||
            returnCode == NA_LICENSE_FILE_ERROR) {
          // setState(() {
          isEnabled = true;
          readerName = 'Reader: ' + textReaderName;
          // });
        }

        return false;
      } else if (returnCode == NA_SUCCESS) {
        isReaderConnected = true;
        // setState(() {
        readerName = 'Reader: ' + textReaderName;
        // });
      }
      return true;
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";

      // setState(() {
      textResult = text;
      isEnabled = true;
      // });
      return false;
    }
  }

  //////////////////////////////// Get Reader Info ////////////////////////////////
  Future<void> getReaderInfoDF() async {
    String readerInfo = "";
    if (isReaderConnected == false) {
      // setState(() {
      textResult = "";
      isEnabled = true;
      // });
      return;
    }
    try {
      var result = await platform.invokeMethod(
        'getReaderInfoMC',
      ); // Call native method getReaderInfoMC
      var parts = result.split(';');
      int returnCode = int.parse(parts[0].trim());
      if (returnCode == NA_SUCCESS) {
        readerInfo = parts[1].trim();
        result = "Reader Info: " + readerInfo;
      } else {
        result = checkException(returnCode);
      }
      // setState(() {
      textResult = result;
      // });
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      // setState(() {
      textResult = text;
      // });
    }
  }

  //////////////////////////////// Connect Card ////////////////////////////////
  Future<int> connectCardDF() async {
    try {
      int returnCode = await platform.invokeMethod(
        'connectCardMC',
      ); // Call native method connectCardMC
      return returnCode;
    } on PlatformException {
      return NA_CONNECTION_ERROR;
    }
  }

  //////////////////////////////// Get NID Number ////////////////////////////////
  Future<dynamic> getNIDNumberDF() async {
    try {
      String result = await platform.invokeMethod(
        'getNIDNumberMC',
      ); // Call native method getNIDNumberMC
      var parts = result.split(';');
      return parts;
    } on PlatformException {
      return null;
    }
  }

  //////////////////////////////// Get Text ////////////////////////////////
  Future<dynamic> getTextDF() async {
    try {
      String result = await platform.invokeMethod(
        'getTextMC',
      ); // Call native method getTextMC
      var parts = result.split(';');
      return parts;
    } on PlatformException {
      return null;
    }
  }

  //////////////////////////////// Get Photo ////////////////////////////////
  Future<dynamic> getPhotoDF() async {
    try {
      String result = await platform.invokeMethod(
        'getPhotoMC',
      ); // Call native method getPhotoMC

      var parts = result.split(';');

      return parts;
    } on PlatformException {
      return null;
    }
  }

  //////////////////////////////// Disconnect Card ////////////////////////////////
  Future<int> disconnectCardDF() async {
    try {
      int returnCode = await platform.invokeMethod(
        'disconnectCardMC',
      ); // Call native method disconnectCardMC
      return returnCode;
    } on PlatformException {
      return -1;
    }
  }

  //////////////////////////////////// Deselect Reader ////////////////////////////////////
  Future<int> deselectReaderDF() async {
    try {
      int returnCode = await platform.invokeMethod(
        'deselectReaderMC',
      ); // Call native method deselectReaderMC
      return returnCode;
    } on PlatformException {
      return -1;
    }
  }

  //////////////////////////////// Update License ////////////////////////////////
  Future<int> updateLicenseFileDF() async {
    try {
      int returnCode = await platform.invokeMethod(
        'updateLicenseFileMC',
      ); // Call native method updateLicenseMC
      return returnCode;
    } on PlatformException {
      return NA_LICENSE_UPDATE_ERROR;
    }
  }

  //////////////////////////////// Get Card Status ////////////////////////////////
  Future<int> getCardStatusDF() async {
    try {
      int returnCode = -1;
      final result = await platform.invokeMethod(
        'getCardStatusMC',
      ); // Call native method getCardStatusMC
      if (result is int) {
        returnCode = result;
      } else {
        print("getCardStatusMC result is not int" + result.toString());
        returnCode = -1;
      }

      return returnCode;
    } on PlatformException {
      return -1;
    }
  }

  //////////////////////////////// Get RID ////////////////////////////////
  Future<dynamic> getReaderIDDF() async {
    try {
      String result = await platform.invokeMethod(
        'getReaderIDMC',
      ); // Call native method getReaderIDMC
      var parts = result.split(';');
      return parts;
    } on PlatformException {
      return null;
    }
  }

  //////////////////////////////// Get Software Info ////////////////////////////////
  Future<bool> getSoftwareInfoDF() async {
    String text = "";
    try {
      text = await platform.invokeMethod(
        'getSoftwareInfoMC',
      ); // Call native method getSoftwareInfoMC
      // setState(() {
      sSoftwareInfo = text;
      // });
      return true;
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";
      // setState(() {
      textResult = text;
      // });
      return false;
    }
  }

  //////////////////////////////// Get License Info ////////////////////////////////
  Future<bool> getLicenseInfoDF() async {
    String result = "";
    try {
      result = await platform.invokeMethod(
        'getLicenseInfoMC',
      ); // Call native method getLicenseInfoMC
      // setState(() {
      sLicenseInfo = result;
      // });
      return true;
    } on PlatformException {
      // setState(() {});
      return false;
    }
  }

  //////////////////////////////////// Close Lib ////////////////////////////////////
  Future<int> closeLibDF() async {
    try {
      int returnCode = await platform.invokeMethod(
        'closeLibMC',
      ); // Call native method closeLibMC
      return returnCode;
    } on PlatformException {
      return -1;
    }
  }

  //////////////////////////////////// Exception ////////////////////////////////////
  String checkException(int returnCode) {
    if (returnCode == NA_INTERNAL_ERROR) {
      return "-1 Internal error.";
    } else if (returnCode == NA_INVALID_LICENSE) {
      return "-2 This reader is not licensed.";
    } else if (returnCode == NA_READER_NOT_FOUND) {
      return "-3 Reader not found.";
    } else if (returnCode == NA_CONNECTION_ERROR) {
      return "-4 Card connection error.";
    } else if (returnCode == NA_GET_PHOTO_ERROR) {
      return "-5 Get photo error.";
    } else if (returnCode == NA_GET_TEXT_ERROR) {
      return "-6 Get text error.";
    } else if (returnCode == NA_INVALID_CARD) {
      return "-7 Invalid card.";
    } else if (returnCode == NA_UNKNOWN_CARD_VERSION) {
      return "-8 Unknown card version.";
    } else if (returnCode == NA_DISCONNECTION_ERROR) {
      return "-9 Disconnection error.";
    } else if (returnCode == NA_INIT_ERROR) {
      return "-10 Init error.";
    } else if (returnCode == NA_READER_NOT_SUPPORTED) {
      return "-11 Reader not supported.";
    } else if (returnCode == NA_LICENSE_FILE_ERROR) {
      return "-12 License file error.";
    } else if (returnCode == NA_PARAMETERS_ERROR) {
      return "-13 Parameter error.";
    } else if (returnCode == NA_INTERNET_ERROR) {
      return "-15 Internet error.";
    } else if (returnCode == NA_CARD_NOT_FOUND) {
      return "-16 Card not found.";
    } else if (returnCode == NA_BLUETOOTH_DISABLED) {
      return "-17 Bluetooth is disabled.";
    } else if (returnCode == NA_LICENSE_UPDATE_ERROR) {
      return "-18 License update error.";
    } else if (returnCode == NA_STORAGE_PERMISSION_ERROR) {
      return "-31 Storage permission error.";
    } else if (returnCode == NA_LOCATION_PERMISSION_ERROR) {
      return "-32 Location permission error.";
    } else if (returnCode == NA_BLUETOOTH_PERMISSION_ERROR) {
      return "-33 Bluetooth permission error.";
    } else if (returnCode == NA_LOCATION_SERVICE_ERROR) {
      return "-41 Location service error.";
    } else {
      return returnCode.toString();
    }
  }

  //////////////////////////////// Button Find Reader ////////////////////////////////
  Future<void> findReader() async {
    print("🔍 findReader() called");

    // Reset connection state
    isReaderConnected = false;
    isEnabled = false;

    String text = "Reader scanning...";
    readerName = text;
    textResult = "";
    bytesPhoto = bytesAppPhoto;

    try {
      // ===================== Get Reader List ======================== //
      print("📡 Getting reader list...");
      var parts;
      try {
        parts = await getReaderListDF();
      } catch (e) {
        print("❌ Error in getReaderListDF: $e");
        readerName = 'Reader: ';
        isEnabled = true;
        textResult = "Error getting reader list: $e";
        return;
      }

      if (parts == null) {
        print("❌ getReaderListDF returned null");
        readerName = 'Reader: ';
        isEnabled = true;
        textResult = "-3 Reader not found.";
        return;
      }

      var returnCode = int.parse(parts[0].trim());
      print("📋 getReaderListDF result: $returnCode, parts: $parts");

      if (returnCode == 0 || returnCode == -3) {
        print("❌ No readers found");
        readerName = 'Reader: ';
        isEnabled = true;
        textResult = "-3 Reader not found.";
        return;
      } else if (returnCode < 0) {
        print("❌ Reader list error: $returnCode");
        isEnabled = true;
        readerName = 'Reader: ';
        textResult = checkException(returnCode);
        return;
      } else if (returnCode > 0 && parts.length > 1) {
        String textReaderName = parts[1].trim();
        print("🎯 Found reader: $textReaderName");

        readerName = "Reader selecting...";

        // ===================== Select Reader ======================== //
        print("🔗 Selecting reader: $textReaderName");
        bool success = await selectReaderDF(textReaderName);

        if (success) {
          print("✅ Reader selected successfully: $textReaderName");
          isReaderConnected = true;
          readerName = 'Reader: $textReaderName';

          // ===================== Get Reader Info ======================== //
          await getReaderInfoDF();

          // ===================== Get License Info ======================== //
          await getLicenseInfoDF();

          print("🎉 Reader setup complete!");
        } else {
          print("❌ Failed to select reader: $textReaderName");
          isReaderConnected = false;
          readerName = 'Reader: ';
          textResult = "Failed to connect to reader: $textReaderName";
        }
      } else {
        print("❌ Invalid reader list response");
        readerName = 'Reader: ';
        isEnabled = true;
        textResult = "Invalid reader response";
      }
    } catch (e) {
      print("❌ Exception in findReader: $e");
      readerName = 'Reader: ';
      isEnabled = true;
      textResult = "Error finding reader: $e";
    } finally {
      isEnabled = true;
      print("🏁 findReader completed - isReaderConnected: $isReaderConnected");
    }
  }

  //////////////////////////////// Button Read Card ////////////////////////////////
  Future<void> buttonRead() async {
    print("🔄 buttonRead() called - isReading: $isReading");

    if (isReading) {
      print("⚠️ Already reading, skipping");
      return;
    }

    isReading = true;
    print("✅ Starting buttonRead process");

    String text = "Reading...";
    // setState(() {
    isEnabled = false;
    bytesPhoto = bytesAppPhoto;
    textResult = text;
    // });

    try {
      // ===================== Check Card Status ======================== //
      if (IO.Platform.isIOS) {
        int returnCode = await getCardStatusDF();
        if (returnCode != 1) {
          text = checkException(returnCode);

          if (isReaderConnected != true) {
            text = "-3 Reader not found.";
          }
          // setState(() {
          textResult = text;
          isEnabled = true;
          // });
          isReading = false;
          return;
        }
      }
      print("connect card");
      // ===================== Connect Card ======================== //
      int startTime = new DateTime.now().millisecondsSinceEpoch;
      int resConnect = await connectCardDF();
      if (resConnect != NA_SUCCESS) {
        print("connect card error");
        // setState(() {
        textResult = checkException(resConnect);
        isEnabled = true;
        isReading = false;
        // });
        return;
      }

      // ===================== Get Text ======================== //
      int returnCode = -1;
      print("get text P ok");
      var parts = await getTextDF();
      int endTime = new DateTime.now().millisecondsSinceEpoch;
      double readTextTime = ((endTime - startTime) / 1000);

      if (parts == null)
        returnCode = NA_GET_TEXT_ERROR;
      else {
        returnCode = int.parse(parts[0].trim());
        text = parts[1].trim();
      }

      if (returnCode != NA_SUCCESS) {
        print("get error");
        // setState(() {
        textResult = checkException(returnCode);
        isEnabled = true;
        // });
        // ===================== Disconnect Card ======================== //
        await disconnectCardDF();
        isReading = false;
        return;
      }
      print('---------->1 ${text}');
      text += "\n\nRead Text: " + readTextTime.toStringAsFixed(2) + " s";
      print(text);
      // setState(() {
      textResult = text;
      // });

      print("📤 Sending data to stream: ${text.substring(0, 50)}...");
      entry.sink.add(text);
      print("✅ Data sent to stream successfully");

      // ===================== Get Photo ======================== //
      var parts2 = await getPhotoDF();

      if (parts == null)
        returnCode = NA_GET_PHOTO_ERROR;
      else {
        returnCode = int.parse(parts2[0].trim());
        text = parts2[1].trim();
      }

      if (returnCode != NA_SUCCESS) {
        if (textResult != checkException(returnCode)) {
          textResult = textResult + "\n" + checkException(returnCode);
        }
        // setState(() {
        textResult = textResult;
        isEnabled = true;
        // });

        // ===================== Disconnect Card ======================== //
        await disconnectCardDF();
        isReading = false;
        return;
      }

      String photo = parts2[1].trim();
      var resBytesPhoto = base64Decode(photo);

      // setState(() {
      bytesPhoto = resBytesPhoto;
      // });

      // ===================== Disconnect Card ======================== //
      await disconnectCardDF();
      endTime = new DateTime.now().millisecondsSinceEpoch;
      double readPhotoTime = ((endTime - startTime) / 1000);

      // setState(() {
      textResult =
          textResult +
          "\nRead Text+Photo: " +
          readPhotoTime.toStringAsFixed(2) +
          " s";
      isEnabled = true;

      print(textResult);
      // });
    } on PlatformException catch (e) {
      String text = "Failed to Invoke: '${e.message}'.";

      // setState(() {
      textResult = text;
      isEnabled = true;
      // });
    }
    isReading = false;
  }

  //////////////////////////////// Button Get Card Status ////////////////////////////////
  Future<void> buttonGetCardStatus() async {
    String text = "Checking card in reader...";
    if (isReading == false) {
      // setState(() {
      isEnabled = false;
      bytesPhoto = bytesAppPhoto;
      textResult = text;
      // });

      try {
        // ===================== Check Card Status ======================== //
        int returnCode =
            await getCardStatusDF(); // Call native method getCardStatusMC

        if (returnCode == 1) {
          text = "Card Status: Present";
        } else if (returnCode == -16) {
          text = "Card Status: Absent (card not found)";
        } else {
          text = checkException(returnCode);
          if (IO.Platform.isIOS) {
            if (isReaderConnected != true) {
              text = "-3 Reader not found.";
            }
          }
        }
        print(text);

        // setState(() {
        isEnabled = true;
        textResult = text;
        // });
      } on PlatformException catch (e) {
        String text = "Failed to Invoke: '${e.message}'.";
        // setState(() {
        textResult = text;
        isEnabled = true;
        // });
      }
    }
  }

  //////////////////////////////// Button Get Card Status ////////////////////////////////
  Future<void> autoReadProcess() async {
    String text = "Checking card in reader...";
    if (isReading == false) {
      // setState(() {
      isEnabled = false;
      bytesPhoto = bytesAppPhoto;
      textResult = text;
      // });
      // findReader();

      try {
        // ===================== Check Card Status ======================== //
        int returnCode =
            await getCardStatusDF(); // Call native method getCardStatusMC

        if (returnCode == 1) {
          text = "Card Status: Present";

          if (isBusy == false) {
            read();
            isBusy = true;
          }
        } else if (returnCode == -16) {
          text = "Card Status: Absent (card not found)";
          isBusy = false;
        } else {
          text = checkException(returnCode);
          if (IO.Platform.isIOS) {
            if (isReaderConnected != true) {
              text = "-3 Reader not found.";
            }
          }
        }
        print(text);

        // setState(() {
        isEnabled = true;
        textResult = text;
        // });
      } on PlatformException catch (e) {
        String text = "Failed to Invoke: '${e.message}'.";
        // setState(() {
        textResult = text;
        isEnabled = true;
        // });
      }
    }
  }

  Stream<String> getEntry() {
    return entry.stream;
  }
}
