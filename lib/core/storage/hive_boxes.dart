/// Hive box names. Changing a name orphans existing on-device data, so treat
/// these as a persistence format.
abstract final class HiveBoxes {
  /// Small device-level preferences (`Box<String>`). Unencrypted: holds only
  /// non-sensitive UI settings.
  static const preferences = 'preferences';

  /// The local user profile (`Box<String>`, encrypted).
  static const profile = 'profile';

  /// Per-owner ledger collections (`Box<String>` of JSON, encrypted). Each
  /// owner gets separate boxes, so one user's books are never readable from
  /// another's session.
  static String ledger(String ownerId, String collection) =>
      'ledger_${ownerId.toLowerCase()}_$collection';
}
