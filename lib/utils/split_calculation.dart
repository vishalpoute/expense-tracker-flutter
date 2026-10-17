double? parseExpenseTotal(String text) {
  final value = double.tryParse(text.trim());
  return value != null && value.isFinite && value > 0 ? value : null;
}

double calculateEqualShare(String text, int peopleCount) {
  final total = parseExpenseTotal(text);
  if (total == null || peopleCount <= 0) return 0;
  return total / peopleCount;
}
