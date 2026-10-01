import 'package:e_wallet/features/beneficiaries/data/beneficiary_api_service.dart';
import 'package:e_wallet/features/transaction/domain/models/transaction.dart';
import 'package:e_wallet/features/transaction/presentation/screens/transaction_detail_screen.dart';
import 'package:e_wallet/features/transaction/presentation/screens/transaction_history_screen.dart';
import 'package:e_wallet/features/wallet/presentation/screens/wallet_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BeneficiaryApiService tests', () {
    test('add, edit, and remove beneficiary in memory', () async {
      final service = BeneficiaryApiService.instance;
      service.reset();
      expect(service.beneficiaries.length, 2);

      // Add
      final added = await service.addBeneficiary(
        walletNumber: 'WAL-99887766',
        nickname: 'Brother',
        isFavorite: true,
      );
      expect(added, isNotNull);
      expect(service.beneficiaries.any((b) => b.walletNumber == 'WAL-99887766'), isTrue);

      // Edit
      final editOk = await service.editBeneficiary(
        id: added!.id,
        nickname: 'My Big Brother',
        isFavorite: false,
      );
      expect(editOk, isTrue);
      final updated = service.beneficiaries.firstWhere((b) => b.id == added.id);
      expect(updated.nickname, 'My Big Brother');
      expect(updated.isFavorite, isFalse);

      // Remove
      final removeOk = await service.removeBeneficiary(added.id);
      expect(removeOk, isTrue);
      expect(service.beneficiaries.any((b) => b.id == added.id), isFalse);
    });
  });

  group('WalletTab Summary & Reports Widget Tests', () {
    testWidgets('renders Wallet Summary cards and KPI reports', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      // Verify wallet details and summary
      expect(find.text('My wallet'), findsOneWidget);
      expect(find.text('WALLET ACCOUNT DETAILS'), findsOneWidget);
      expect(find.text('Current Balance'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);

      // Verify 4-metric wallet summary
      expect(find.text('WALLET SUMMARY'), findsOneWidget);
      expect(find.text('Total Sent'), findsOneWidget);
      expect(find.text('Total Received'), findsOneWidget);
      expect(find.text('Total Deposit'), findsOneWidget);
      expect(find.text('Total Withdraw'), findsOneWidget);

      // Verify Report & KPI Analytics
      expect(find.text('REPORT & KPI ANALYTICS'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);

      // Tap on Monthly filter
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly Performance'), findsOneWidget);

      // Verify actions
      expect(find.text('WALLET ACTIONS'), findsOneWidget);
      expect(find.text('Add money (Deposit)'), findsOneWidget);
      expect(find.text('Withdraw money'), findsOneWidget);
    });
  });

  group('TransactionHistoryScreen & TransactionDetailScreen Tests', () {
    testWidgets('filters by status and opens receipt from detail screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionHistoryScreen(
              onTransactionTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title, search, type chips, and status chips
      expect(find.text('Transaction History'), findsOneWidget);
      expect(find.text('All Status'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Tap a status chip
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      // Test TransactionDetailScreen
      const testTxn = TransactionModel(
        id: 'TXN-999',
        name: 'Transfer to Sokha',
        amount: -25.0,
        date: 'Today, 2:30 PM',
        category: TransactionCategory.sent,
        status: 'Completed',
        transactionCode: 'TXN-2026-999',
        senderWalletNumber: 'WAL-111',
        receiverWalletNumber: 'WAL-222',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionDetailScreen(transaction: testTxn),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transaction details'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('-\$25.00'), findsOneWidget);
      expect(find.text('View Official Receipt'), findsOneWidget);

      // Tap View Official Receipt
      await tester.tap(find.text('View Official Receipt'));
      await tester.pumpAndSettle();

      expect(find.text('Transaction Receipt'), findsOneWidget);
      expect(find.text('Payment Successful'), findsOneWidget);
    });
  });
}
