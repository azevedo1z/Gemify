import 'package:flutter/material.dart';
import 'package:offmoney/presentation/theme/metrics.dart';

class LargeTitle extends StatelessWidget {
  const LargeTitle({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Metrics.inset,
      0,
      Metrics.inset,
      Metrics.inset,
    ),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, style: Theme.of(context).textTheme.headlineLarge),
    ),
  );
}
