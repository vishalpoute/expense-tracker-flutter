import 'package:expense_repository/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('category drafts and expense defaults are independent', () {
    final first = Category.empty;
    first.categoryId = 'saved-category';
    first.name = 'Food';
    first.icon = 'food';
    first.color = 123;
    final second = Category.empty;
    expect(identical(first, second), isFalse);
    expect(second.categoryId, isEmpty);
    expect(second.name, isEmpty);
    expect(second.icon, isEmpty);
    expect(second.color, 0);
    second.name = 'Travel';
    expect(first.name, 'Food');
    final firstExpense = Expense.empty;
    final secondExpense = Expense.empty;
    firstExpense.category.name = 'Draft only';
    expect(secondExpense.category.name, isEmpty);
    expect(Category.empty.name, isEmpty);
  });

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
