import 'package:flutter/material.dart';
import '../models/alphabet_letter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LetterDetailScreen extends StatelessWidget {
  final AlphabetLetter letter;

  LetterDetailScreen({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.letter + ' ${letter.letter}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: 'letter_${letter.id}',
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.gesture,
                    size: 150,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  letter.letter,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  letter.language == 'uk'
                      ? AppLocalizations.of(context)!.ukrainian_alphabet
                      : AppLocalizations.of(context)!.english_alphabet,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  AppLocalizations.of(context)!.image_not_loaded_demo,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}