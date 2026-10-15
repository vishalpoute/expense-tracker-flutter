import 'package:expense_repository/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new expense drafts do not overwrite earlier expenses', () {
    final first = Expense.empty;
    first.expenseId = 'saved-id';
    first.amount = 120;
    first.date = DateTime(2026, 10, 1);
    first.category = Category(
      categoryId: 'food', name: 'Food', totalExpenses: 0, icon: 'food', color: 0,
    );

    final second = Expense.empty;
    expect(identical(first, second), isFalse);
    expect(second.expenseId, isEmpty);
    expect(second.amount, 0);
    expect(second.category.categoryId, isEmpty);
    expect(second.date.isAfter(DateTime(2026, 10, 1)), isTrue);
    second.expenseId = 'new-id';
    second.amount = 50;

    expect(first.expenseId, 'saved-id');
    expect(first.amount, 120);
    expect(first.date, DateTime(2026, 10, 1));
    expect(first.category.categoryId, 'food');
  });
}
