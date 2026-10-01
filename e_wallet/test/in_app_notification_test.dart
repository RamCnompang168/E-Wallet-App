import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_wallet/core/services/in_app_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InAppNotificationService Tests', () {
    testWidgets('displays real top-side notification banner overlay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: InAppNotificationService.navigatorKey,
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  InAppNotificationService.instance.show(
                    title: 'Deposit Confirmed',
                    message: 'Deposit of \$100.00 confirmed and added to wallet balance.',
                    icon: Icons.south_west_rounded,
                    iconColor: const Color(0xFF00D09C),
                  );
                },
                child: const Text('Show Top Notification'),
              ),
            ),
          ),
        ),
      );

      // Verify button is present
      expect(find.text('Show Top Notification'), findsOneWidget);

      // Tap button to show notification
      await tester.tap(find.text('Show Top Notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Notification banner should be visible at top with app badge, title, and message
      expect(find.text('NOVAPAY'), findsOneWidget);
      expect(find.text('• Just now'), findsOneWidget);
      expect(find.text('Deposit Confirmed'), findsOneWidget);
      expect(
        find.text('Deposit of \$100.00 confirmed and added to wallet balance.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);

      // Swipe up to dismiss
      await tester.drag(find.text('Deposit Confirmed'), const Offset(0, -50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After dismissal animation completes, banner should be gone
      expect(find.text('Deposit Confirmed'), findsNothing);
    });

    testWidgets('dismisses top notification when close icon is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: InAppNotificationService.navigatorKey,
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  InAppNotificationService.instance.show(
                    title: 'Withdrawal Successful',
                    message: 'Withdrawal of \$50.00 completed.',
                    icon: Icons.north_east_rounded,
                    iconColor: Colors.deepOrangeAccent,
                  );
                },
                child: const Text('Withdraw Alert'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Withdraw Alert'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Withdrawal Successful'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Withdrawal Successful'), findsNothing);
    });

    testWidgets('tapping top notification invokes onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: InAppNotificationService.navigatorKey,
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  InAppNotificationService.instance.show(
                    title: 'Transfer Sent',
                    message: 'Sent \$25.00 to Sokha.',
                    icon: Icons.swap_horiz_rounded,
                    onTap: () {
                      tapped = true;
                    },
                  );
                },
                child: const Text('Transfer Alert'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Transfer Alert'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Transfer Sent'), findsOneWidget);

      await tester.tap(find.text('Transfer Sent'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tapped, isTrue);
    });
  });
}
