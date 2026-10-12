import 'package:budget/database/tables.dart';
import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/transactionEntry/swipeToSelectTransactions.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:budget/widgets/transactionEntry/transactionEntryTypeButton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
    appStateSettings = await getDefaultPreferences();
    globalSelectedID.value = {};
    globalCollapsedFutureID.value = {};
    selectingTransactionsActive = 0;
    recentlyAddedTransactionInfo.value =
        RecentlyAddedTransactionInfo(null, false);
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('single taps toggle nonadjacent rows after a long press',
      (tester) async {
    await pumpEntries(tester);

    await tester.longPress(find.text('Entry 1'));
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], ['1']);

    await tester.tap(find.text('Entry 4'));
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], ['1', '4']);
    expect(find.text('Details 4'), findsNothing);
    expect(selectingTransactionsActive, 0);

    await tester.tap(find.text('Entry 1'));
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], ['4']);
    await tester.tap(find.text('Entry 4'));
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], isEmpty);

    await tester.tap(find.text('Entry 4'));
    await tester.pumpAndSettle();
    expect(find.text('Details 4'), findsOneWidget);
  });

  testWidgets('category and action buttons toggle the row during selection',
      (tester) async {
    await pumpEntries(tester, lastEntryType: TransactionSpecialType.upcoming);
    await tester.longPress(find.text('Entry 1'));
    await tester.pumpAndSettle();

    final lastRow = find.byKey(const ValueKey('row-4'));
    // Tap the painted control's position: selection intentionally transfers
    // its pointer handling to the surrounding row.
    await tester.tapAt(tester.getCenter(find.descendant(
      of: lastRow,
      matching: find.byType(CategoryIcon),
    )));
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], ['1', '4']);
    expect(find.text('Details 4'), findsNothing);

    await tester.tapAt(tester.getCenter(find.descendant(
      of: lastRow,
      matching: find.byType(ActionButton),
    )));
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], ['1']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('checkbox dragging still deselects consecutive iOS rows',
      (tester) async {
    appStateSettings['iOSEmulate'] = true;
    await pumpEntries(tester);
    await tester.longPress(find.text('Entry 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entry 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entry 4'));
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], ['1', '3', '4']);

    final lastCheckbox = find.descendant(
      of: find.byKey(const ValueKey('row-4')),
      matching: find.byType(TransactionSelectionCheck),
    );
    final thirdCheckbox = find.descendant(
      of: find.byKey(const ValueKey('row-3')),
      matching: find.byType(TransactionSelectionCheck),
    );
    final start = tester.getCenter(lastCheckbox);
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(start - const Offset(0, 25));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(thirdCheckbox));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], ['1']);
    expect(selectingTransactionsActive, 0);
  });

  testWidgets('an unselectable row still opens details during selection',
      (tester) async {
    await pumpEntries(tester, lastEntryAllowSelect: false);
    await tester.longPress(find.text('Entry 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entry 4'));
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], ['1']);
    expect(find.text('Details 4'), findsOneWidget);
  });

  testWidgets('selection in another list does not change normal row taps',
      (tester) async {
    await pumpEntries(tester, lastEntryListId: 'Other list');
    await tester.longPress(find.text('Entry 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entry 4'));
    await tester.pumpAndSettle();
    expect(globalSelectedID.value['Transactions'], ['1']);
    expect(globalSelectedID.value['Other list'], isEmpty);
    expect(find.text('Details 4'), findsOneWidget);
  });
}

Future<void> pumpEntries(
  WidgetTester tester, {
  bool? lastEntryAllowSelect,
  String lastEntryListId = 'Transactions',
  TransactionSpecialType? lastEntryType,
}) async {
  // Dispose the previous app, including routes opened by the preceding test.
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final created = DateTime(2026, 10, 12);
  final wallet = TransactionWallet(
    walletPk: '0',
    name: 'Test account',
    dateCreated: created,
    order: 0,
    currency: 'usd',
    decimals: 2,
  );
  final category = TransactionCategory(
    categoryPk: 'test-category',
    name: 'Test category',
    colour: 'FF123456',
    dateCreated: created,
    order: 0,
    income: false,
  );
  final transactions = List.generate(
    4,
    (index) => Transaction(
      transactionPk: '${index + 1}',
      name: 'Entry ${index + 1}',
      amount: -10,
      note: '',
      categoryFk: category.categoryPk,
      walletFk: wallet.walletPk,
      dateCreated: created,
      income: false,
      paid: true,
      skipPaid: false,
      type: index == 3 ? lastEntryType : null,
    ),
  );

  await tester.pumpWidget(EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations/generated',
    fallbackLocale: const Locale('en'),
    child: Builder(builder: (context) {
      return Provider<AllWallets>.value(
        value: AllWallets(list: [wallet], indexedByPk: {'0': wallet}),
        child: MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: SwipeToSelectTransactions(
              listID: 'Transactions',
              child: ListView(
                children: List.generate(4, (index) {
                  return TransactionEntry(
                    key: ValueKey('row-${index + 1}'),
                    transaction: transactions[index],
                    transactionBefore:
                        index == 0 ? null : transactions[index - 1],
                    transactionAfter:
                        index == 3 ? null : transactions[index + 1],
                    category: category,
                    listID: index == 3 ? lastEntryListId : 'Transactions',
                    allowSelect: index == 3 ? lastEntryAllowSelect : null,
                    openPage: Scaffold(
                      body: Center(child: Text('Details ${index + 1}')),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
    }),
  ));
  // Asset loading is real asynchronous work and is not advanced by pump alone.
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
    if (find.text('Entry 1').evaluate().isNotEmpty) break;
  }
  expect(find.text('Entry 1'), findsOneWidget);
}
