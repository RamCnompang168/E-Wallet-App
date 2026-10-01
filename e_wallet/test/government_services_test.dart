import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_wallet/features/government_services/domain/models/government_service.dart';
import 'package:e_wallet/features/government_services/presentation/screens/government_services_screen.dart';

void main() {
  group('Government Services Feature Tests', () {
    test('kGovernmentServices contains key Cambodian public services', () {
      expect(kGovernmentServices.isNotEmpty, isTrue);
      
      final roadTax = kGovernmentServices.firstWhere((s) => s.id == 'ROAD_TAX');
      expect(roadTax.title, 'Road Tax');
      expect(roadTax.titleKh, contains('ពន្ធលើមធ្យោបាយដឹកជញ្ជូន'));
      expect(roadTax.referenceLabel, contains('Plate Number'));

      final edc = kGovernmentServices.firstWhere((s) => s.id == 'ELECTRICITY_EDC');
      expect(edc.title, 'EDC Electricity');
      expect(edc.titleKh, contains('អគ្គិសនីកម្ពុជា'));

      final nssf = kGovernmentServices.firstWhere((s) => s.id == 'NSSF_CONTRIBUTION');
      expect(nssf.title, 'NSSF Contribution');
      expect(nssf.titleKh, contains('បេឡាជាតិរបបសន្តិសុខសង្គម'));

      final ppwsa = kGovernmentServices.firstWhere((s) => s.id == 'WATER_PPWSA');
      expect(ppwsa.title, 'PPWSA Water Supply');
    });

    testWidgets('renders GovernmentServicesScreen with search, categories, and service cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GovernmentServicesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Government Services'), findsOneWidget);
      expect(find.text('Public Services & Taxes'), findsOneWidget);
      expect(find.text('Road Tax'), findsOneWidget);
      expect(find.text('EDC Electricity'), findsOneWidget);
      expect(find.text('NSSF Contribution'), findsOneWidget);

      // Filter by Utilities
      await tester.tap(find.text('Utilities (EDC/Water)'));
      await tester.pumpAndSettle();

      expect(find.text('EDC Electricity'), findsOneWidget);
      expect(find.text('PPWSA Water Supply'), findsOneWidget);
      expect(find.text('Road Tax'), findsNothing);

      // Search functionality
      await tester.enterText(find.byType(TextField).first, 'NSSF');
      await tester.pumpAndSettle();

      // Clear filter to All to test search alone
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('NSSF Contribution'), findsOneWidget);
      expect(find.text('EDC Electricity'), findsNothing);
    });

    testWidgets('tapping on a service opens payment sheet with bill inquiry fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GovernmentServicesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Road Tax
      await tester.tap(find.text('Road Tax'));
      await tester.pumpAndSettle();

      // Payment Sheet should appear
      expect(find.text('Vehicle Plate Number'), findsOneWidget);
      expect(find.text('Payment Amount (USD)'), findsOneWidget);
      expect(find.text('Transaction PIN'), findsOneWidget);
      expect(find.text('Confirm & Pay Bill'), findsOneWidget);
    });
  });
}
