import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/qr_visual.dart';

class ReceiveQrScreen extends StatefulWidget {
  const ReceiveQrScreen({super.key});

  @override
  State<ReceiveQrScreen> createState() => _ReceiveQrScreenState();
}

class _ReceiveQrScreenState extends State<ReceiveQrScreen> {
  final _amount = TextEditingController();
  String? _requestedAmount;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Receive money'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'My QR (KHQR)'),
            Tab(text: 'Request amount'),
          ],
        ),
      ),
      body: TabBarView(children: [_qrPanel(), _requestPanel()]),
    ),
  );

  Widget _requestPanel() => ListView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    children: [
      const Text(
        'Request a specific amount',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      const Text(
        'Generates an official KHQR dynamic QR scannable by ABA, ACLEDA, Bakong, and other banks.',
        style: TextStyle(color: AppColors.muted, fontSize: 13),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: _amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          prefixText: '\$ ',
          hintText: '0.00',
          labelText: 'Amount (USD)',
        ),
        onChanged: (_) {
          // If amount changes, update dynamically if requested
        },
      ),
      const SizedBox(height: 16),
      YellowButton(
        label: 'Generate request QR',
        icon: Icons.qr_code_2_rounded,
        onPressed: () {
          final amt = _amount.text.trim();
          final val = double.tryParse(amt);
          if (val == null || val <= 0) {
            _notice('Please enter a valid amount greater than \$0.00');
            return;
          }
          setState(() {
            _requestedAmount = amt;
          });
          _notice('KHQR bill for \$$amt generated successfully.');
        },
      ),
      const SizedBox(height: 20),
      QrVisual(
        amount: _requestedAmount,
      ),
      const SizedBox(height: 20),
      if (_requestedAmount != null)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Save QR'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
      const SizedBox(height: 24),
    ],
  );

  Widget _qrPanel() => ListView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    children: [
      const QrVisual(),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Save QR'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
    ],
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() => _saving = false);
    _notice('KHQR image saved to your device gallery.');
  }

  void _share() => _notice('KHQR payment link copied & ready to share.');

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(_saving ? 'Saving KHQR…' : message)));
}
