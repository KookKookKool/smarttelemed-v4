import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Column(
              children: [
                Image.asset(
              'assets/logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
                const SizedBox(height: 5),
              ],
            ),
            const SizedBox(height: 10),

            // Buttons
            ElevatedButton(
              onPressed: () {
                _navigateTo(context, '/general');
              },
              child: const Text('บุคคลทั่วไป',
              style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(255, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            const SizedBox(height: 38),
            ElevatedButton(
              onPressed: () {
                _navigateTo(context, '/loginToken');
              },
              child: const Text('อาสาสมัคร',
              style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(255, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            const SizedBox(height: 38
            ),
            ElevatedButton(
              onPressed: () {
                _navigateTo(context, '/hospital');
              },
              child: const Text('โรงพยาบาล',
              style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(255, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}