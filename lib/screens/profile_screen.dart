import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'auth_screen.dart';
import 'package:sign_language_app/l10n/app_localizations.dart';
import 'package:sign_language_app/services/locale_service.dart';
import 'package:sign_language_app/services/gesture_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  int _completedTests = 0;
  int _completedGestures = 0;
  int _completedNotes = 0;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (AuthService.currentUser == null) {
      // Если пользователь не установлен, пытаемся загрузить из сохраненных данных
      _loadUserFromSavedCredentials();
    } else {
      // Если пользователь уже установлен, используем его данные
      setState(() {
        _currentUser = AuthService.currentUser;
        _completedTests = _currentUser?.completedTests.length ?? 0;
        _completedGestures = _currentUser?.completedGestures.length ?? 0;
        _completedNotes = _currentUser?.completedNotes.length ?? 0;
        _isAdmin = AuthService.isAdmin();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserFromSavedCredentials() async {
    final credentials = await AuthService.loadUserCredentials();
    final username = credentials['username'];
    final password = credentials['password'];

    if (username != null && password != null) {
      try {
        final result = await AuthService.login(username, password);

        if (result['status'] == 'Login successful' || result['status'] == 'success') {
          setState(() {
            _currentUser = AuthService.currentUser;
            _completedTests = _currentUser?.completedTests.length ?? 0;
            _completedGestures = _currentUser?.completedGestures.length ?? 0;
            _completedNotes = _currentUser?.completedNotes.length ?? 0;
            _isAdmin = AuthService.isAdmin();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeService = LocaleService();
    return ValueListenableBuilder<Locale>(
      valueListenable: localeService,
      builder: (context, locale, _) {
        return Scaffold(
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _currentUser == null
                  ? _buildLoginPrompt(context)
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _currentUser!.profileImage != null && _currentUser!.profileImage!.isNotEmpty
                                ? NetworkImage(_currentUser!.profileImage!) as ImageProvider
                                : AssetImage('lib/assets/default_avatar.png') as ImageProvider,
                          ),
                          SizedBox(height: 16),
                          if ((_currentUser!.name != null && _currentUser!.name!.isNotEmpty) || (_currentUser!.username != null && _currentUser!.username.isNotEmpty))
                            Text(
                              (_currentUser!.name != null && _currentUser!.name!.isNotEmpty)
                                  ? _currentUser!.name!
                                  : _currentUser!.username,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          SizedBox(height: 8),
                          Text(
                            _isAdmin
                                ? AppLocalizations.of(context)!.admin
                                : AppLocalizations.of(context)!.user,
                            style: TextStyle(
                              fontSize: 16,
                              color: _isAdmin ? Colors.deepPurple : Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 24),
                          _buildStatisticsSection(context),
                          SizedBox(height: 24),
                          _buildButtonsSection(context),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(AppLocalizations.of(context)!.language + ':'),
                                const SizedBox(width: 16),
                                DropdownButton<Locale>(
                                  value: locale,
                                  items: [
                                    DropdownMenuItem(
                                      value: const Locale('uk'),
                                      child: Text(AppLocalizations.of(context)!.ukrainian),
                                    ),
                                    DropdownMenuItem(
                                      value: const Locale('en'),
                                      child: Text(AppLocalizations.of(context)!.english),
                                    ),
                                  ],
                                  onChanged: (Locale? newLocale) {
                                    if (newLocale != null) {
                                      localeService.setLocale(newLocale);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.not_authorized,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.please_login,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
            child: Text(AppLocalizations.of(context)!.login),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.statistics,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ProfileStatCard(
                  icon: Icons.assignment_turned_in,
                  label: AppLocalizations.of(context)!.tests_completed,
                  value: '$_completedTests',
                ),
                ProfileStatCard(
                  icon: Icons.pan_tool_alt,
                  label: AppLocalizations.of(context)!.gestures_completed,
                  value: '$_completedGestures',
                ),
                _buildStatCard(
                  AppLocalizations.of(context)!.notes_completed,
                  '$_completedNotes',
                  Icons.menu_book,
                  Colors.deepPurple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsSection(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          AppLocalizations.of(context)!.edit_profile,
          Icons.edit,
          Colors.blue,
              () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfileScreen()),
            );
            if (result == true) {
              _loadUserData();
            }
          },
        ),
        SizedBox(height: 12),
        _buildActionButton(
          AppLocalizations.of(context)!.logout,
          Icons.logout,
          Colors.red,
          () {
            _showLogoutConfirmationDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      width: 120,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color[700],
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, MaterialColor color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.reset_progress),
        content: Text(AppLocalizations.of(context)!.confirm_reset_progress),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final user = _currentUser!;
              // Сброс тестов, жестов и конспектов одновременно
              await AuthService.updateUserProfile({
                'completedTests': [],
                'completedNotes': [],
                'completedGestures': [],
              });
              _loadUserData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.progress_reset)),
              );
            },
            child: Text(AppLocalizations.of(context)!.reset.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
          content: Text(AppLocalizations.of(context)!.confirm_logout),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel.toUpperCase()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService.deleteUserCredentials();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
              child: Text(AppLocalizations.of(context)!.logout.toUpperCase()),
            ),
          ],
        ),
    );
  }
}

class ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileStatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Colors.deepPurple;
    return Container(
      width: 90,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}