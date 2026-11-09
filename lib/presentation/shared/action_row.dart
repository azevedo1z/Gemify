import 'package:flutter/material.dart';

class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.label,
    required this.onTap,
    this.destructive = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: destructive ? scheme.error : scheme.primary),
      ),
      onTap: onTap,
    );
  }
}
