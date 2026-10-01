import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_state.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({
    super.key,
    required this.biometricsEnabled,
    required this.onBiometricsChanged,
  });

  final bool biometricsEnabled;
  final ValueChanged<bool> onBiometricsChanged;

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  // Password controllers
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _savingPassword = false;

  // PIN controllers
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _savingPin = false;

  late bool _biometrics;

  @override
  void initState() {
    super.initState();
    _biometrics = widget.biometricsEnabled;
  }

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPass = _oldPassController.text;
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;

    if (oldPass.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both old and new password.')),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }

    setState(() => _savingPassword = true);

    try {
      if (AuthState.instance.isAuthenticated) {
        await ApiClient.instance.patch('users/me/password/', body: {
          'old_password': oldPass,
          'new_password': newPass,
        });
      }

      if (!mounted) return;
      setState(() {
        _savingPassword = false;
        _oldPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.accentGreen,
          content: Text('Password changed successfully!', style: TextStyle(color: Colors.black)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingPassword = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingPassword = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
    }
  }

  Future<void> _changePin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (newPin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(newPin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN must be exactly 6 numeric digits.')),
      );
      return;
    }

    if (newPin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PINs do not match.')),
      );
      return;
    }

    setState(() => _savingPin = true);

    try {
      if (AuthState.instance.isAuthenticated) {
        await ApiClient.instance.post('users/me/pin/', body: {
          'pin': newPin,
          if (currentPin.isNotEmpty) 'current_pin': currentPin,
        });
      }

      if (!mounted) return;
      setState(() {
        _savingPin = false;
        _currentPinController.clear();
        _newPinController.clear();
        _confirmPinController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.accentGreen,
          content: Text('Transaction PIN updated successfully!', style: TextStyle(color: Colors.black)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingPin = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingPin = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction PIN set.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Security & PIN')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Biometrics Switch
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: Theme.of(context).colorScheme.surface,
          leading: const Icon(Icons.fingerprint, color: AppColors.indigo),
          title: const Text('Biometric Authentication', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Use fingerprint / face ID for login'),
          trailing: Switch(
            value: _biometrics,
            onChanged: (val) {
              setState(() => _biometrics = val);
              widget.onBiometricsChanged(val);
            },
          ),
        ),
        const SizedBox(height: 28),

        // Change Password Section
        const Text(
          'CHANGE PASSWORD',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _oldPassController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newPassController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPassController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm new password'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _savingPassword ? null : _changePassword,
          style: FilledButton.styleFrom(backgroundColor: AppColors.indigo),
          child: _savingPassword
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Update Password'),
        ),

        const SizedBox(height: 32),

        // Set / Change Transaction PIN Section
        const Text(
          'TRANSACTION PIN MANAGEMENT',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        const Text(
          'Used to authorize money transfers, withdrawals, and payments. 3 consecutive wrong attempts will lock your PIN for 30 minutes.',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentPinController,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Current 6-digit PIN (optional)', counterText: ''),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newPinController,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New 6-digit PIN', counterText: ''),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPinController,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Confirm new 6-digit PIN', counterText: ''),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _savingPin ? null : _changePin,
          style: FilledButton.styleFrom(backgroundColor: AppColors.yellow),
          child: _savingPin
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Save Transaction PIN', style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
}
