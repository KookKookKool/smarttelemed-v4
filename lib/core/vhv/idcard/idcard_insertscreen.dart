import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/style/background_2.dart';
import 'package:smarttelemed_v4/style/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smarttelemed_v4/core/idcard/idcard_reader.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class IdCardInsertScreen extends StatefulWidget {
  const IdCardInsertScreen({Key? key}) : super(key: key);

  @override
  State<IdCardInsertScreen> createState() => _IdCardInsertScreenState();
}

class _IdCardInsertScreenState extends State<IdCardInsertScreen> {
  late ESMIDCard reader;
  Stream<String>? entry;
  Timer? readingtime;
  Timer? reading;
  bool shownumpad = false;
  Timer? _timer;
  Timer? timerreadIDCard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // runs after build()

      readerID();
    });
  }

  void readerID() {
    try {
      Future.delayed(const Duration(seconds: 1), () {
        reader = ESMIDCard.instance;

        entry = reader?.getEntry();

        debugPrint('->initstate');
        if (entry != null) {
          debugPrint('->prepare stream');

          entry?.listen(
            (String data) async {
              List<String> splitted = data.split('#');
              debugPrint("IDCard $data");

              Fluttertoast.showToast(
                msg: "" + data,
                toastLength: Toast.LENGTH_SHORT, // or Toast.LENGTH_LONG
                gravity: ToastGravity.BOTTOM, // TOP, CENTER, BOTTOM
                backgroundColor: Colors.black54,
                textColor: Colors.white,
                fontSize: 16.0,
              );

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
              debugPrint(error);
            },
            onDone: () {
              debugPrint('Stream closed!');
            },
          );
        } else {}
        const oneSec = Duration(seconds: 1);
        reading = Timer.periodic(oneSec, (Timer t) => checkCard());
      });
    } on Exception catch (e) {
      debugPrint('error');
      debugPrint(e.toString());
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
    reader?.readAuto();
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
  Widget build(BuildContext context) {
    return CircleBackground2(
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
                            onPressed: () {
                              Navigator.pushNamed(context, '/idcardloader');
                            },
                            child: const Text(
                              'สำเร็จ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
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
                            onPressed: () {
                              // Navigator.pushNamed(context, '/idcardloader');
                              reader?.findReader();
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
                      // text for no ID card
                      Text(
                        'ไม่มีบัตรประชาชน',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                    ],
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
