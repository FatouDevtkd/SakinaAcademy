import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_ac/screens/al_akhdari_screen.dart';
import 'package:sakina_ac/screens/admin_screen.dart';

void main() {
  testWidgets('Al Akhdari screen lists all 13 audio lessons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AlAkhdariScreen()),
    );

    expect(AlAkhdariScreen.episodes, hasLength(13));
    expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    expect(find.text('Épisode 1 : Introduction à Al Akhdari'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Épisode 13 : Synthèse et révision'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Épisode 13 : Synthèse et révision'), findsOneWidget);
  });

  testWidgets('Admin dashboard shows its available management sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdminDashboard())),
    );

    expect(find.text('Administratrices autorisées'), findsOneWidget);
    expect(find.text('Déposer et publier des cours'), findsOneWidget);
    expect(find.text('Créer des questionnaires'), findsOneWidget);
  });
}
