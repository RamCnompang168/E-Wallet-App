import 'package:flutter/material.dart';
import 'simulation_screen.dart';

class DepositSimulationScreen extends StatelessWidget {
  const DepositSimulationScreen({super.key});

  @override
  Widget build(BuildContext context) => const SimulationScreen(
    title: 'Deposit simulation',
    button: 'Simulate deposit',
    positive: true,
  );
}
