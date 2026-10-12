import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/pages/onBoardingPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/tappableTextEntry.dart';
import 'package:budget/widgets/watchAllWallets.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Windows includes SQLite. Use it only for this in-memory test fixture;
    // the application still uses its bundled platform database library.
    if (Platform.isWindows) {
      open.overrideFor(
          OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
    }
  });

  setUp(() async {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    appStateSettings = await getDefaultPreferences();
    isDatabaseImportedOnThisSession = false;
    clientID = 'onboarding-widget-test';
    database = FinanceDatabase(NativeDatabase.opened(sqlite3.openInMemory()));
    await database.customSelect('SELECT 1').get();
    await EasyLocalization.ensureInitialized();
  });

  for (final emulateIOS in [false, true]) {
    testWidgets(
        'the second onboarding page completes local setup (${emulateIOS ? 'iOS' : 'Android-style'})',
        (tester) async {
      try {
        appStateSettings['iOSEmulate'] = emulateIOS;
        await pumpOnboarding(tester);

        await tapNext(tester);
        expect(find.text('Create a budget'), findsOneWidget);
        expect(appStateSettings['hasOnboarded'], false);
        expect(find.byTooltip("Let's Go!"), findsOneWidget);

        final nextButton = find.byType(ButtonIcon).last;
        final opacity = find.ancestor(
            of: nextButton, matching: find.byType(AnimatedOpacity));
        // The last local setup page must have a painted, usable completion action.
        if (opacity.evaluate().isNotEmpty) {
          expect(tester.widget<AnimatedOpacity>(opacity.first).opacity, 1);
        }
        await tapNext(tester);

        expect(appStateSettings['hasOnboarded'], true);
        final savedSettings =
            jsonDecode(sharedPreferences.getString('userSettings')!)
                as Map<String, dynamic>;
        expect(savedSettings['hasOnboarded'], true);
        expect(await database.getAllWallets(), isNotEmpty);
        expect(await database.getAllCategories(), isNotEmpty);
        expect(await database.getAllBudgets(), isEmpty);
        expect(find.text('Sign In with Google'), findsNothing);
        expect(find.text('Continue Without Sign In'), findsNothing);
      } finally {
        await disposeOnboarding(tester);
      }
    });
  }

  testWidgets('completing a presented onboarding flow returns to its caller',
      (tester) async {
    try {
      await pumpOnboarding(tester, presented: true);
      await tapNext(tester);
      await tapNext(tester);

      expect(find.text('Caller page'), findsOneWidget);
      expect(find.byType(OnBoardingPage), findsNothing);
      expect(appStateSettings['hasOnboarded'], false);
      expect(await database.getAllWallets(), isNotEmpty);
    } finally {
      await disposeOnboarding(tester);
    }
  });

  testWidgets('finishing local setup saves the optional budget once',
      (tester) async {
    try {
      await pumpOnboarding(tester);
      await tapNext(tester);

      final amountEntry = find.byWidgetPredicate(
          (widget) => widget is TappableTextEntry && widget.fontSize == 35);
      await tester.tap(amountEntry);
      await tester.pumpAndSettle();
      for (final digit in ['2', '5', '0']) {
        final calculatorButton = find.byWidgetPredicate(
            (widget) => widget is CalculatorButton && widget.label == digit);
        await tester.tap(
            find.descendant(of: calculatorButton, matching: find.text(digit)));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is Button && widget.label == 'Set Amount'));
      await tester.pumpAndSettle();
      await tapNext(tester);

      expect(appStateSettings['hasOnboarded'], true);
      final budgets = await database.getAllBudgets();
      expect(budgets, hasLength(1));
      expect(budgets.single.amount, 250);
      expect(budgets.single.walletFk, '0');
      expect(budgets.single.pinned, true);
      expect(budgets.single.reoccurrence, BudgetReoccurence.monthly);
    } finally {
      await disposeOnboarding(tester);
    }
  });
}

Future<void> pumpOnboarding(WidgetTester tester,
    {bool presented = false}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations/generated',
    fallbackLocale: const Locale('en'),
    child: Builder(builder: (context) {
      return WatchAllWallets(
        child: MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: presented
              ? Builder(builder: (context) {
                  return Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const OnBoardingPage(
                            popNavigationWhenDone: true,
                            showPreviewDemoButton: false,
                          ),
                        ),
                      ),
                      child: const Text('Caller page'),
                    ),
                  );
                })
              : const OnBoardingPage(showPreviewDemoButton: false),
        ),
      );
    }),
  ));
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pumpAndSettle();
  if (presented) {
    await tester.tap(find.text('Caller page'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpAndSettle();
  }
}

Future<void> disposeOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  final closingDatabase = database.close();
  // Drift defers stream cleanup with timers in the test's fake clock.
  await tester.pump(const Duration(seconds: 1));
  await closingDatabase;
}

Future<void> tapNext(WidgetTester tester) async {
  await tester.tap(find.byType(ButtonIcon).last);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pumpAndSettle();
}
