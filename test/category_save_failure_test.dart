import 'dart:async';
import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/create_categorybloc/create_category_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/views/category_creation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class CategoryRepository implements ExpenseRepository {
  int attempts = 0;
  String? savedName;
  Completer<void> pending = Completer<void>();
  @override
  Future<void> createCategory(Category category) {
    attempts++;
    savedName = category.name;
    return pending.future;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('blank category names are rejected and valid names are trimmed', (tester) async {
    final repository = CategoryRepository();
    final bloc = CreateCategoryBloc(repository);
    addTearDown(bloc.close);
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
        TextButton(onPressed: () => getCategoryCreation(context), child: const Text('Create')),
      ))),
    ));
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    for (final name in ['', '   ']) {
      await tester.enterText(find.byType(TextFormField).first, name);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repository.attempts, 0);
      expect(find.text('Enter a category name.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextFormField).first, '  Food  ');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(repository.attempts, 1);
    expect(repository.savedName, 'Food');
    repository.pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('failed category save preserves form and allows retry', (tester) async {
    final repository = CategoryRepository();
    final bloc = CreateCategoryBloc(repository);
    addTearDown(bloc.close);
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
        TextButton(onPressed: () => getCategoryCreation(context), child: const Text('Create')),
      ))),
    ));
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Food');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.pending.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save category. Please try again.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Food'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    repository.pending = Completer<void>();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(repository.attempts, 2);
    repository.pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Create a Category'), findsNothing);
  });
}
