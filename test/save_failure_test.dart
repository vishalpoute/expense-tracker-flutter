import 'dart:async';
import 'package:intl/intl.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/views/add_expense.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingRepository implements ExpenseRepository {
  int attempts = 0;
  Completer<void> pending = Completer<void>();

  @override
  Future<List<Category>> getCategory() async => [];

  @override
  Future<void> createExpense(Expense expense) {
    attempts++;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('past expense dates can be selected', (tester) async {
    final repository = FailingRepository();
    final saveBloc = CreateExpenseBloc(repository);
    final categoriesBloc = GetCategoriesBloc(repository)..add(GetCategories());
    addTearDown(saveBloc.close);
    addTearDown(categoriesBloc.close);
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: saveBloc),
        BlocProvider.value(value: categoriesBloc),
      ],
      child: const MaterialApp(home: AddExpense()),
    ));
    await tester.pumpAndSettle();
    final dateField = find.byType(TextFormField).last;
    await tester.ensureVisible(dateField);
    await tester.tap(dateField);
    await tester.pumpAndSettle();
    final calendar = tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker));
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(calendar.firstDate.isAfter(yesterday), isFalse);
    calendar.onDateChanged(yesterday);
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text(DateFormat('dd/MM/yyyy').format(yesterday)), findsOneWidget);
  });

  testWidgets('invalid amounts show feedback without saving', (tester) async {
    final repository = FailingRepository();
    final saveBloc = CreateExpenseBloc(repository);
    final categoriesBloc = GetCategoriesBloc(repository)..add(GetCategories());
    addTearDown(saveBloc.close);
    addTearDown(categoriesBloc.close);
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: saveBloc),
        BlocProvider.value(value: categoriesBloc),
      ],
      child: const MaterialApp(home: AddExpense()),
    ));
    await tester.pumpAndSettle();
    for (final value in ['', 'abc', '1.5', '0', '-5', '999999999999999999999999999999']) {
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, value);
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a positive whole-number amount.'), findsOneWidget);
      expect(repository.attempts, 0);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('failed save shows feedback and allows retry', (tester) async {
    final repository = FailingRepository();
    final saveBloc = CreateExpenseBloc(repository);
    final categoriesBloc = GetCategoriesBloc(repository)..add(GetCategories());
    addTearDown(saveBloc.close);
    addTearDown(categoriesBloc.close);
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: saveBloc),
        BlocProvider.value(value: categoriesBloc),
      ],
      child: const MaterialApp(home: AddExpense()),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '25');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(repository.attempts, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.pending.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save expense. Please try again.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('25'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    repository.pending = Completer<void>();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(repository.attempts, 2);
    repository.pending.completeError(Exception('still offline'));
    await tester.pumpAndSettle();
  });
}
