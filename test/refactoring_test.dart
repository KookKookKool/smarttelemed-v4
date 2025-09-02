import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Test imports for different app modules
import 'package:smarttelemed_v4/shared/style/app_colors.dart';
import 'package:smarttelemed_v4/shared/utils/responsive.dart';
import 'package:smarttelemed_v4/shared/widgets/manubar.dart';
import 'package:smarttelemed_v4/routes/app_routes.dart';

// App-specific imports
import 'package:smarttelemed_v4/apps/vhv/dashboard_screen.dart';
import 'package:smarttelemed_v4/apps/personal/mainpt_screen.dart';

void main() {
  group('Refactored Structure Tests', () {
    testWidgets('VHV Dashboard Screen can be created', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DashboardScreen(),
          routes: AppRoutes.routes,
        ),
      );
      
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Personal MainPT Screen can be created', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MainPtScreen(),
          routes: AppRoutes.routes,
        ),
      );
      
      expect(find.byType(MainPtScreen), findsOneWidget);
    });

    test('AppRoutes contains expected routes', () {
      final routes = AppRoutes.routes;
      
      // Test shared routes
      expect(routes.containsKey('/auth'), true);
      expect(routes.containsKey('/settings'), true);
      expect(routes.containsKey('/device'), true);
      
      // Test VHV routes
      expect(routes.containsKey('/general'), true);
      expect(routes.containsKey('/loginToken'), true);
      expect(routes.containsKey('/dashboard'), true);
      
      // Test Personal routes
      expect(routes.containsKey('/mainpt'), true);
      expect(routes.containsKey('/profilept'), true);
      
      // Test Hospital routes
      expect(routes.containsKey('/hospital'), true);
      expect(routes.containsKey('/doctor'), true);
      expect(routes.containsKey('/appoint'), true);
    });

    test('Shared widgets can be imported', () {
      // Test that shared components can be instantiated
      expect(const Manubar(), isA<Widget>());
    });
  });
}