// lib/screens/gestures_screen.dart
import 'package:flutter/material.dart';
import '../screens/dictionary_screen.dart';
import '../screens/alphabet_selection_screen.dart';
import '../screens/tests_screen.dart';
import '../screens/gesture_selection_screen.dart';
import '../screens/notes_screen.dart';
import 'package:sign_language_app/l10n/app_localizations.dart';
import 'package:sign_language_app/services/auth_service.dart';

class GesturesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCategoryCard(
            context,
            AppLocalizations.of(context)!.gestures_dictionary,
            AppLocalizations.of(context)!.gestures_dictionary_description,
            Icons.sign_language,
            Colors.purple[700]!,
                () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DictionaryScreen())
            ),
          ),
          SizedBox(height: 16),
          _buildCategoryCard(
            context,
            AppLocalizations.of(context)!.gestures_alphabet,
            AppLocalizations.of(context)!.gestures_alphabet_description,
            Icons.text_fields,
            Colors.blue[700]!,
                () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlphabetSelectionScreen())
            ),
          ),
          SizedBox(height: 16),
          _buildCategoryCard(
            context,
            AppLocalizations.of(context)!.gestures_tests,
            AppLocalizations.of(context)!.gestures_tests_description,
            Icons.quiz,
            Colors.green[700]!,
                () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TestsScreen())
            ),
          ),
          SizedBox(height: 16),
          _buildCategoryCard(
            context,
            AppLocalizations.of(context)!.notes,
            AppLocalizations.of(context)!.notes_description,
            Icons.menu_book,
            Colors.deepPurple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotesScreen(
                  userId: AuthService.currentUser?.username,
                  completedNotes: AuthService.currentUser?.completedNotes ?? [],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onPressed
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}