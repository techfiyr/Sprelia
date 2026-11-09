import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speakdaily/core/branding/app_brand.dart';
import 'package:speakdaily/core/routing/app_router.dart';

import '../../helpers/pump_app.dart';

GoRouter routerOf(WidgetTester tester) {
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  return container.read(routerProvider);
}

void main() {
  testWidgets('starts on Welcome with the brand tagline', (tester) async {
    await pumpSpreliaApp(tester);
    expect(find.text(AppBrand.tagline), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Get Started opens the five-tab shell', (tester) async {
    await pumpSpreliaApp(tester);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Home', 'Practice', 'Learn', 'Progress', 'Profile']) {
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)), findsOneWidget);
    }
    expect(find.text('Start Speaking'), findsOneWidget);
  });

  testWidgets('tabs switch content', (tester) async {
    await pumpSpreliaApp(tester);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Learn')));
    await tester.pumpAndSettle();
    expect(find.text('Mistake Vault'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Practice')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a tutor'), findsOneWidget);
  });

  testWidgets('tutor flow is pushed full-screen above the tabs', (tester) async {
    await pumpSpreliaApp(tester);
    routerOf(tester).go(AppRoutes.home);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Speaking'));
    await tester.pumpAndSettle();
    expect(find.text('Get ready'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('unknown routes show a recoverable not-found screen', (tester) async {
    await pumpSpreliaApp(tester);
    routerOf(tester).go('/definitely/not/a/route');
    await tester.pumpAndSettle();
    expect(find.byType(RouteNotFoundScreen), findsOneWidget);
    await tester.tap(find.text('Go to Home'));
    await tester.pumpAndSettle();
    expect(find.text('Start Speaking'), findsOneWidget);
  });

  test('route helpers encode path parameters', () {
    expect(AppRoutes.prepare('emma'), '/prepare/emma');
    expect(AppRoutes.feedback('a/b?c'), '/feedback/a%2Fb%3Fc');
  });
}
