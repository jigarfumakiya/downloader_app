import 'package:downloader_app/features/home/presentation/widget/add_downlaod_dialog.dart';
import 'package:downloader_app/features/home/presentation/widget/home_list_view.dart';
import 'package:downloader_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/**
 * @Author: Jigar Fumakiya
 * @Date: 30/03/23
 * @Project: downloader_app
 * app_test.dart
 */
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Should show listview when data is loaded', (widgetTester) async {
    await app.main();
    await widgetTester.pumpAndSettle();
    final listViewFinder = find.byType(HomeListView);
    expect(listViewFinder, findsOneWidget);
  });

  testWidgets('Floating button click should open up download dialog',
      (widgetTester) async {
    await widgetTester.pumpWidget(const app.MyApp());

    await widgetTester.pumpAndSettle();

    final floatingButton = find.byType(FloatingActionButton);
    await widgetTester.tap(floatingButton);
    await widgetTester.pumpAndSettle();

    expect(find.byType(AddDownloadDialog), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(TextButton), findsNWidgets(2));
  });

  testWidgets(
      'While adding download if click okay without message then it should display error ',
      (widgetTester) async {
    await widgetTester.pumpWidget(const app.MyApp());

    await widgetTester.pumpAndSettle();

    final floatingButton = find.byType(FloatingActionButton);
    await widgetTester.tap(floatingButton);
    await widgetTester.pumpAndSettle();

    expect(find.byType(AddDownloadDialog), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(TextButton), findsNWidgets(2));

    final okayButton = find.widgetWithText(TextButton, 'Add');
    await widgetTester.tap(okayButton);
    await widgetTester.pumpAndSettle();

    final textFinder = find.text('Please enter a valid URL');
    expect(textFinder, findsOneWidget);
  });

  testWidgets(
      'While adding download if URL is not valid then it should display error',
      (widgetTester) async {
    await widgetTester.pumpWidget(const app.MyApp());

    await widgetTester.pumpAndSettle();

    final floatingButton = find.byType(FloatingActionButton);
    await widgetTester.tap(floatingButton);
    await widgetTester.pumpAndSettle();

    final urlField = find.byType(TextFormField);
    expect(urlField, findsOneWidget);

    // Enter invalid URL
    await widgetTester.enterText(urlField, 'invalid-url');
    await widgetTester.pumpAndSettle();

    // Tap on "OK" button
    final okButton = find.widgetWithText(TextButton, 'Add');
    await widgetTester.tap(okButton);
    await widgetTester.pumpAndSettle();

    // Check if error message is displayed
    final errorMessage = find.text('Please enter a valid URL');
    expect(errorMessage, findsOneWidget);
  });
}
