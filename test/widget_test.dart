import 'package:flutter_test/flutter_test.dart';
import 'package:sign_language_app/main.dart';

void main() {
  testWidgets('Main screen has camera, dictionary, and profile tabs', (WidgetTester tester) async {
    await tester.pumpWidget(SignLanguageApp());
    expect(find.text('Камера'), findsOneWidget);
    expect(find.text('Словарь'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);
  });
}

