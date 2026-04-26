import 'package:flutter/material.dart';
import '../../design/farol_colors.dart' as tokens;

extension FarolSnackbar on BuildContext {
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: tokens.FarolColors.beam),
    );
  }

  void showErrorSnackBar(Object error) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text('$error'), backgroundColor: Colors.red.shade700),
    );
  }
}
