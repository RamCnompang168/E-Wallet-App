import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import 'package:e_wallet/features/transaction/presentation/screens/send_amount_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _torchOn = false;
  bool _scanning = false;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Stack(
      children: [
        Center(
          child: Container(
            width: 248,
            height: 248,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.yellow, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 12,
          child: IconButton(
            tooltip: 'Close scanner',
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        Positioned(
          top: 20,
          right: 12,
          child: IconButton(
            tooltip: _torchOn ? 'Turn flash off' : 'Turn flash on',
            onPressed: () => setState(() => _torchOn = !_torchOn),
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_outlined,
              color: _torchOn ? AppColors.yellow : Colors.white,
            ),
          ),
        ),
        Positioned(
          bottom: 34,
          left: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Align a NovaPay QR within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 220,
                child: YellowButton(
                  label: 'Upload from gallery',
                  icon: Icons.image_outlined,
                  isLoading: _scanning,
                  onPressed: _upload,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _upload() async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _scanning = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verified NovaPay QR: WAL-59433784 (Thida Meas)')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SendAmountScreen(
          receiver: 'Thida Meas',
          receiverWalletNumber: 'WAL-59433784',
        ),
      ),
    );
  }
}
