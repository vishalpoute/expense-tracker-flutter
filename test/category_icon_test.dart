import 'package:expenses_tracker/widgets/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final name in ['', 'missing-category']) {
    testWidgets('missing category image $name shows a fallback', (tester) async {
      await tester.pumpWidget(MaterialApp(home: CategoryIcon(name: name, color: Colors.white)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.category)).color, Colors.white);
    });
  }

  testWidgets('valid category images still render', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CategoryIcon(name: 'food')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.category), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
  });
}
