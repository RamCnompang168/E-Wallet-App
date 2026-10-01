import 'package:e_wallet/core/services/account_approval_service.dart';
import 'package:e_wallet/core/services/auth_state.dart';
import 'package:e_wallet/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel and PendingApprovalUser tests', () {
    test('avatarUrl formats relative media URLs with host', () {
      const user = UserModel(
        id: '1',
        email: 'test@example.com',
        phoneNumber: '+85512345678',
        fullName: 'Sokha Chan',
        role: 'CUSTOMER',
        status: 'ACTIVE',
        kycTier: 1,
        profilePhoto: '/media/avatars/2026/09/avatar.jpg',
      );

      expect(user.avatarUrl, isNotNull);
      expect(user.avatarUrl, contains('/media/avatars/2026/09/avatar.jpg'));
      expect(user.initials, 'SC');
    });

    test('PendingApprovalUser parsed correctly with document display', () {
      final pendingUser = PendingApprovalUser.fromJson({
        'id': 'abc-123',
        'full_name': 'Kosal Vong',
        'email': 'kosal@example.com',
        'phone_number': '+85512999888',
        'id_document_type': 'NATIONAL_ID',
        'id_document_number': '012345678',
        'id_document_photo': 'http://127.0.0.1:8000/media/docs/doc_1.jpg',
        'profile_photo': 'http://127.0.0.1:8000/media/avatars/avatar_1.jpg',
        'gender': 'MALE',
        'date_of_birth': '1998-05-15',
        'status': 'PENDING_APPROVAL',
      });

      expect(pendingUser.id, 'abc-123');
      expect(pendingUser.fullName, 'Kosal Vong');
      expect(pendingUser.documentDisplay, 'National ID');
      expect(pendingUser.idDocumentNumber, '012345678');
      expect(pendingUser.initials, 'KV');
      expect(pendingUser.resolvedDocumentPhotoUrl, isNotNull);
    });

    test('PendingApprovalUser handles passport document type', () {
      final pendingPassportUser = PendingApprovalUser.fromJson({
        'id': 'pass-456',
        'full_name': 'Mary Srun',
        'email': 'mary@example.com',
        'phone_number': '+85598765432',
        'id_document_type': 'PASSPORT',
        'id_document_number': 'N8765432',
      });

      expect(pendingPassportUser.documentDisplay, 'Passport');
      expect(pendingPassportUser.idDocumentNumber, 'N8765432');
      expect(pendingPassportUser.initials, 'MS');
    });
  });

  group('Three-Step RegisterScreen Widget Tests', () {
    testWidgets('renders Step 1 with account fields and 3-step header', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(onThemeChanged: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Step 1: Account Information'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('ID Document'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      expect(find.widgetWithText(TextField, 'Full name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Cambodian Phone Number'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email address'), findsOneWidget);
      expect(find.textContaining('Password'), findsOneWidget);
      expect(find.widgetWithText(TextField, '6-digit Transaction PIN'), findsOneWidget);

      expect(find.text('Continue to Step 2'), findsOneWidget);
    });

    testWidgets('validation prevents advancing to Step 2 when fields are empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(onThemeChanged: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue to Step 2'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name.'), findsOneWidget);
      expect(find.text('Step 1: Account Information'), findsOneWidget);
    });

    testWidgets('advances to Step 2 ID verification and tests toggle and back navigation', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(onThemeChanged: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Fill Step 1 fields
      final nameField = find.widgetWithText(TextField, 'Full name');
      final phoneField = find.widgetWithText(TextField, 'Cambodian Phone Number');
      final emailField = find.widgetWithText(TextField, 'Email address');
      final passwordField = find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.labelText?.contains('Password') ?? false),
      );
      final pinField = find.widgetWithText(TextField, '6-digit Transaction PIN');

      await tester.enterText(nameField, 'Sokha Chan');
      await tester.enterText(phoneField, '012 345 678');
      await tester.enterText(emailField, 'sokha@example.com');
      await tester.enterText(passwordField, 'SecurePassword123');
      await tester.enterText(pinField, '123456');

      await tester.tap(find.text('Continue to Step 2'));
      await tester.pumpAndSettle();

      // Verify Step 2 UI is displayed
      expect(find.text('Step 2: Identity Verification'), findsOneWidget);
      expect(find.text('National ID'), findsWidgets);
      expect(find.text('Passport'), findsWidgets);
      expect(find.text('National ID Number'), findsOneWidget);
      expect(find.text('Upload Photo of National ID'), findsOneWidget);
      expect(find.text('Continue to Step 3'), findsOneWidget);
      expect(find.text('Back to Step 1'), findsOneWidget);

      // Switch to Passport
      await tester.tap(find.text('Passport').first);
      await tester.pumpAndSettle();

      // Verify label changes to Passport Number
      expect(find.text('Passport Number'), findsOneWidget);
      expect(find.text('Upload Photo of Passport'), findsOneWidget);

      // Test Step 2 validation when document number is empty
      await tester.tap(find.text('Continue to Step 3'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your Passport number.'), findsOneWidget);

      // Back to Step 1
      await tester.tap(find.text('Back to Step 1'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1: Account Information'), findsOneWidget);
      expect(find.text('sokha@example.com'), findsOneWidget);
    });
  });
}
