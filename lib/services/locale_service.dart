import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ValueNotifier<Locale> {
  static const String _localeKey = 'app_locale';
  static final LocaleService _instance = LocaleService._internal();

  factory LocaleService() => _instance;

  LocaleService._internal() : super(const Locale('uk')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey) ?? 'uk';
    value = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}