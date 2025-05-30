import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  int _completedTests = 0;
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
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return _currentUser == null
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
          Text(
            _currentUser!.username,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _isAdmin ? 'Адміністратор' : 'Користувач',
            style: TextStyle(
              fontSize: 16,
              color: _isAdmin ? Colors.deepPurple : Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          _buildStatisticsSection(),
          SizedBox(height: 24),
          _buildButtonsSection(context),
        ],
      ),
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
            'Ви не авторизованіі',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Будь-ласка, увійдіть в аккаунт',
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
            child: Text('Увійти'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
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
              'Статистика',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Тестів пройдено',
                  '$_completedTests',
                  Icons.assignment_turned_in,
                  Colors.green,
                ),
                _buildStatCard(
                  'Рівень',
                  _getLevel(),
                  Icons.star,
                  Colors.amber,
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
          'Редагування профіля',
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
          'Скинути прогрес тестів',
          Icons.refresh,
          Colors.orange,
              () {
            _showResetConfirmationDialog(context);
          },
        ),
        SizedBox(height: 12),
        _buildActionButton(
          'Вийти з аккаунта',
          Icons.exit_to_app,
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
        title: Text('Скинути прогрес'),
        content: Text('Ви впевнені, що хочете скинути увесь прогрес тестів? Цю дію неможна буде потім відмінити.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ВІДМІНА'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Вызываем метод сброса прогресса
              await AuthService.resetCompletedTests(_currentUser!.username);
              _loadUserData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Прогрес тестів скинуто')),
              );
            },
            child: Text('СКИНУТИ'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: Text('Вихід з аккаунту'),
          content: Text('Ви впевнені, що хочете вийти з аккаунту?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ВІДМІНА'),
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
              child: Text('ВИЙТИ'),
            ),
          ],
        ),
    );
  }

  String _getLevel() {
    if (_completedTests >= 15) return 'Експерт';
    if (_completedTests >= 10) return 'Досвічений';
    if (_completedTests >= 5) return 'Середній';
    return 'Новачок';
  }
}