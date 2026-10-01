import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/ui_components.dart';

class SendMoneyPage extends StatefulWidget {
  const SendMoneyPage({super.key});
  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage> {
  int step = 0;
  String amount = '0';
  final recipient = TextEditingController();
  @override
  void dispose() {
    recipient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: Text(['Send money', 'Enter amount', 'Review transfer'][step]),
      centerTitle: true,
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: step == 0
          ? people()
          : step == 1
          ? amountEntry()
          : review(),
    ),
  );
  Widget people() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Who are you sending to?',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: recipient,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Wallet ID, phone, or name',
        ),
      ),
      const SizedBox(height: 28),
      const Text(
        'RECENT RECEIVERS',
        style: TextStyle(
          letterSpacing: 1,
          fontSize: 11,
          color: AppColors.muted,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 18,
        children: ['Sophia', 'Mika', 'Aiden', 'Add']
            .map(
              (name) => InkWell(
                onTap: () => setState(() {
                  recipient.text = name == 'Add' ? '' : name;
                  if (name != 'Add') step = 1;
                }),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: name == 'Add'
                          ? AppColors.indigo.withValues(alpha: .14)
                          : AppColors.indigo,
                      child: name == 'Add'
                          ? const Icon(Icons.add, color: AppColors.indigo)
                          : Text(name.substring(0, 1)),
                    ),
                    const SizedBox(height: 6),
                    Text(name),
                  ],
                ),
              ),
            )
            .toList(),
      ),
      const Spacer(),
      FilledButton(
        onPressed: recipient.text.trim().isEmpty
            ? null
            : () => setState(() => step = 1),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(55),
          backgroundColor: AppColors.indigo,
        ),
        child: const Text('Continue'),
      ),
    ],
  );
  Widget amountEntry() => Column(
    children: [
      const SizedBox(height: 34),
      const Text(
        'Available balance  \$12,450.80',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 16),
      Text(
        '\$$amount',
        style: const TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
        ),
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        children: ['+10', '+50', '+100', 'MAX']
            .map(
              (v) => ActionChip(
                label: Text(v),
                onPressed: () => setState(
                  () => amount = v == 'MAX'
                      ? '12,450.80'
                      : (double.parse(amount) + double.parse(v.substring(1)))
                            .toStringAsFixed(0),
                ),
              ),
            )
            .toList(),
      ),
      const Spacer(),
      keypad(),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: double.tryParse(amount)! > 0
            ? () => setState(() => step = 2)
            : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(55),
          backgroundColor: AppColors.indigo,
        ),
        child: const Text('Review transfer'),
      ),
    ],
  );
  Widget keypad() => GridView.count(
    shrinkWrap: true,
    crossAxisCount: 3,
    childAspectRatio: 1.7,
    children: [...List.generate(9, (i) => '${i + 1}'), '.', '0', '⌫']
        .map(
          (key) => TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (key == '⌫') {
                  amount = amount.length > 1
                      ? amount.substring(0, amount.length - 1)
                      : '0';
                } else if (key != '.' || !amount.contains('.')) {
                  amount = amount == '0' ? key : '$amount$key';
                }
              });
            },
            child: Text(
              key,
              style: TextStyle(
                fontSize: key == '⌫' ? 21 : 25,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
        .toList(),
  );
  Widget review() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(
        child: Column(
          children: [
            const Text('You’re sending'),
            Text(
              '\$$amount',
              style: const TextStyle(
                fontSize: 43,
                fontWeight: FontWeight.w800,
                color: AppColors.indigo,
              ),
            ),
            Text(
              'to ${recipient.text.isEmpty ? 'Sophia Martinez' : recipient.text}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 36),
      line('Transfer amount', '\$$amount'),
      line('Fee', '\$0.00'),
      const Divider(height: 28),
      line('Total', '\$$amount', bold: true),
      const Spacer(),
      FilledButton(
        onPressed: complete,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(55),
          backgroundColor: AppColors.indigo,
        ),
        child: const Text('Confirm & enter PIN'),
      ),
    ],
  );
  Widget line(String left, String right, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(left, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
        const Spacer(),
        Text(
          right,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
  void complete() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: FintechCard(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen.withValues(alpha: .18),
              ),
              padding: const EdgeInsets.all(9),
              child: const CircleAvatar(
                backgroundColor: AppColors.accentGreen,
                child: Icon(
                  Icons.check_rounded,
                  size: 38,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Success',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '\$$amount sent successfully',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.accentGreen.withValues(alpha: .09),
              ),
              child: const Column(
                children: [
                  Text(
                    'REFERENCE NUMBER',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'NP-2026-9A4F01',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).popUntil((r) => r.isFirst),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ),
  );
}
