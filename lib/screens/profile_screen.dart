// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/error_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen gains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload data when app becomes visible
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUser = _authService.currentUser;

      // If user is null, try to get it from the auth stream
      if (_currentUser == null) {
        await for (final user in _authService.authStateChanges) {
          if (user != null) {
            _currentUser = user;
            break;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        await showCustomInfoDialog(
          context: context,
          title: 'Error Loading Profile',
          message: 'Could not load your profile information. ${e.toString()}',
          icon: Icons.error,
          isDestructive: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await showCustomInfoDialog(
        context: context,
        title: 'Signing out...',
        message: '',
        icon: Icons.logout,
      );

      await _authService.signOut();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        await showCustomInfoDialog(
          context: context,
          title: 'Sign Out Failed',
          message: 'Could not sign out. ${e.toString()}',
          icon: Icons.error,
          isDestructive: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentUser == null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Not logged in',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            const CircleAvatar(
                              radius: 50,
                              backgroundColor: Color(0xFF4CAF50),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  onPressed: () async {
                                    await showCustomInfoDialog(
                                      context: context,
                                      title: 'Profile Picture',
                                      message:
                                          'Profile picture editing is not implemented.',
                                      icon: Icons.info_outline,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _EditableProfileInfo(user: _currentUser!),
                        const SizedBox(height: 20),
                        _ImpactCard(user: _currentUser!),
                        const SizedBox(height: 30),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildSettingItem(
                          'Notifications',
                          Icons.notifications_none,
                          onTap:
                              () => showCustomInfoDialog(
                                context: context,
                                title: 'Not Implemented',
                                message:
                                    'Notification settings are not yet implemented.',
                                icon: Icons.info_outline,
                              ),
                        ),
                        _buildSettingItem(
                          'Privacy',
                          Icons.privacy_tip_outlined,
                          onTap:
                              () => showCustomInfoDialog(
                                context: context,
                                title: 'Not Implemented',
                                message:
                                    'Privacy settings are not yet implemented.',
                                icon: Icons.info_outline,
                              ),
                        ),
                        _buildSettingItem(
                          'Help & Support',
                          Icons.help_outline,
                          onTap:
                              () => showCustomInfoDialog(
                                context: context,
                                title: 'Not Implemented',
                                message:
                                    'Help & Support is not yet implemented.',
                                icon: Icons.info_outline,
                              ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showCustomConfirmDialog(
                              context: context,
                              title: 'Sign Out',
                              message: 'Are you sure you want to sign out?',
                              confirmText: 'Sign Out',
                              cancelText: 'Cancel',
                              isDestructive: true,
                              icon: Icons.logout,
                            );
                            if (confirm == true) {
                              _handleSignOut();
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = _getMonthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildImpactMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF97B380)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _EditableProfileInfo extends StatefulWidget {
  final User user;
  const _EditableProfileInfo({required this.user});
  @override
  State<_EditableProfileInfo> createState() => _EditableProfileInfoState();
}

class _EditableProfileInfoState extends State<_EditableProfileInfo> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  bool _editing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.user.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.user.lastName ?? '',
    );
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Update the user profile in Firestore
      await AuthService().updateUserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Exit editing mode
        setState(() {
          _editing = false;
        });

        // Refresh the parent widget to show updated data
        if (context.mounted) {
          // Trigger a rebuild of the parent profile screen
          final profileScreen =
              context.findAncestorStateOfType<_ProfileScreenState>();
          profileScreen?.setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child:
                      _editing
                          ? TextField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              border: OutlineInputBorder(),
                            ),
                          )
                          : Text(
                            widget.user.firstName?.isNotEmpty == true
                                ? widget.user.firstName!
                                : 'First Name Not Set',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      _editing
                          ? TextField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(),
                            ),
                          )
                          : Text(
                            widget.user.lastName?.isNotEmpty == true
                                ? widget.user.lastName!
                                : 'Last Name Not Set',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                ),
                IconButton(
                  icon: Icon(
                    _editing
                        ? (_isSaving ? Icons.hourglass_empty : Icons.check)
                        : Icons.edit,
                    color: const Color(0xFF4CAF50),
                  ),
                  onPressed:
                      _isSaving
                          ? null
                          : () async {
                            if (_editing) {
                              await _saveProfile();
                            } else {
                              setState(() {
                                _editing = true;
                              });
                            }
                          },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _editing
                ? TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                )
                : Text(
                  widget.user.email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
            if (_editing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : () {
                                setState(() {
                                  _editing = false;
                                  // Reset to original values
                                  _firstNameController.text =
                                      widget.user.firstName ?? '';
                                  _lastNameController.text =
                                      widget.user.lastName ?? '';
                                  _emailController.text = widget.user.email;
                                });
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final User user;
  const _ImpactCard({required this.user});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Impact',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImpactMetric(
                  'Waste Reduced',
                  '${(user.wasteReduction / 1000).toStringAsFixed(1)} kg',
                  Icons.eco,
                ),
                _buildImpactMetric(
                  'Money Saved',
                  ' 24${(user.moneySaved / 100).toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
