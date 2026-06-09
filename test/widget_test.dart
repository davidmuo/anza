// Smoke test: confirms the app boots to the onboarding screen on a fresh
// install (no persisted user, no completed-onboarding flag).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anza/app.dart';
import 'package:anza/services/storage_service.dart';

void main() {
  testWidgets('Fresh install shows the onboarding screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.create();

    await tester.pumpWidget(AnzaApp(storageService: storageService));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Anza'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
