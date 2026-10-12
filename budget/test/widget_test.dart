import 'package:budget/struct/defaultPreferences.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/colorPicker.dart';
import 'package:budget/widgets/selectColor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('custom color opens the picker and reports the selected color',
      (tester) async {
    tester.view.physicalSize = const Size(2400, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    appStateSettings = await getDefaultPreferences();
    expect(appStateSettings['purchaseID'], isNull);

    Color? chosenColor;
    await EasyLocalization.ensureInitialized();
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
            body: Center(
              child: ColorIconCustom(
                size: 55,
                outline: false,
                initialSelectedColor: Colors.blue,
                onTap: (color) => chosenColor = color,
              ),
            ),
          ),
        );
      }),
    ));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ColorIconCustom));
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(RingColorPicker), findsOneWidget);

    final hueRing = find.byType(ColorPickerHueRing);
    final ringSize = tester.getSize(hueRing);
    await tester
        .tapAt(tester.getTopLeft(hueRing) + Offset(ringSize.width / 2, 8));
    await tester.pump();
    await tester.ensureVisible(find.byType(Button).last);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(Button).last);
    await tester.pump();
    expect(chosenColor, isNotNull);
    expect(chosenColor, isNot(Colors.blue));
  });
}
