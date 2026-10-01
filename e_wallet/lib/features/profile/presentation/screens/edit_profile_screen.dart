import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  String? _gender;
  bool _saving = false;
  bool _uploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = AuthState.instance.currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _dobController = TextEditingController(text: user?.dateOfBirth ?? '');
    _gender = user?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _uploadingPhoto = true);
      final bytes = await image.readAsBytes();
      final success = await AuthState.instance.uploadProfilePhoto(
        filePath: image.path,
        fileBytes: bytes,
        fileName: image.name,
      );

      if (!mounted) return;
      setState(() => _uploadingPhoto = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.accentGreen,
            content: Text('Profile photo updated successfully!', style: TextStyle(color: Colors.black)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text('Failed to upload profile photo.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Error picking photo: $e')),
      );
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    DateTime initial = DateTime(2000, 1, 1);
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobController.text.trim());
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name cannot be blank.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (AuthState.instance.isAuthenticated) {
        final body = <String, dynamic>{
          'full_name': name,
        };
        if (_gender != null && _gender!.isNotEmpty) {
          body['gender'] = _gender;
        }
        final dob = _dobController.text.trim();
        if (dob.isNotEmpty) {
          body['date_of_birth'] = dob;
        }

        await ApiClient.instance.patch('users/me/', body: body);
        await AuthState.instance.refreshProfile();
      }

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.accentGreen,
          content: Text('Profile updated successfully!', style: TextStyle(color: Colors.black)),
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState.instance,
      builder: (context, _) {
        final user = AuthState.instance.currentUser;
        final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;

        return Scaffold(
          appBar: AppBar(title: const Text('Account Details')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentGreen,
                        image: hasAvatar
                            ? DecorationImage(
                                image: NetworkImage(user.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: !hasAvatar
                          ? Text(
                              user?.initials ?? 'NP',
                              style: const TextStyle(
                                fontSize: 32,
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
                        child: _uploadingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                padding: EdgeInsets.zero,
                                onPressed: _pickAndUploadPhoto,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Change Profile Photo', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: false,
                controller: TextEditingController(text: user?.email ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Email Address (Verified)',
                  prefixIcon: Icon(Icons.mail_outline),
                  suffixIcon: Icon(Icons.verified, color: AppColors.accentGreen),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: false,
                controller: TextEditingController(text: user?.phoneNumber ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Verified)',
                  prefixIcon: Icon(Icons.phone_android_rounded),
                  suffixIcon: Icon(Icons.verified, color: AppColors.accentGreen),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  hintText: 'Select gender',
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
              const SizedBox(height: 16),
              TextField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDateOfBirth,
                decoration: InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)',
                  hintText: 'Tap to select date',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: _dobController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _dobController.clear()),
                        )
                      : const Icon(Icons.arrow_drop_down),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: AppColors.indigo,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        );
      },
    );
  }
}
