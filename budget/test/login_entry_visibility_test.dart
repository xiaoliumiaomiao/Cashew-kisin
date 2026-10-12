import 'package:budget/pages/settingsPage.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/exportCSV.dart';
import 'package:budget/widgets/exportDB.dart';
import 'package:budget/widgets/importCSV.dart';
import 'package:budget/widgets/importDB.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
    appStateSettings = await getDefaultPreferences();
    googleUser = null;
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('mobile More retains account tools without a Google login entry',
      (tester) async {
    await pumpSettingsSurface(tester, const MorePages());
    try {
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Settings & Customization'), findsOneWidget);
      final notifications = find.byWidgetPredicate((widget) =>
          widget is SettingsContainerOpenPage &&
          widget.title == 'Notifications');
      expect(tester.getSize(notifications).width, greaterThan(350));
      expect(find.byType(GoogleAccountLoginButton), findsNothing);
      expect(find.text('Login'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('settings retain CSV and local backup tools without Google Drive',
      (tester) async {
    await pumpSettingsSurface(tester, const SettingsPageContent());
    try {
      expect(find.byType(ExportCSV), findsOneWidget);
      expect(find.byType(ImportCSV), findsOneWidget);
      expect(find.byType(ExportDB), findsOneWidget);
      expect(find.byType(ImportDB), findsOneWidget);
      expect(find.byType(GoogleAccountLoginButton), findsNothing);
      expect(find.text('Google Drive'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('desktop sidebar keeps navigation without a Google login entry',
      (tester) async {
    await pumpSettingsSurface(tester, const NavigationSidebar(), desktop: true);
    try {
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(GoogleAccountLoginButton), findsNothing);
      expect(find.text('Login'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

Future<void> pumpSettingsSurface(WidgetTester tester, Widget surface,
    {bool desktop = false}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize =
      desktop ? const Size(1200, 1400) : const Size(1170, 2532);
  tester.view.devicePixelRatio = desktop ? 1 : 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations/generated',
    fallbackLocale: const Locale('en'),
    child: Builder(builder: (context) {
      return MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(
          body: desktop
              ? Align(alignment: Alignment.topLeft, child: surface)
              : SingleChildScrollView(child: surface),
        ),
      );
    }),
  ));
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
    if (find.byType(surface.runtimeType).evaluate().isNotEmpty) break;
  }
  expect(find.byType(surface.runtimeType), findsOneWidget);
}
