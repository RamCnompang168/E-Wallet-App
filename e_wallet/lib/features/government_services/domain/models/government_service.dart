import 'package:flutter/material.dart';

enum GovServiceCategory {
  all,
  tax,
  transport,
  utility,
  social,
}

class GovernmentServiceItem {
  final String id;
  final String title;
  final String titleKh;
  final String ministry;
  final String description;
  final IconData icon;
  final Color color;
  final GovServiceCategory category;
  final String referenceLabel;
  final String referenceHint;
  final double defaultAmount;
  final List<double> presetAmounts;

  const GovernmentServiceItem({
    required this.id,
    required this.title,
    required this.titleKh,
    required this.ministry,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.referenceLabel,
    required this.referenceHint,
    this.defaultAmount = 25.0,
    this.presetAmounts = const [10.0, 25.0, 50.0, 100.0],
  });
}

const List<GovernmentServiceItem> kGovernmentServices = [
  GovernmentServiceItem(
    id: 'ROAD_TAX',
    title: 'Road Tax',
    titleKh: 'ពន្ធលើមធ្យោបាយដឹកជញ្ជូន',
    ministry: 'General Dept. of Taxation (GDT)',
    description: 'Pay annual vehicle road tax sticker for cars and motorcycles.',
    icon: Icons.directions_car_filled_rounded,
    color: Color(0xFF1E88E5),
    category: GovServiceCategory.tax,
    referenceLabel: 'Vehicle Plate Number',
    referenceHint: 'e.g. 2A-8888 or 1AU-9999',
    defaultAmount: 25.0,
    presetAmounts: [15.0, 25.0, 40.0, 60.0],
  ),
  GovernmentServiceItem(
    id: 'VEHICLE_INSPECTION',
    title: 'Vehicle Inspection',
    titleKh: 'ត្រួតពិនិត្យលក្ខណៈបច្ចេកទេស (ឆែកឆេរ)',
    ministry: 'Ministry of Public Works & Transport',
    description: 'Pay official periodic vehicle roadworthiness inspection fees.',
    icon: Icons.car_repair_rounded,
    color: Color(0xFFFB8C00),
    category: GovServiceCategory.transport,
    referenceLabel: 'Chassis / Plate Number',
    referenceHint: 'e.g. 2B-5566 or Chassis ID',
    defaultAmount: 20.0,
    presetAmounts: [10.0, 20.0, 35.0, 50.0],
  ),
  GovernmentServiceItem(
    id: 'ELECTRICITY_EDC',
    title: 'EDC Electricity',
    titleKh: 'អគ្គិសនីកម្ពុជា (EDC)',
    ministry: 'Electricité du Cambodge',
    description: 'Pay monthly electricity power bills across Cambodia.',
    icon: Icons.bolt_rounded,
    color: Color(0xFFFBC02D),
    category: GovServiceCategory.utility,
    referenceLabel: 'EDC Consumer Number',
    referenceHint: 'e.g. 021-998877 (10 digits)',
    defaultAmount: 35.0,
    presetAmounts: [15.0, 30.0, 50.0, 100.0],
  ),
  GovernmentServiceItem(
    id: 'WATER_PPWSA',
    title: 'PPWSA Water Supply',
    titleKh: 'រដ្ឋាករទឹកស្វយ័តក្រុងភ្នំពេញ',
    ministry: 'Phnom Penh Water Supply Authority',
    description: 'Settle residential and commercial clean water utility bills.',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF00ACC1),
    category: GovServiceCategory.utility,
    referenceLabel: 'Water Customer Account No.',
    referenceHint: 'e.g. W-0987654',
    defaultAmount: 15.0,
    presetAmounts: [8.0, 15.0, 25.0, 40.0],
  ),
  GovernmentServiceItem(
    id: 'NSSF_CONTRIBUTION',
    title: 'NSSF Contribution',
    titleKh: 'បេឡាជាតិរបបសន្តិសុខសង្គម (ប.ស.ស)',
    ministry: 'National Social Security Fund',
    description: 'Pay voluntary healthcare and pension security contributions.',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFF43A047),
    category: GovServiceCategory.social,
    referenceLabel: 'NSSF Member ID Card',
    referenceHint: 'e.g. NSSF-10928374',
    defaultAmount: 22.0,
    presetAmounts: [15.0, 22.0, 35.0, 50.0],
  ),
  GovernmentServiceItem(
    id: 'PROPERTY_TAX',
    title: 'Property / Land Tax',
    titleKh: 'ពន្ធលើអចលនទ្រព្យ និងដីធ្លី',
    ministry: 'General Dept. of Taxation (GDT)',
    description: 'Pay annual immovable property tax and land ownership dues.',
    icon: Icons.apartment_rounded,
    color: Color(0xFF8E24AA),
    category: GovServiceCategory.tax,
    referenceLabel: 'Property Tax Identification (PTIN)',
    referenceHint: 'e.g. PT-2026-99001',
    defaultAmount: 50.0,
    presetAmounts: [25.0, 50.0, 100.0, 200.0],
  ),
  GovernmentServiceItem(
    id: 'BUSINESS_REG_MOC',
    title: 'Business Registration',
    titleKh: 'ចុះបញ្ជីពាណិជ្ជកម្ម និងសេវាសាធារណៈ',
    ministry: 'Ministry of Commerce (MoC)',
    description: 'Settle business filing, company annual declarations, and trademark fees.',
    icon: Icons.business_center_rounded,
    color: Color(0xFF3949AB),
    category: GovServiceCategory.tax,
    referenceLabel: 'Filing Application Reference',
    referenceHint: 'e.g. MOC-APP-2026-789',
    defaultAmount: 30.0,
    presetAmounts: [20.0, 30.0, 60.0, 120.0],
  ),
];
