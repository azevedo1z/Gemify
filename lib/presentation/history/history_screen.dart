import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offmoney/application/month_repository.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/providers.dart';
import 'package:offmoney/presentation/shared/formatters.dart';
import 'package:offmoney/presentation/shared/grouped_section.dart';
import 'package:offmoney/presentation/shared/month_view.dart';
import 'package:offmoney/presentation/shared/share_text.dart';
import 'package:offmoney/presentation/theme/metrics.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
      body: switch (ref.watch(closedMonthsProvider)) {
        AsyncData(value: final months) when months.isEmpty => Center(
          child: Text(
            l10n.historyEmpty,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        AsyncData(value: final months) => ListView(
          padding: const EdgeInsets.only(top: Metrics.inset),
          children: [
            GroupedSection(
              children: [
                for (final month in months) _HistoryTile(month: month),
              ],
            ),
          ],
        ),
        AsyncError() => Center(child: Text(l10n.loadFailed)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.month});

  final MonthOverview month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = month.summary;
    final balance = summary.balance ?? Money.zero;
    return ListTile(
      title: Text(formatReference(month.reference, l10n)),
      subtitle: Text(
        l10n.historyLine(
          formatMoney(summary.income ?? Money.zero),
          formatMoney(summary.totalExpenses),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMoney(balance),
            style: balance.isNegative
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ClosedMonthScreen(monthId: month.id),
        ),
      ),
    );
  }
}

class ClosedMonthScreen extends ConsumerWidget {
  const ClosedMonthScreen({required this.monthId, super.key});

  final int monthId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(monthProvider(monthId))) {
      AsyncData(value: final month) => Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: l10n.share,
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: shareText(month, l10n)),
              ),
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ],
        ),
        body: MonthView(month: month),
        bottomNavigationBar: AuditBar(summary: month.summary),
      ),
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.loadFailed)),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}
