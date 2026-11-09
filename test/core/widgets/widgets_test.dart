import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/errors/app_failure.dart';
import 'package:speakdaily/core/widgets/widgets.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await pumpThemed(tester, AppButton(label: 'Continue', onPressed: () => taps++));
      await tester.tap(find.text('Continue'));
      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpThemed(tester, const AppButton(label: 'Continue', onPressed: null));
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    });

    testWidgets('loading shows a spinner and blocks taps', (tester) async {
      var taps = 0;
      await pumpThemed(tester, AppButton(label: 'Save', isLoading: true, onPressed: () => taps++));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.bySemanticsLabel('Save, loading'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('variants map to the right Material buttons', (tester) async {
      await pumpThemed(
        tester,
        Column(children: [
          AppButton.secondary(label: 'A', onPressed: () {}),
          AppButton.text(label: 'B', onPressed: () {}),
          AppButton.destructive(label: 'C', onPressed: () {}),
        ]),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  testWidgets('AppTextField.password obscures and toggles', (tester) async {
    await pumpThemed(tester, const AppTextField.password());
    EditableText editable() => tester.widget<EditableText>(find.byType(EditableText));
    expect(editable().obscureText, isTrue);
    expect(editable().autocorrect, isFalse);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(editable().obscureText, isFalse);
  });

  testWidgets('AppCard is tappable', (tester) async {
    var taps = 0;
    await pumpThemed(tester, AppCard(onTap: () => taps++, child: const Text('Card')));
    await tester.tap(find.text('Card'));
    expect(taps, 1);
  });

  testWidgets('AppErrorState shows only the safe message and retries', (tester) async {
    var retries = 0;
    await pumpThemed(tester, AppErrorState(failure: const NetworkFailure(), onRetry: () => retries++));
    expect(find.text("You're offline"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('AppEmptyState renders its action', (tester) async {
    var taps = 0;
    await pumpThemed(
      tester,
      AppEmptyState(title: 'Nothing here', message: 'Start practising.', actionLabel: 'Start', onAction: () => taps++),
    );
    await tester.tap(find.text('Start'));
    expect(taps, 1);
  });

  testWidgets('BrandLogo is labelled with the product name', (tester) async {
    await pumpThemed(tester, const BrandLogo());
    expect(find.byKey(const ValueKey('brand-logo')), findsOneWidget);
    expect(find.bySemanticsLabel('Hermione logo'), findsOneWidget);
  });

  testWidgets('AppLoadingView shows its message', (tester) async {
    await pumpThemed(tester, const AppLoadingView(message: 'Loading lessons'));
    expect(find.text('Loading lessons'), findsOneWidget);
  });
}
