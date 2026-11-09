import 'package:flutter/material.dart';
import 'package:offmoney/presentation/shared/money_input.dart';

class MoneyField extends StatelessWidget {
  const MoneyField({
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    enabled: enabled,
    keyboardType: TextInputType.number,
    inputFormatters: [MoneyInputFormatter()],
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: hint == null ? null : FloatingLabelBehavior.always,
      errorText: errorText,
    ),
  );
}
