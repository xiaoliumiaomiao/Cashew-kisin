import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:budget/database/tables.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/watchAllWallets.dart';
import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Value;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

const _categoryName = 'Quick food';
const _categoryPk = 'quick-food';
late _SavePauseInterceptor _savePauseInterceptor;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // This fixture uses Windows' SQLite only for its isolated in-memory ledger.
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
    clientID = 'quick-entry-widget-test';
    _savePauseInterceptor = _SavePauseInterceptor();
    database = FinanceDatabase(NativeDatabase.opened(sqlite3.openInMemory())
        .interceptWith(_savePauseInterceptor));
    await database.into(database.wallets).insert(WalletsCompanion.insert(
          walletPk: const Value('0'),
          name: 'Test wallet',
          order: 0,
          currency: const Value('USD'),
        ));
    await database.into(database.categories).insert(CategoriesCompanion.insert(
          categoryPk: const Value(_categoryPk),
          name: _categoryName,
          order: 0,
          income: const Value(false),
          emojiIconName: const Value('🍲'),
        ));
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
      'new ordinary transaction starts with category for saved title preference',
      (tester) async {
    try {
      appStateSettings['askForTransactionTitle'] = true;
      await sharedPreferences.setString(
          'userSettings', jsonEncode(appStateSettings));
      await _pumpTransactionPage(tester);

      expect(find.byType(SelectTitle), findsNothing);
      expect(
          find.byType(SelectCategoryWithIncomeExpenseSelector), findsOneWidget);
      expect(find.text(_categoryName), findsOneWidget);
      final savedSettings = jsonDecode(
          sharedPreferences.getString('userSettings')!) as Map<String, dynamic>;
      expect(savedSettings['askForTransactionTitle'], true);
      expect(await _transactions(tester), isEmpty);
    } finally {
      await _disposeTransactionPage(tester);
    }
  });

  testWidgets('picking category opens amount with editing left and saving right',
      (tester) async {
    try {
      await _openQuickAmount(tester);

      expect(find.byType(SelectAmount), findsOneWidget);
      final amountButtons = find.descendant(
          of: find.byType(SelectAmount), matching: find.byType(Button));
      expect(amountButtons, findsNWidgets(2));
      final editing = _amountAction('Continue Editing');
      final saving = _amountAction('Add Transaction');
      expect(editing, findsOneWidget);
      expect(saving, findsOneWidget);
      expect(tester.getCenter(editing).dx, lessThan(tester.getCenter(saving).dx));
      expect(await _transactions(tester), isEmpty);
    } finally {
      await _disposeTransactionPage(tester);
    }
  });

  testWidgets('continue editing keeps amount and category without saving',
      (tester) async {
    try {
      await _openQuickAmount(tester);
      await _enterAmount(tester, '23');
      await tester.tap(_amountAction('Continue Editing'));
      await _settle(tester);

      _expectDetailedForm(tester, amount: '23');
      expect(await _transactions(tester), isEmpty);
    } finally {
      await _disposeTransactionPage(tester);
    }
  });

  testWidgets('continue editing also returns to the form before amount entry',
      (tester) async {
    try {
      await _openQuickAmount(tester);
      await tester.tap(_amountAction('Continue Editing'));
      await _settle(tester);

      _expectDetailedForm(tester, amount: '0');
      expect(await _transactions(tester), isEmpty);
    } finally {
      await _disposeTransactionPage(tester);
    }
  });

  testWidgets('outside amount sheet dismisses it without saving entered values',
      (tester) async {
    try {
      await _openQuickAmount(tester);
      await _enterAmount(tester, '23');
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      _expectDetailedForm(tester, amount: '23');
      expect(await _transactions(tester), isEmpty);
    } finally {
      await _disposeTransactionPage(tester);
    }
  });

  testWidgets('add transaction persists exactly one row and returns to caller',
      (tester) async {
    try {
      await _openQuickAmount(tester);
      await _enterAmount(tester, '23');
      await tester.tap(_amountAction('Add Transaction'));
      await _settle(tester);

      expect(find.byType(AddTransactionPage), findsNothing);
      expect(find.text('Open transaction'), findsOneWidget);
      final transactions = await _transactions(tester);
      expect(transactions, hasLength(1));
      expect(transactions.single.amount, -23);
      expect(transactions.single.categoryFk, _categoryPk);
      expect(transactions.single.walletFk, '0');
      expect(transactions.single.name, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(await _transactions(tester), hasLength(1));
    } finally {
      await _disposeTransactionPage(tester);
    }
  });

  testWidgets('rapid Add taps save once and close only the amount and add routes',
      (tester) async {
    _PausedSave? heldDatabase;
    try {
      final navigation = _RouteRecorder();
      await _openQuickAmount(tester,
          routeRecorder: navigation, nestedCaller: true);
      await _enterAmount(tester, '23');
      final popsBeforeSaving = navigation.popped.length;
      heldDatabase = _savePauseInterceptor.pauseNextSave();

      await tester.tap(_amountAction('Add Transaction'));
      await tester.tap(_amountAction('Add Transaction'));
      await _settle(tester);

      expect(heldDatabase.started.isCompleted, true);
      expect(find.byType(SelectAmount), findsOneWidget);
      expect(find.byType(AddTransactionPage), findsOneWidget);
      expect(navigation.popped, hasLength(popsBeforeSaving));
      expect(await _transactions(tester), isEmpty);
      await heldDatabase.release(tester);
      await _settle(tester);

      expect(find.byType(AddTransactionPage), findsNothing);
      expect(find.text('Open transaction'), findsOneWidget);
      expect(find.text('Open caller'), findsNothing);
      expect(navigation.popped, hasLength(popsBeforeSaving + 2));
      expect(await _transactions(tester), hasLength(1));
    } finally {
      await heldDatabase?.release(tester);
      await _disposeTransactionPage(tester);
    }
  });

  for (final dismissWithEditing in [true, false]) {
    testWidgets(
        '${dismissWithEditing ? 'Continue Editing' : 'outside dismissal'} during save preserves a newly opened amount sheet',
        (tester) async {
      _PausedSave? heldDatabase;
      try {
        final navigation = _RouteRecorder();
        await _openQuickAmount(tester,
            routeRecorder: navigation, nestedCaller: true);
        await _enterAmount(tester, '23');
        final popsBeforeSaving = navigation.popped.length;
        heldDatabase = _savePauseInterceptor.pauseNextSave();

        await tester.tap(_amountAction('Add Transaction'));
        await _settle(tester);
        expect(heldDatabase.started.isCompleted, true);
        expect(await _transactions(tester), isEmpty);
        if (dismissWithEditing) {
          await tester.tap(_amountAction('Continue Editing'));
        } else {
          await tester.tapAt(const Offset(10, 10));
        }
        await _settle(tester);
        _expectDetailedForm(tester, amount: '23');
        expect(navigation.popped, hasLength(popsBeforeSaving + 1));

        // Open a different real modal before the original save can complete.
        await tester.tap(find.ancestor(
            of: _detailAmount(), matching: find.byType(Tappable)).first);
        await _settle(tester);
        expect(_amountAction('Set Amount'), findsOneWidget);
        await heldDatabase.release(tester);
        await _settle(tester);

        expect(_amountAction('Set Amount'), findsOneWidget);
        expect(find.byType(AddTransactionPage), findsOneWidget);
        expect(find.text('Open transaction'), findsNothing);
        expect(find.text('Open caller'), findsNothing);
        expect(navigation.popped, hasLength(popsBeforeSaving + 1));
        final transactions = await _transactions(tester);
        expect(transactions, hasLength(1));
        expect(transactions.single.amount, -23);
      } finally {
        await heldDatabase?.release(tester);
        await _disposeTransactionPage(tester);
      }
    });
  }

  testWidgets('continue editing lets the detailed form save title and notes',
      (tester) async {
    try {
      await _openQuickAmount(tester);
      await _enterAmount(tester, '23');
      await tester.tap(_amountAction('Continue Editing'));
      await _settle(tester);
      _expectDetailedForm(tester, amount: '23');

      final titleField = find.descendant(
          of: find.byType(TitleInput), matching: find.byType(TextFormField));
      await tester.ensureVisible(titleField);
      await tester.enterText(titleField, 'Lunch with Alex');
      await _settle(tester);
      final notesField = find.descendant(
          of: find.byType(TransactionNotesTextInput),
          matching: find.byType(TextFormField));
      await tester.ensureVisible(notesField);
      await tester.enterText(notesField, 'Receipt kept for reimbursement');
      await _settle(tester);
      FocusManager.instance.primaryFocus?.unfocus();
      await _settle(tester);
      expect(await _transactions(tester), isEmpty);

      final detailSave = find.byWidgetPredicate(
          (widget) => widget is Button && widget.label == 'Add Transaction');
      expect(detailSave, findsOneWidget);
      await tester.tap(detailSave);
      await _settle(tester);

      expect(find.byType(AddTransactionPage), findsNothing);
      expect(find.text('Open transaction'), findsOneWidget);
      final transactions = await _transactions(tester);
      expect(transactions, hasLength(1));
      expect(transactions.single.name, 'Lunch with Alex');
      expect(transactions.single.note, 'Receipt kept for reimbursement');
      expect(transactions.single.amount, -23);
      expect(transactions.single.categoryFk, _categoryPk);
      expect(transactions.single.walletFk, '0');
    } finally {
      await _disposeTransactionPage(tester);
    }
  });

  testWidgets('amount editing from detailed form keeps one Set Amount action',
      (tester) async {
    try {
      final categories =
          await tester.runAsync(() => database.getAllCategories());
      final category = categories!.single;
      await _pumpTransactionPage(tester,
          startInitialSequence: false, category: category, amount: -23);
      await tester.tap(find.ancestor(
          of: _detailAmount(), matching: find.byType(Tappable)).first);
      await _settle(tester);

      expect(find.byType(SelectAmount), findsOneWidget);
      expect(_amountAction('Set Amount'), findsOneWidget);
      expect(_amountAction('Continue Editing'), findsNothing);
      expect(_amountAction('Add Transaction'), findsNothing);
      expect(
          find.descendant(
              of: find.byType(SelectAmount), matching: find.byType(Button)),
          findsOneWidget);
      await tester.tap(_amountAction('Set Amount'));
      await _settle(tester);
      _expectDetailedForm(tester, amount: '23');
      expect(await _transactions(tester), isEmpty);
    } finally {
      await _disposeTransactionPage(tester);
    }
  });
}

Future<void> _pumpTransactionPage(WidgetTester tester,
    {bool startInitialSequence = true,
    TransactionCategory? category,
    double? amount,
    _RouteRecorder? routeRecorder,
    bool nestedCaller = false}) async {
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
          navigatorObservers: [if (routeRecorder != null) routeRecorder],
          home: Builder(builder: (context) {
            Widget buildCaller(BuildContext context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddTransactionPage(
                        routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                        startInitialAddTransactionSequence: startInitialSequence,
                        selectedCategory: category,
                        selectedAmount: amount,
                      ),
                    ),
                  ),
                  child: const Text('Open transaction'),
                ),
              );
            }

            if (!nestedCaller) return buildCaller(context);
            return Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: buildCaller),
                ),
                child: const Text('Open caller'),
              ),
            );
          }),
        ),
      );
    }),
  ));
  await _settle(tester);
  if (nestedCaller) {
    await tester.tap(find.text('Open caller'));
    await _settle(tester);
  }
  await tester.tap(find.text('Open transaction'));
  await _settle(tester);
}

Future<void> _openQuickAmount(WidgetTester tester,
    {_RouteRecorder? routeRecorder, bool nestedCaller = false}) async {
  // Isolate amount behavior from the separate persisted-title regression.
  appStateSettings['askForTransactionTitle'] = false;
  await _pumpTransactionPage(tester,
      routeRecorder: routeRecorder, nestedCaller: nestedCaller);
  expect(find.byType(SelectCategoryWithIncomeExpenseSelector), findsOneWidget);
  final categoryIcon = find.ancestor(
      of: find.text(_categoryName), matching: find.byType(CategoryIcon));
  await tester.tap(find.descendant(
      of: categoryIcon, matching: find.byType(Tappable)).first);
  await _settle(tester);
  expect(find.byType(SelectAmount), findsOneWidget);
}

Future<void> _enterAmount(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    final button = find.byWidgetPredicate(
        (widget) => widget is CalculatorButton && widget.label == digit);
    await tester.tap(find.descendant(of: button, matching: find.text(digit)));
    await _settle(tester);
  }
}

Finder _amountAction(String label) => find.descendant(
      of: find.byType(SelectAmount),
      matching: find.byWidgetPredicate(
          (widget) => widget is Button && widget.label == label),
    );

Finder _detailAmount() => find.byWidgetPredicate(
    (widget) => widget is TextFont && widget.fontSize == 32);

void _expectDetailedForm(WidgetTester tester, {required String amount}) {
  expect(find.byType(AddTransactionPage), findsOneWidget);
  expect(find.byType(SelectAmount), findsNothing);
  expect(find.byType(SelectCategoryWithIncomeExpenseSelector), findsNothing);
  expect(find.text('Open transaction'), findsNothing);
  expect(find.text(_categoryName), findsOneWidget);
  expect(_detailAmount(), findsOneWidget);
  final displayedNumber = tester
      .widget<TextFont>(_detailAmount())
      .text
      .replaceAll(RegExp(r'[^0-9.]'), '');
  expect(double.parse(displayedNumber), double.parse(amount));
}

Future<List<Transaction>> _transactions(WidgetTester tester) async =>
    (await tester.runAsync(
        () => database.select(database.transactions).get()))!;

class _RouteRecorder extends NavigatorObserver {
  final popped = <Route<dynamic>>[];

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popped.add(route);
    super.didPop(route, previousRoute);
  }
}

class _PausedSave {
  final started = Completer<void>();
  final resume = Completer<void>();

  Future<void> release(WidgetTester tester) async {
    if (resume.isCompleted) return;
    resume.complete();
    await _settle(tester);
  }
}

class _SavePauseInterceptor extends QueryInterceptor {
  _PausedSave? _nextSave;

  _PausedSave pauseNextSave() {
    assert(_nextSave == null);
    return _nextSave = _PausedSave();
  }

  @override
  Future<int> runInsert(
      QueryExecutor executor, String statement, List<Object?> args) async {
    final pausedSave = _nextSave;
    if (pausedSave != null && statement.contains('"transactions"')) {
      _nextSave = null;
      pausedSave.started.complete();
      await pausedSave.resume.future;
    }
    // Delay one INSERT, then execute the unchanged SQL against real SQLite.
    return executor.runInsert(statement, args);
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  // Route and amount transitions take at most 500 ms. A bounded clock advance
  // also permits the page's background animations without waiting on them.
  for (var frame = 0; frame < 16; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
}

Future<void> _disposeTransactionPage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  var closed = false;
  final closingDatabase = database.close().then((_) => closed = true);
  // Drift stream cancellation can schedule another timer after each flush.
  for (var frame = 0; frame < 30 && !closed; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
  expect(closed, true, reason: 'The isolated test database must close.');
  await closingDatabase;
  await tester.pump(const Duration(seconds: 2));
}
