import 'package:equatable/equatable.dart';

import '../../../../core/domain/money.dart';

/// The person using the app on this device.
final class UserProfile extends Equatable {
  const UserProfile({
    required this.ownerId,
    required this.displayName,
    required this.currency,
    required this.createdAt,
  });

  /// Owner id for books kept only on this device (no cloud account).
  static const localOwnerId = 'device';

  static const nameLength = 40;

  /// Whose books to open. Books are stored per owner.
  final String ownerId;
  final String displayName;

  /// Currency for every amount in this user's books. Fixed after setup so
  /// existing amounts are never reinterpreted.
  final Currency currency;
  final DateTime createdAt;

  /// The first word of [displayName], for greetings.
  String get firstName {
    final trimmed = displayName.trim();
    final space = trimmed.indexOf(' ');
    return space < 0 ? trimmed : trimmed.substring(0, space);
  }

  UserProfile copyWith({String? displayName}) => UserProfile(
    ownerId: ownerId,
    displayName: displayName ?? this.displayName,
    currency: currency,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [ownerId, displayName, currency, createdAt];
}
