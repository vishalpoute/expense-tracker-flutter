import 'dart:async';
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
