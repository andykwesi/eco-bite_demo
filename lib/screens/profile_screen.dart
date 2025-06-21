import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/error_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        DialogHelper.showErrorDialog(
          context: context,
          title: 'Error Loading Profile',
          message: 'Could not load your profile information. ${e.toString()}',
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
      DialogHelper.showLoadingDialog(
        context: context,
        message: 'Signing out...',
      );

      await _authService.signOut();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        DialogHelper.showErrorDialog(
          context: context,
          title: 'Sign Out Failed',
          message: 'Could not sign out. ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF97B380),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Your Impact',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
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
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/login');
                                },
                                child: const Text('Go to Login'),
                              ),
                            ],
                          ),
                        )
                        : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                radius: 50,
                                backgroundColor: Color(0xFF97B380),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _currentUser!.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentUser!.email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Member since ${_formatDate(_currentUser!.createdAt)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Impact metrics
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Impact',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildImpactMetric(
                                          'Waste Reduced',
                                          '${(_currentUser!.wasteReduction / 1000).toStringAsFixed(1)} kg',
                                          Icons.eco,
                                        ),
                                        _buildImpactMetric(
                                          'Money Saved',
                                          '\$${(_currentUser!.moneySaved / 100).toStringAsFixed(2)}',
                                          Icons.attach_money,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Settings section
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              _buildSettingItem(
                                'Notifications',
                                Icons.notifications_none,
                                onTap: () {
                                  DialogHelper.showErrorDialog(
                                    context: context,
                                    title: 'Not Implemented',
                                    message:
                                        'Notification settings are not yet implemented.',
                                  );
                                },
                              ),

                              _buildSettingItem(
                                'Privacy',
                                Icons.privacy_tip_outlined,
                                onTap: () {
                                  DialogHelper.showErrorDialog(
                                    context: context,
                                    title: 'Not Implemented',
                                    message:
                                        'Privacy settings are not yet implemented.',
                                  );
                                },
                              ),

                              _buildSettingItem(
                                'Help & Support',
                                Icons.help_outline,
                                onTap: () {
                                  DialogHelper.showErrorDialog(
                                    context: context,
                                    title: 'Not Implemented',
                                    message:
                                        'Help & Support is not yet implemented.',
                                  );
                                },
                              ),

                              const SizedBox(height: 30),

                              // Sign out button
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final confirm =
                                      await DialogHelper.showConfirmationDialog(
                                        context: context,
                                        title: 'Sign Out',
                                        message:
                                            'Are you sure you want to sign out?',
                                        confirmText: 'Sign Out',
                                      );

                                  if (confirm) {
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
          ],
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
