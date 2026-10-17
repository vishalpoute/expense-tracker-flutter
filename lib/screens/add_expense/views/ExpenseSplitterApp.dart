import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Person {
  String email;
  TextEditingController controller;

  Person({required this.email}) : controller = TextEditingController(text: email);
}

class ExpenseSplitterPage extends StatefulWidget {
  const ExpenseSplitterPage({Key? key}) : super(key: key);

  @override
  _ExpenseSplitterPageState createState() => _ExpenseSplitterPageState();
}

class _ExpenseSplitterPageState extends State<ExpenseSplitterPage> {
  final _formKey = GlobalKey<FormState>();
  final _expenseController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Person> _people = [Person(email: '')];
  List<String> _recentEmails = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _deviceId;
  bool _isLoading = false;
  double _splitAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDeviceIdAndEmails();
  }

  void _calculateSplitAmount() {
    if (_expenseController.text.isNotEmpty) {
      final totalAmount = double.parse(_expenseController.text);
      setState(() {
        _splitAmount = totalAmount / _people.length;
      });
    }
  }

  void _addPerson() {
    setState(() {
      _people.add(Person(email: ''));
      _calculateSplitAmount();
    });
  }

  void _removePerson(int index) {
    if (_people.length > 1) {
      setState(() {
        _people.removeAt(index);
        _calculateSplitAmount();
      });
    }
  }

  Future<void> _loadDeviceIdAndEmails() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id') ?? const Uuid().v4();
    await prefs.setString('device_id', _deviceId!);
    _recentEmails = prefs.getStringList('recent_emails') ?? [];
    setState(() {});
  }

  Future<void> _saveRecentEmails() async {
    final prefs = await SharedPreferences.getInstance();
    final Set<String> uniqueEmails = {};

    for (var person in _people) {
      if (person.email.isNotEmpty) {
        uniqueEmails.add(person.email);
      }
    }

    _recentEmails = [...uniqueEmails, ..._recentEmails]
        .take(5)
        .toList();

    await prefs.setStringList('recent_emails', _recentEmails);
  }

  Future<void> _sendEmailToAll() async {
    // Notifications require a trusted server; client apps must not hold SMTP credentials.
    throw StateError('Email notifications require secure server-side configuration.');
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final expense = double.parse(_expenseController.text);
      final description = _descriptionController.text.trim();
      final emails = _people.map((p) => p.email).toList();
      final splitAmount = expense / emails.length;

      // Save to Firebase
      await _firestore.collection('expenses').add({
        'amount': expense,
        'split_amount': splitAmount,
        'emails': emails,
        'description': description,
        'device_id': _deviceId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending'
      });

      // Save emails to recent list
      await _saveRecentEmails();

      // Send email notifications
      try {
        await _sendEmailToAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved and emails sent successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense saved but failed to send some emails: $e')),
        );
      }

      // Clear form
      _expenseController.clear();
      _descriptionController.clear();
      setState(() {
        _people = [Person(email: '')];
        _splitAmount = 0.0;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving expense: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Person Expense Splitter'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _expenseController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Amount (\$)',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _calculateSplitAmount();
                            }
                          },
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Please enter an amount';
                            if (double.tryParse(value!) == null) return 'Please enter a valid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Please enter a description';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'People to Split With',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Split Amount: \$${_splitAmount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._people.asMap().entries.map((entry) {
                          final index = entry.key;
                          final person = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: person.controller,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Person ${index + 1} Email',
                                      prefixIcon: const Icon(Icons.email),
                                      suffixIcon: _recentEmails.isNotEmpty
                                          ? PopupMenuButton<String>(
                                        icon: const Icon(Icons.history),
                                        onSelected: (String value) {
                                          setState(() {
                                            person.controller.text = value;
                                            person.email = value;
                                          });
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return _recentEmails.map((String email) {
                                            return PopupMenuItem<String>(
                                              value: email,
                                              child: Text(email),
                                            );
                                          }).toList();
                                        },
                                      )
                                          : null,
                                    ),
                                    onChanged: (value) {
                                      person.email = value;
                                    },
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Please enter an email';
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (_people.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.red,
                                    onPressed: () => _removePerson(index),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context).colorScheme.tertiary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton.icon(

                            onPressed: _addPerson,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Add Person', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: _isLoading ? null : _saveExpense,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Split Expense', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                // Additional widgets can be added here
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _expenseController.dispose();
    _descriptionController.dispose();
    for (var person in _people) {
      person.controller.dispose();
    }
    super.dispose();
  }
}
