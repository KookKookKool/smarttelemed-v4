import 'package:flutter/material.dart';
import 'package:smarttelemed_v4/utils/responsive.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smarttelemed_v4/storage/storage.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  void _navigateTo(BuildContext context, String routeName) async {
    // Save session based on the route
    String userType;
    switch (routeName) {
      case '/general':
        userType = 'general';
        break;
      case '/loginToken':
        userType = 'volunteer';
        break;
      case '/hospital':
        userType = 'hospital';
        break;
      default:
        userType = 'unknown';
    }

    // Save session data
    await SessionStorage.saveSession(userType: userType);

    if (context.mounted) {
      Navigator.of(context).pushNamed(routeName);
    }
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
            Builder(
              builder: (ctx) {
                final r = ResponsiveSizer(ctx);
                return Column(
                  children: [
                    SvgPicture.asset(
                      'assets/logo.svg',
                      width: r.sw(160),
                      height: r.sw(160),
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: r.sh(6)),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),

            // Buttons
            ElevatedButton(
              onPressed: () {
                _navigateTo(context, '/general');
              },
              child: const Text('บุคคลทั่วไป', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(255, 50),
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
              child: const Text('อาสาสมัคร', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(255, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            const SizedBox(height: 38),
            ElevatedButton(
              onPressed: () {
                _navigateTo(context, '/hospital');
              },
              child: const Text('โรงพยาบาล', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                fixedSize: Size(255, 50),
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
