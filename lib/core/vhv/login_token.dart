import 'package:flutter/material.dart';
import 'login_qrcam.dart';

class LoginTokenPage extends StatefulWidget {
  const LoginTokenPage({Key? key}) : super(key: key);

  @override
  State<LoginTokenPage> createState() => _LoginTokenPageState();
}

class _LoginTokenPageState extends State<LoginTokenPage> {
  final TextEditingController _tokenController = TextEditingController();
  String? _errorText;

  void _onConfirm() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorText = 'กรุณากรอก Token';
      });
      return;
    }
    setState(() {
      _errorText = null;
    });
    // TODO: ใช้งาน token ต่อ เช่น ส่งไป validate หรือ navigate
    print('Token: $token');
    // Navigator.pushNamed(context, '/nextPage');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(''),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Text(
                      'Token Hospital',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 280,
                  height: 38,
                  child: TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      hintText: 'ESM123456790',
                      errorText: _errorText,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const LoginQrCamPage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(0.0, 1.0);
                                const end = Offset.zero;
                                const curve = Curves.ease;
                                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                          if (result != null && result is String) {
                            setState(() {
                              _tokenController.text = result;
                            });
                          }
                        },
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _onConfirm,
                  child: const Text('ยืนยัน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 13, 255, 150),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}