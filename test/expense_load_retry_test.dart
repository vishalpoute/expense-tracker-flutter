import 'dart:async';
import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'package:expenses_tracker/screens/home/views/home_screen.dart';
import 'package:expenses_tracker/screens/home/views/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class RecoveringRepository implements ExpenseRepository {
  int attempts = 0;
  final pending = Completer<List<Expense>>();

  @override
  Future<List<Expense>> getExpenses() async {
    attempts++;
    if (attempts == 1) throw Exception('offline');
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('failed expense load can retry and show the loaded expenses', (tester) async {
    final repository = RecoveringRepository();
    final bloc = GetExpensesBloc(repository)..add(GetExpenses());
    addTearDown(bloc.close);
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load expenses. Please try again.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.attempts, 1);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(repository.attempts, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    repository.pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
