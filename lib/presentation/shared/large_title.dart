import 'package:flutter/material.dart';
import 'package:gemify/presentation/theme/metrics.dart';

class LargeTitle extends StatelessWidget {
  const LargeTitle({required this.text, this.tooltip, this.onTap, super.key});

  final String text;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onTap = this.onTap;
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: theme.textTheme.headlineLarge),
        if (onTap != null)
          Icon(Icons.expand_more_rounded, color: theme.colorScheme.primary),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Metrics.inset,
        0,
        Metrics.inset,
        Metrics.inset,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: onTap == null
            ? title
            : Tooltip(
                message: tooltip,
                child: InkWell(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(Metrics.radius),
                  ),
                  onTap: onTap,
                  child: title,
                ),
              ),
      ),
    );
  }
}
