import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/app_theme.dart';
import '../data/wallet_repository.dart';
import '../domain/models/wallet_activity.dart';
import '../../transaction/presentation/send_money_page.dart';
import '../../transaction/presentation/transaction_screens.dart';

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;
  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  bool shown = true;
  bool _biometricEnabled = true;
  int tab = 0;
  final repo = WalletRepository();
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: [_home(dark), _activity(), _profile()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: dark ? const Color(0xFF101725) : Colors.white,
        selectedIndex: tab,
        onDestinationSelected: (x) => setState(() => tab = x),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _home(bool dark) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
    children: [
      Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.indigo,
            child: Text('JD', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good morning', style: TextStyle(color: AppColors.muted)),
                Text(
                  'Jordan Davis',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationListScreen()),
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _card(),
      const SizedBox(height: 26),
      const Text(
        'Quick actions',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          _action(
            Icons.arrow_upward_rounded,
            'Send',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SendMoneyPage()),
            ),
          ),
          _action(Icons.qr_code_2_rounded, 'Receive', () => _qr()),
          _action(
            Icons.add_card_rounded,
            'Add money',
            () => _notice('Funds added successfully'),
          ),
          _action(
            Icons.document_scanner_outlined,
            'Scan',
            () => _notice('Camera scanner is ready'),
          ),
        ],
      ),
      const SizedBox(height: 28),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Cash flow',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'October',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _chart(),
      const SizedBox(height: 25),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          TextButton(
            onPressed: () => setState(() => tab = 1),
            child: const Text('See all'),
          ),
        ],
      ),
      ...repo.recent().take(3).map(_tile),
    ],
  );
  Widget _card() => Container(
    height: 205,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xFF635BFF), Color(0xFF9C61E7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x556C63FF),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Total balance',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => shown = !shown),
              icon: Icon(
                shown
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          shown ? '\$12,450.80' : '••••••••',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            const Text(
              '••••  4892',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'NP-7390-4892'));
                _notice('Wallet ID copied');
              },
              child: const Icon(
                Icons.copy_rounded,
                size: 20,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _action(IconData icon, String name, VoidCallback action) => Expanded(
    child: InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        action();
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: AppColors.indigo, size: 24),
          ),
          const SizedBox(height: 7),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
  Widget _chart() => Container(
    height: 170,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: CustomPaint(
      painter: _ChartPainter(Theme.of(context).brightness == Brightness.dark),
      child: const SizedBox.expand(),
    ),
  );
  Widget _tile(WalletActivity a) {
    final icon = switch (a.kind) {
      ActivityKind.income => Icons.arrow_downward_rounded,
      ActivityKind.deposit => Icons.add_card_rounded,
      ActivityKind.payment => Icons.play_circle_outline_rounded,
      _ => Icons.arrow_upward_rounded,
    };
    final color = a.isCredit ? AppColors.emerald : const Color(0xFFFF7A90);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(a.time, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        '${a.isCredit ? '+' : '-'}\$${a.amount.abs().toStringAsFixed(2)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _activity() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Activity',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 16),
      const TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Search transactions',
        ),
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Send', 'Receive', 'Deposit', 'Withdraw']
              .map(
                (x) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(x),
                    selected: x == 'All',
                    onSelected: (_) {},
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'TODAY',
        style: TextStyle(
          letterSpacing: 1.1,
          fontSize: 11,
          color: AppColors.muted,
          fontWeight: FontWeight.bold,
        ),
      ),
      ...repo.recent().map(_tile),
    ],
  );
  Widget _profile() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Profile',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 26),
      const Center(
        child: CircleAvatar(
          radius: 42,
          backgroundColor: AppColors.indigo,
          child: Text(
            'JD',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Jordan Davis',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      const Center(
        child: Text(
          'jordan@novapay.app',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
      const SizedBox(height: 28),
      _setting(
        Icons.fingerprint_rounded,
        'Biometric login',
        trailing: Switch(
          value: _biometricEnabled,
          onChanged: (value) => setState(() => _biometricEnabled = value),
        ),
      ),
      _setting(
        Icons.dark_mode_outlined,
        'Appearance',
        sub: 'Dark mode',
        action: widget.onToggleTheme,
      ),
      _setting(
        Icons.lock_outline_rounded,
        'Change transaction PIN',
        action: () => _notice('PIN change flow started.'),
      ),
      _setting(
        Icons.shield_outlined,
        'Privacy & security',
        action: () => _notice('Privacy controls opened.'),
      ),
      _setting(
        Icons.logout_rounded,
        'Log out',
        action: () => Navigator.of(context).popUntil((route) => route.isFirst),
        bad: true,
      ),
    ],
  );
  Widget _setting(
    IconData icon,
    String name, {
    String? sub,
    Widget? trailing,
    VoidCallback? action,
    bool bad = false,
  }) => ListTile(
    onTap: action,
    contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (bad ? Colors.red : AppColors.indigo).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: bad ? Colors.red : AppColors.indigo),
    ),
    title: Text(
      name,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: bad ? Colors.red : null,
      ),
    ),
    subtitle: sub == null ? null : Text(sub),
    trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
  );
  void _qr() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your NovaPay QR',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 22),
          Container(
            width: 185,
            height: 185,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 148,
              color: Color(0xFF101010),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'NP-7390-4892',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
  void _notice(String x) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(x), behavior: SnackBarBehavior.floating),
  );
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter(this.dark);
  final bool dark;
  @override
  void paint(Canvas c, Size s) {
    final g = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: .06);
    for (var y = 25.0; y < s.height; y += 35) {
      c.drawLine(Offset(0, y), Offset(s.width, y), g);
    }
    final vals = [.74, .64, .71, .45, .55, .25, .33];
    final p = Path();
    for (var i = 0; i < vals.length; i++) {
      final x = i * s.width / (vals.length - 1);
      final y = vals[i] * (s.height - 25);
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    final f = Path.from(p)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(
      f,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x556C63FF), Color(0x006C63FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & s),
    );
    c.drawPath(
      p,
      Paint()
        ..color = AppColors.indigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.dark != dark;
}
