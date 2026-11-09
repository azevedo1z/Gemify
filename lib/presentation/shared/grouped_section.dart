import 'package:flutter/material.dart';
import 'package:offmoney/presentation/theme/metrics.dart';

class GroupedSection extends StatelessWidget {
  const GroupedSection({
    required this.children,
    this.header,
    this.footer,
    super.key,
  });

  final Widget? header;
  final Widget? footer;
  final List<Widget> children;

  static const _labelInsets = EdgeInsets.symmetric(horizontal: Metrics.inset);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = this.header;
    final footer = this.footer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Metrics.inset,
        0,
        Metrics.inset,
        Metrics.sectionGap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: _labelInsets.copyWith(bottom: Metrics.headerGap),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.titleMedium,
                child: header,
              ),
            ),
          if (children.isNotEmpty)
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, child) in children.indexed) ...[
                    if (index > 0) const Divider(indent: Metrics.inset),
                    child,
                  ],
                ],
              ),
            ),
          if (footer != null)
            Padding(
              padding: _labelInsets.copyWith(top: Metrics.headerGap),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                child: footer,
              ),
            ),
        ],
      ),
    );
  }
}
