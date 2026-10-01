import 'package:flutter/material.dart';
import 'simulation_screen.dart';

class WithdrawSimulationScreen extends StatelessWidget {
  const WithdrawSimulationScreen({super.key});

  @override
  Widget build(BuildContext context) => const SimulationScreen(
    title: 'Withdraw simulation',
    button: 'Confirm withdrawal',
    positive: false,
  );
}
