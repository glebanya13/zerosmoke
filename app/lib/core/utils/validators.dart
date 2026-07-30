/// Returns true for a reasonably well-formed email address.
bool isValidEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
}
