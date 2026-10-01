import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_state.dart';
import '../../../shell/presentation/screens/main_navigation_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onThemeChanged});
  final VoidCallback onThemeChanged;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 1;

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController(text: '123456');
  bool _obscurePassword = true;

  // Step 2 Controllers & State (ID Document)
  String _idDocumentType = 'NATIONAL_ID';
  final _idDocNumberController = TextEditingController();
  XFile? _pickedIdDocImage;
  Uint8List? _pickedIdDocBytes;

  // Step 3 Controllers & State (Profile Details)
  final _step3NameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _gender;
  XFile? _pickedProfileImage;
  Uint8List? _pickedProfileImageBytes;

  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _idDocNumberController.dispose();
    _step3NameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    var phone = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('0')) {
      phone = '+855${phone.substring(1)}';
    } else if (phone.startsWith('855')) {
      phone = '+$phone';
    }
    return phone;
  }

  void _goToStep2() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final pin = _pinController.text.trim();

    if (name.isEmpty) {
      _showSnack('Please enter your full name.');
      return;
    }

    if (phone.isEmpty) {
      _showSnack('Please enter your phone number.');
      return;
    }

    final normalizedPhone = _normalizePhone(phone);
    if (!RegExp(r'^\+855\d{8,9}$').hasMatch(normalizedPhone) &&
        !RegExp(r'^\+[1-9]\d{7,19}$').hasMatch(normalizedPhone)) {
      _showSnack('Please enter a valid Cambodian phone number (e.g. 012 345 678 or +855 12 345 678).');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Please enter a valid email address.');
      return;
    }

    if (password.length < 8) {
      _showSnack('Password must be at least 8 characters.');
      return;
    }

    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      _showSnack('Transaction PIN must be exactly 6 numeric digits.');
      return;
    }

    // Carry over full name from Step 1 to Step 3
    if (_step3NameController.text.isEmpty) {
      _step3NameController.text = name;
    }

    setState(() {
      _currentStep = 2;
    });
  }

  void _goToStep3() {
    final docNumber = _idDocNumberController.text.trim();
    if (docNumber.isEmpty) {
      _showSnack('Please enter your ${_idDocumentType == "PASSPORT" ? "Passport" : "National ID"} number.');
      return;
    }

    if (docNumber.length < 4) {
      _showSnack('Document number is too short. Please check again.');
      return;
    }

    if (_pickedIdDocBytes == null) {
      _showSnack('Please upload a photo of your ${_idDocumentType == "PASSPORT" ? "Passport" : "National ID"}.');
      return;
    }

    setState(() {
      _currentStep = 3;
    });
  }

  Future<void> _pickIdDocImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedIdDocImage = image;
          _pickedIdDocBytes = bytes;
        });
      }
    } catch (e) {
      _showSnack('Could not select document image: $e');
    }
  }

  void _showIdDocImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload ${_idDocumentType == "PASSPORT" ? "Passport" : "National ID"} Photo',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.indigo),
                title: const Text('Choose from Gallery / Photos'),
                subtitle: const Text('Pick from emulator or device photo library'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickIdDocImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accentGreen),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickIdDocImage(ImageSource.camera);
                },
              ),
              if (_pickedIdDocImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedIdDocImage = null;
                      _pickedIdDocBytes = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedProfileImage = image;
          _pickedProfileImageBytes = bytes;
        });
      }
    } catch (e) {
      _showSnack('Could not select profile photo: $e');
    }
  }

  void _showProfileImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.indigo),
                title: const Text('Choose from Gallery / Photos'),
                subtitle: const Text('Pick from emulator or device photo library'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accentGreen),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              if (_pickedProfileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedProfileImage = null;
                      _pickedProfileImageBytes = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'SELECT DATE OF BIRTH',
    );

    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _dobController.text = '$y-$m-$d';
      });
    }
  }

  Future<void> _handleCompleteRegistration() async {
    final finalName = _step3NameController.text.trim().isNotEmpty
        ? _step3NameController.text.trim()
        : _nameController.text.trim();
    final phone = _normalizePhone(_phoneController.text.trim());
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final pin = _pinController.text.trim();
    final dob = _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null;

    String? idDocBase64;
    if (_pickedIdDocBytes != null) {
      idDocBase64 = base64Encode(_pickedIdDocBytes!);
    }

    String? profilePhotoBase64;
    if (_pickedProfileImageBytes != null) {
      profilePhotoBase64 = base64Encode(_pickedProfileImageBytes!);
    }

    setState(() => _loading = true);

    final success = await AuthState.instance.register(
      fullName: finalName,
      phoneNumber: phone,
      email: email,
      password: password,
      pin: pin,
      gender: _gender,
      dateOfBirth: dob,
      idDocumentType: _idDocumentType,
      idDocumentNumber: _idDocNumberController.text.trim(),
      idDocumentPhotoBase64: idDocBase64,
      profilePhotoBase64: profilePhotoBase64,
    );

    if (!mounted) return;

    if (success) {
      // Also upload profile photo via standard multipart endpoint if available
      if (_pickedProfileImage != null && !AuthState.instance.isPendingApproval) {
        await AuthState.instance.uploadProfilePhoto(
          filePath: _pickedProfileImage!.path,
          fileBytes: _pickedProfileImageBytes,
          fileName: _pickedProfileImage!.name,
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);

      if (AuthState.instance.isPendingApproval) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.pending_actions_rounded, color: AppColors.primary, size: 48),
            title: const Text('Registration Submitted', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
              'Thank you, $finalName!\n\nYour account and ${_idDocumentType == "PASSPORT" ? "Passport" : "National ID"} details have been submitted and are currently pending administrator approval.\n\nOnce approved, you will be able to log in to NovaPay.',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Back to Sign in'),
              ),
            ],
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.accentGreen,
          content: Text(
            'Welcome to NovaPay, $finalName! Registration complete.',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavigationShell(onThemeChanged: widget.onThemeChanged),
        ),
      );
    } else {
      setState(() => _loading = false);
      final msg = AuthState.instance.errorMessage ?? 'Registration failed.';
      _showSnack(msg);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'NP';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_currentStep == 3) {
            setState(() => _currentStep = 2);
          } else if (_currentStep == 2) {
            setState(() => _currentStep = 1);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentStep == 1
                ? 'Create Account'
                : (_currentStep == 2 ? 'Identity Verification' : 'Profile Details'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_currentStep == 3) {
                setState(() => _currentStep = 2);
              } else if (_currentStep == 2) {
                setState(() => _currentStep = 1);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Column(
          children: [
            _buildStepperHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  if (_currentStep == 1)
                    _buildStepOne()
                  else if (_currentStep == 2)
                    _buildStepTwo()
                  else
                    _buildStepThree(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: .5),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: .08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStepIndicator(
            stepNumber: 1,
            title: 'Account',
            isActive: _currentStep == 1,
            isCompleted: _currentStep > 1,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep > 1 ? AppColors.accentGreen : Colors.white.withValues(alpha: .2),
            ),
          ),
          _buildStepIndicator(
            stepNumber: 2,
            title: 'ID Document',
            isActive: _currentStep == 2,
            isCompleted: _currentStep > 2,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep > 2 ? AppColors.accentGreen : Colors.white.withValues(alpha: .2),
            ),
          ),
          _buildStepIndicator(
            stepNumber: 3,
            title: 'Profile',
            isActive: _currentStep == 3,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color bg;
    Widget iconOrText;

    if (isCompleted) {
      bg = AppColors.accentGreen;
      iconOrText = const Icon(Icons.check, size: 14, color: AppColors.primaryDark);
    } else if (isActive) {
      bg = AppColors.indigo;
      iconOrText = Text('$stepNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white));
    } else {
      bg = Colors.white.withValues(alpha: .12);
      iconOrText = Text('$stepNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.muted));
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: bg,
          child: iconOrText,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isActive || isCompleted ? null : AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Account Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your basic credentials to set up your wallet account.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full name',
            hintText: 'e.g. Sokha Chan',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Cambodian Phone Number',
            hintText: '012 345 678 or +855',
            prefixIcon: Icon(Icons.phone_android_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password (min. 8 characters)',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: '6-digit Transaction PIN',
            counterText: '',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Highlights',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.muted),
              ),
              SizedBox(height: 6),
              Text(
                '• 8+ characters password security\n'
                '• 6-digit transaction PIN for payments and transfers\n'
                '• Automatic USD multi-currency wallet creation',
                style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _goToStep2,
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: const Text('Continue to Step 2'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: AppColors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    final isPassport = _idDocumentType == 'PASSPORT';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Identity Verification',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Provide your National ID or Passport details and upload a photo for administrative verification.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Document Type Selection Chips
        const Text(
          'Select Document Type',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _idDocumentType = 'NATIONAL_ID'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _idDocumentType == 'NATIONAL_ID'
                        ? AppColors.indigo.withValues(alpha: .2)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _idDocumentType == 'NATIONAL_ID'
                          ? AppColors.indigo
                          : Colors.white.withValues(alpha: .1),
                      width: _idDocumentType == 'NATIONAL_ID' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: _idDocumentType == 'NATIONAL_ID'
                            ? AppColors.accentGreen
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'National ID',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _idDocumentType == 'NATIONAL_ID'
                              ? Colors.white
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _idDocumentType = 'PASSPORT'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _idDocumentType == 'PASSPORT'
                        ? AppColors.indigo.withValues(alpha: .2)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _idDocumentType == 'PASSPORT'
                          ? AppColors.indigo
                          : Colors.white.withValues(alpha: .1),
                      width: _idDocumentType == 'PASSPORT' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: _idDocumentType == 'PASSPORT'
                            ? AppColors.accentGreen
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Passport',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _idDocumentType == 'PASSPORT'
                              ? Colors.white
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Document Number Field
        TextField(
          controller: _idDocNumberController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: isPassport ? 'Passport Number' : 'National ID Number',
            hintText: isPassport ? 'e.g. N0123456' : 'e.g. 012345678',
            prefixIcon: const Icon(Icons.credit_card_rounded),
            helperText: 'Enter your valid government-issued ID number',
          ),
        ),

        const SizedBox(height: 22),

        // Document Photo Upload Box
        Text(
          '${isPassport ? "Passport" : "National ID"} Photo',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),

        if (_pickedIdDocBytes != null)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentGreen.withValues(alpha: .4)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.memory(
                    _pickedIdDocBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.accentGreen, size: 18),
                          SizedBox(width: 6),
                          Text('Photo Selected', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _showIdDocImageSourceDialog,
                            child: const Text('Change'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => setState(() {
                              _pickedIdDocImage = null;
                              _pickedIdDocBytes = null;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _showIdDocImageSourceDialog,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .15),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.indigo.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      size: 32,
                      color: AppColors.indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload Photo of ${isPassport ? "Passport" : "National ID"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose from device / emulator photos or camera',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _showIdDocImageSourceDialog,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                    label: const Text('Select Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.accentGreen),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your document data is encrypted and reviewed by administrators to approve your wallet account.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: _goToStep3,
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: const Text('Continue to Step 3'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: AppColors.indigo,
          ),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () => setState(() => _currentStep = 1),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to Step 1'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _buildStepThree() {
    final displayName = _step3NameController.text.trim().isNotEmpty
        ? _step3NameController.text.trim()
        : _nameController.text.trim();
    final initials = _getInitials(displayName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Personal Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload your profile photo and provide personal details.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Profile Picture Avatar Picker
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _showProfileImageSourceDialog,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentGreen,
                        border: Border.all(color: Colors.white.withValues(alpha: .2), width: 3),
                        image: _pickedProfileImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_pickedProfileImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _pickedProfileImageBytes == null
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDark,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.indigo,
                        child: Icon(
                          _pickedProfileImageBytes != null ? Icons.edit : Icons.camera_alt,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _showProfileImageSourceDialog,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(
                  _pickedProfileImageBytes != null ? 'Change Photo' : 'Upload Profile Photo',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Text(
                'Choose photo from emulator / device gallery',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        // Full Name carried over from Step 1
        TextField(
          controller: _step3NameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            helperText: 'Carried over from Step 1 (you can edit if needed)',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),

        const SizedBox(height: 14),

        // Gender Dropdown
        DropdownButtonFormField<String?>(
          initialValue: _gender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.wc_outlined),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('Not specified')),
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          onChanged: (val) => setState(() => _gender = val),
        ),

        const SizedBox(height: 14),

        // Date of Birth Field with DatePicker
        TextField(
          controller: _dobController,
          readOnly: true,
          onTap: _pickDateOfBirth,
          decoration: InputDecoration(
            labelText: 'Date of Birth (YYYY-MM-DD)',
            hintText: 'Tap to select birthday',
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            suffixIcon: _dobController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _dobController.clear()),
                  )
                : const Icon(Icons.arrow_drop_down),
          ),
        ),

        const SizedBox(height: 28),

        // Submit & Back Buttons
        FilledButton(
          onPressed: _loading ? null : _handleCompleteRegistration,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: AppColors.indigo,
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Complete Registration', style: TextStyle(fontSize: 16)),
                  ],
                ),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: _loading ? null : () => setState(() => _currentStep = 2),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to Step 2'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}
