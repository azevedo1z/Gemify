import 'package:meta/meta.dart';

@immutable
final class Money implements Comparable<Money> {
  const Money(this.cents);

  static const zero = Money(0);
  static const max = Money(99999999999);

  final int cents;

  bool get isNegative => cents < 0;

  bool get isPositive => cents > 0;

  Money operator +(Money other) => Money(cents + other.cents);

  Money operator -(Money other) => Money(cents - other.cents);

  bool operator <(Money other) => cents < other.cents;

  bool operator <=(Money other) => cents <= other.cents;

  bool operator >(Money other) => cents > other.cents;

  bool operator >=(Money other) => cents >= other.cents;

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money($cents)';
}

extension MoneyTotal on Iterable<Money> {
  Money get total => fold(Money.zero, (sum, amount) => sum + amount);
}
