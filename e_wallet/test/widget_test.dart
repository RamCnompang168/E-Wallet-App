import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_wallet/core/theme/app_theme.dart';
import 'package:e_wallet/features/notifications/presentation/screens/notification_list_screen.dart';
import 'package:e_wallet/features/qr/presentation/screens/qr_scanner_screen.dart';
import 'package:e_wallet/features/shell/presentation/screens/main_navigation_shell.dart';
import 'package:e_wallet/features/transaction/presentation/screens/transaction_history_screen.dart';
import 'package:e_wallet/features/transaction/presentation/widgets/transaction_pin_pad_sheet.dart';
import 'package:e_wallet/main.dart';

void main() {
  testWidgets('shows NovaPay splash branding', (tester) async {
    await tester.pumpWidget(const NovaPayApp());
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('NovaPay'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('wallet ID copy action gives visible confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const MainNavigationShell(onThemeChanged: _noop),
      ),
    );

    await tester.tap(find.text('COPY ID'));
    await tester.pump();

    expect(find.text('Wallet ID copied to clipboard.'), findsOneWidget);
  });

  testWidgets('transaction history filters results', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TransactionHistoryScreen(onTransactionTap: (_) {}),
        ),
      ),
    );

    await tester.tap(find.text('Sent'));
    await tester.pump();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Cash deposit'), findsNothing);
  });

  testWidgets('notifications can be marked as read', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const NotificationListScreen()),
    );

    await tester.tap(find.text('Mark all read'));
    await tester.pump();

    expect(find.text('All caught up'), findsOneWidget);
    expect(find.text('Read'), findsNWidgets(3));
  });

  testWidgets('scanner controls have working actions', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: QrScannerScreen(onClose: () => closed = true),
      ),
    );

    await tester.tap(find.byTooltip('Turn flash on'));
    await tester.pump();
    expect(find.byTooltip('Turn flash off'), findsOneWidget);

    await tester.tap(find.byTooltip('Close scanner'));
    expect(closed, isTrue);
  });

  testWidgets('transaction pin pad renders completely with digit 0 and triggers completion', (tester) async {
    String? enteredPin;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TransactionPinPadSheet(
            onCompleted: (pin) => enteredPin = pin,
          ),
        ),
      ),
    );

    // Verify key 0 and key 1 are present
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Enter transaction PIN'), findsOneWidget);

    // Tap 6 digits including 0
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();

    expect(enteredPin, '123450');
  });
}

void _noop() {}
