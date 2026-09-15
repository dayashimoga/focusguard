import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/presentation/widgets/adaptive_scaffold.dart';

void main() {
  const destinations = [
    AdaptiveDestination(
        icon: Icons.home, selectedIcon: Icons.home, label: 'Home'),
    AdaptiveDestination(
        icon: Icons.settings, selectedIcon: Icons.settings, label: 'Settings'),
  ];

  group('Widget: AdaptiveScaffold', () {
    testWidgets(
        'renders BottomNavigationBar on mobile viewport (< 720dp width)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: destinations,
            body: const Text('Mobile Content'),
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Mobile Content'), findsOneWidget);
    });

    testWidgets(
        'renders NavigationRail on tablet/desktop viewport (>= 720dp width)',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffold(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: destinations,
            body: const Text('Tablet Content'),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Tablet Content'), findsOneWidget);
    });
  });
}
