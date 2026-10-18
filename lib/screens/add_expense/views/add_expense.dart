import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/views/category_creation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  TextEditingController expenseController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  late Expense expense;
  bool isLoading = false;

  @override
  void initState() {
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    expense = Expense.empty;
    expense.expenseId = const Uuid().v1();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateExpenseBloc, CreateExpenseState>(
      listener: (context, state) {
        if (state is CreateExpenseSuccess) {
          Navigator.pop(context, expense);
        } else if (state is CreateExpenseLoading) {
          setState(() {
            isLoading = true;
          });
        } else if (state is CreateExpenseFailure) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save expense. Please try again.')),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          body: BlocBuilder<GetCategoriesBloc, GetCategoriesState>(
            builder: (context, state) {
              if (state is GetCategoriesSuccess) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Add Expenses",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: TextFormField(
                            controller: expenseController,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const FaIcon(
                                FontAwesomeIcons.dollarSign,
                                size: 16,
                                color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: categoryController,
                          textAlignVertical: TextAlignVertical.center,
                          readOnly: true,
                          onTap: () {},
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: expense.category.categoryId.isEmpty
                                ? Colors.white
                                : Color(expense.category.color),
                            prefixIcon: expense.category.categoryId.isEmpty
                                ? const FaIcon(
                              FontAwesomeIcons.list,
                              size: 16,
                              color: Colors.grey,
                            )
                                : Image.asset(
                              'assets/${expense.category.icon}.png',
                              scale: 2,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () async {
                                final newCategory = await getCategoryCreation(context);
                                if (!mounted || newCategory == null) return;
                                setState(() {
                                  state.categories.insert(0, newCategory);
                                });
                              },
                              icon: const FaIcon(
                                FontAwesomeIcons.plus,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                            hintText: 'Category',
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          width: MediaQuery.of(context).size.width,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListView.builder(
                              itemCount: state.categories.length,
                              itemBuilder: (context, int i) {
                                return Card(
                                  child: ListTile(
                                    onTap: () {
                                      setState(() {
                                        expense.category = state.categories[i];
                                        categoryController.text = expense.category.name;
                                      });
                                    },
                                    leading: Image.asset(
                                      'assets/${state.categories[i].icon}.png',
                                      scale: 2,
                                    ),
                                    title: Text(state.categories[i].name),
                                    tileColor: Color(state.categories[i].color),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: dateController,
                          textAlignVertical: TextAlignVertical.center,
                          readOnly: true,
                          onTap: () async {
                            DateTime? newDate = await showDatePicker(
                              context: context,
                              initialDate: expense.date,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );

                            if (mounted && newDate != null) {
                              setState(() {
                                dateController.text = DateFormat('dd/MM/yyyy').format(newDate);
                                expense.date = newDate;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const FaIcon(
                              FontAwesomeIcons.clock,
                              size: 16,
                              color: Colors.grey,
                            ),
                            hintText: 'Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: kToolbarHeight,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : TextButton(
                            onPressed: () {
                              final amount = int.tryParse(expenseController.text.trim());
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter a positive whole-number amount.')),
                                );
                                return;
                              }
                              if (expense.category.categoryId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Choose a category before saving.')),
                                );
                                return;
                              }
                              expense.amount = amount;

                              context.read<CreateExpenseBloc>().add(CreateExpense(expense));
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontSize: 22, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is GetCategoriesFailure) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load categories.'),
                      TextButton(
                        onPressed: () => context.read<GetCategoriesBloc>().add(GetCategories()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
