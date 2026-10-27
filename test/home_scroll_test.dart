import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/screens/home/views/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long category names fit beside transaction amounts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final expense = Expense.empty;
    expense.amount = 12345;
    expense.category = Category(categoryId: 'long', name: 'A very long category name that must fit on a phone', totalExpenses: 0, icon: 'food', color: 0);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MainScreen([expense]))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(expense.category.name), 200, scrollable: find.byType(Scrollable));
    expect(tester.takeException(), isNull);
    expect(find.text(r'$12345.00'), findsOneWidget);
    final label = tester.widget<Text>(find.text(expense.category.name));
    expect(label.overflow, TextOverflow.ellipsis);
  });

  for (final size in [const Size(320, 800), const Size(360, 800), const Size(800, 600), const Size(600, 320)]) {
    testWidgets('home content scrolls at $size without losing transactions', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final expenses = List.generate(30, (index) {
        final expense = Expense.empty;
        expense.amount = index + 1;
        expense.category = Category(categoryId: '$index', name: 'Item $index', totalExpenses: 0, icon: 'food', color: 0);
        return expense;
      });
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: MainScreen(expenses))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Item 29'), 300, scrollable: find.byType(Scrollable));
      await tester.pumpAndSettle();
      expect(find.text('Item 29'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
