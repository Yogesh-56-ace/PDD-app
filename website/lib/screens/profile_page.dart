import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _targetController = TextEditingController();
  
  final _passwordFormKey = GlobalKey<FormState>();
  final _currPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ApiService.getProfile();
      setState(() {
        _nameController.text = user['name'] ?? '';
        _heightController.text = user['height']?.toString() ?? '';
        _weightController.text = user['weight']?.toString() ?? '';
        _ageController.text = user['age']?.toString() ?? '';
        _targetController.text = (user['daily_target'] ?? 30).toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);

    try {
      await ApiService.updateProfile({
        'name': _nameController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'age': _ageController.text.trim(),
        'daily_target': int.parse(_targetController.text),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile details updated successfully!'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isSavingPassword = true);

    try {
      await ApiService.changePassword(
        _currPasswordController.text,
        _newPasswordController.text,
      );
      _currPasswordController.clear();
      _newPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSavingPassword = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _targetController.dispose();
    _currPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          // Edit Profile Form
          _buildFormCard(
            width: 440,
            title: 'Personal Information',
            formKey: _profileFormKey,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _targetController,
                      decoration: const InputDecoration(labelText: 'Daily Target (mins)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Target required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isSavingProfile)
                const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              else
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Profile Changes'),
                ),
            ],
          ),

          // Change Password Form
          _buildFormCard(
            width: 440,
            title: 'Security Settings',
            formKey: _passwordFormKey,
            children: [
              TextFormField(
                controller: _currPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Current password required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty || v.length < 6
                    ? 'New password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 24),
              if (_isSavingPassword)
                const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              else
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Update Password'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(
      {required double width,
      required String title,
      required GlobalKey<FormState> formKey,
      required List<Widget> children}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B2917)),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
