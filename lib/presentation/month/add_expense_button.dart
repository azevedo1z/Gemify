import 'package:flutter/material.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/shared/labels.dart';
import 'package:offmoney/presentation/theme/metrics.dart';

class AddExpenseButton extends StatefulWidget {
  const AddExpenseButton({required this.onPick, super.key});

  final ValueChanged<ExpenseCategory> onPick;

  @override
  State<AddExpenseButton> createState() => _AddExpenseButtonState();
}

class _AddExpenseButtonState extends State<AddExpenseButton> {
  static const _menuGap = 8.0;
  static const _menuTransition = Duration(milliseconds: 150);

  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    tooltip: AppLocalizations.of(context).newExpense,
    onPressed: _chooseCategory,
    child: Icon(_menuOpen ? Icons.close_rounded : Icons.add_rounded),
  );

  Future<void> _chooseCategory() async {
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(
              context,
              rootNavigator: true,
            ).overlay!.context.findRenderObject()!
            as RenderBox;
    final buttonOrigin = button.localToGlobal(Offset.zero, ancestor: overlay);
    final rightInset = overlay.size.width - buttonOrigin.dx + _menuGap;
    final bottomInset =
        overlay.size.height - buttonOrigin.dy - button.size.height;
    setState(() => _menuOpen = true);
    final category = await showGeneralDialog<ExpenseCategory>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: _menuTransition,
      pageBuilder: (_, animation, _) => _AnchoredMenu(
        rightInset: rightInset,
        bottomInset: bottomInset,
        animation: animation,
      ),
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (category != null) widget.onPick(category);
  }
}

class _AnchoredMenu extends StatelessWidget {
  const _AnchoredMenu({
    required this.rightInset,
    required this.bottomInset,
    required this.animation,
  });

  static const _collapsedScale = 0.9;

  final double rightInset;
  final double bottomInset;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final appearing = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return Stack(
      children: [
        Positioned(
          left: Metrics.inset,
          right: rightInset,
          bottom: bottomInset,
          child: Align(
            alignment: Alignment.bottomRight,
            child: FadeTransition(
              opacity: appearing,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: _collapsedScale,
                  end: 1,
                ).animate(appearing),
                alignment: Alignment.bottomRight,
                child: const _CategoryMenu(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryMenu extends StatelessWidget {
  const _CategoryMenu();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final menuTheme = PopupMenuTheme.of(context);
    return Material(
      color: menuTheme.color,
      shape: menuTheme.shape,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final category in ExpenseCategory.values) ...[
              if (category != ExpenseCategory.values.first) const Divider(),
              _CategoryRow(
                icon: _categoryIcon(category),
                label: newExpenseTitle(category, l10n),
                onTap: () => Navigator.of(context).pop(category),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(ExpenseCategory category) => switch (category) {
    ExpenseCategory.fixed => Icons.event_repeat_rounded,
    ExpenseCategory.installment => Icons.credit_card_rounded,
    ExpenseCategory.variable => Icons.receipt_long_rounded,
  };
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const _iconGap = 12.0;

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Metrics.rowHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Metrics.inset),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: _iconGap),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
