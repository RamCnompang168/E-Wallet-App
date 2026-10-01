import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_wallet/features/qr/data/khqr_helper.dart';
import 'package:e_wallet/features/qr/presentation/screens/receive_qr_screen.dart';
import 'package:e_wallet/features/transaction/domain/models/transaction.dart';
import 'package:e_wallet/features/transaction/presentation/screens/deposit_khqr_screen.dart';
import 'package:e_wallet/features/wallet/presentation/screens/wallet_tab.dart';

void main() {
  group('KHQR Helper Tests', () {
    test('generateKhqrPayload produces standard EMVCo static QR payload', () {
      final payload = KhqrHelper.generateKhqrPayload(
        accountId: 'WAL-01493803',
        merchantName: 'Sokha Chan',
        currency: 'USD',
      );

      expect(payload.startsWith('000201010211'), isTrue); // Static QR
      expect(payload.contains('29'), isTrue); // Tag 29
      expect(payload.contains('bakong@nbc'), isTrue);
      expect(payload.contains('WAL-01493803'), isTrue);
      expect(payload.contains('5303840'), isTrue); // USD currency 840
      expect(payload.contains('5802KH'), isTrue); // Cambodia country
      expect(payload.contains('5910SOKHA CHAN'), isTrue); // Name
      expect(payload.contains('6304'), isTrue); // Checksum tag

      // Check CRC format (last 4 characters are valid 4-hex digits)
      final crc = payload.substring(payload.length - 4);
      expect(RegExp(r'^[0-9A-F]{4}$').hasMatch(crc), isTrue);
    });

    test('generateKhqrPayload produces standard EMVCo dynamic QR payload with amount', () {
      final payload = KhqrHelper.generateKhqrPayload(
        accountId: 'WAL-59433784',
        merchantName: 'Thida Meas',
        amount: 25.50,
        currency: 'USD',
        billNumber: 'INV-1001',
      );

      expect(payload.startsWith('000201010212'), isTrue); // Dynamic QR (12)
      expect(payload.contains('540525.50'), isTrue); // Tag 54 Amount
      expect(payload.contains('INV-1001'), isTrue); // Bill number
    });

    test('generateKhqrPayload handles Cambodian Riel (KHR) currency tag 116', () {
      final payload = KhqrHelper.generateKhqrPayload(
        accountId: 'WAL-40564511',
        merchantName: 'Ron Ram',
        amount: 100000,
        currency: 'KHR',
      );

      expect(payload.contains('5303116'), isTrue); // KHR currency 116
      expect(payload.contains('5409100000.00'), isTrue);
    });

    test('calculateCrc16 produces deterministic checksum', () {
      final sample = '0002010102116304';
      final crc1 = KhqrHelper.calculateCrc16(sample);
      final crc2 = KhqrHelper.calculateCrc16(sample);
      expect(crc1, equals(crc2));
      expect(crc1.length, equals(4));
    });
  });

  group('TransactionModel timestamp Tests', () {
    test('TransactionModel parses ISO timestamp into DateTime object', () {
      final json = {
        'id': 'TXN-999',
        'amount': '150.00',
        'transaction_type': 'TRANSFER',
        'direction': 'INCOMING',
        'sender_name': 'Sokha Chan',
        'created_at': '2026-09-26T10:30:00Z',
      };

      final txn = TransactionModel.fromJson(json);
      expect(txn.timestamp, isNotNull);
      expect(txn.timestamp!.year, equals(2026));
      expect(txn.category, equals(TransactionCategory.received));
      expect(txn.amount, equals(150.0));
    });
  });

  group('ReceiveQrScreen & QrVisual Widget Tests', () {
    testWidgets('renders ReceiveQrScreen with official KHQR card and tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiveQrScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Receive money'), findsOneWidget);
      expect(find.text('My QR (KHQR)'), findsOneWidget);
      expect(find.text('Request amount'), findsOneWidget);
      expect(find.text('KHQR'), findsOneWidget);
      expect(find.text('Bakong Payment'), findsOneWidget);
      expect(find.text('ABA'), findsOneWidget);
      expect(find.text('ACLEDA'), findsOneWidget);
    });

    testWidgets('generates dynamic request amount QR when entering amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiveQrScreen(),
        ),
      );
      await tester.pump();

      // Switch to Request amount tab
      await tester.tap(find.text('Request amount'));
      await tester.pumpAndSettle();

      expect(find.text('Request a specific amount'), findsOneWidget);

      // Enter amount
      await tester.enterText(find.byType(TextField), '75.50');
      await tester.pump();

      // Tap generate button
      await tester.tap(find.text('Generate request QR'));
      await tester.pumpAndSettle();

      // Verify generated amount card displays $75.50
      expect(find.text(r'$75.50'), findsOneWidget);
      expect(find.text('KHQR bill for \$75.50 generated successfully.'), findsOneWidget);
    });
  });

  group('DepositKhqrScreen Widget Tests', () {
    testWidgets('renders DepositKhqrScreen with KHQR card and timer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DepositKhqrScreen(amount: 50.0),
        ),
      );
      await tester.pump();

      expect(find.text('KHQR Deposit Payment'), findsOneWidget);
      expect(find.text('Scan with ABA, ACLEDA, or Bakong'), findsOneWidget);
      expect(find.text(r'$50.00'), findsOneWidget);
      expect(find.text('I have scanned & paid with Bank'), findsOneWidget);
      expect(find.text('Save QR Code to Gallery'), findsOneWidget);
    });
  });

  group('WalletTab KPI Breakdown Tests', () {
    testWidgets('renders WalletTab with detailed Received, Deposited, Sent, Withdrawn, and Success/Failed KPI cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WalletTab(
              balanceHidden: false,
              onVisibilityTap: () {},
              onCopyTap: () {},
              onDeposit: () {},
              onWithdraw: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify KPI Analytics Header and Selector chips
      expect(find.text('REPORT & KPI ANALYTICS'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);

      // Verify all required KPI metrics exist in the UI
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Deposited'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Withdrawn'), findsOneWidget);
      expect(find.text('Successful'), findsOneWidget);
      expect(find.text('Failed / Cancelled'), findsOneWidget);
      expect(find.text('Total Volume'), findsOneWidget);
      expect(find.text('Average Size'), findsOneWidget);
    });
  });
}
