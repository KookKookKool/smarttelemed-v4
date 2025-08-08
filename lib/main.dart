import 'package:flutter/material.dart';
import 'core/splash/plus_loader.dart';
import 'core/splash/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Telemed V4',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const PlusLoaderPage(),
    );
  }
}

class PlusLoaderPage extends StatefulWidget {
  const PlusLoaderPage({Key? key}) : super(key: key);

  @override
  State<PlusLoaderPage> createState() => _PlusLoaderPageState();
}

class _PlusLoaderPageState extends State<PlusLoaderPage> {
  bool _zooming = false;

  void _goToSplashScreen() async {
    setState(() {
      _zooming = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedScale(
          scale: _zooming ? 18.0 : 1.0,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeIn,
          child: AnimatedOpacity(
            opacity: _zooming ? 1.0 : 1.0,
            duration: const Duration(milliseconds: 900),
            child: PlusLoader(size: 120, onCompleted: _goToSplashScreen),
          ),
        ),
      ),
    );
  }
}
