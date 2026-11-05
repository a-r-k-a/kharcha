import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Stores the profile as JSON in an encrypted box. A record that can't be
/// read is reported as a [StorageFailure] rather than treated as "no
/// profile", which would send the user back through setup over real data.
///
/// The box is opened on first use, so a keystore or disk error surfaces as
/// a failure the user can retry instead of a crash at launch.
final class HiveProfileRepository implements ProfileRepository {
  HiveProfileRepository(this._openBox);

  final Future<Box<String>> Function() _openBox;
  Box<String>? _box;

  Future<Box<String>> get _opened async => _box ??= await _openBox();

  static const _key = 'profile';
  static const _version = 1;

  @override
  Future<Result<UserProfile?>> load() => _guard('read', () async {
    final stored = (await _opened).get(_key);
    if (stored == null) return null;
    final profile = _decode(stored);
    if (profile == null) {
      throw const FormatException('Malformed profile record');
    }
    return profile;
  });

  @override
  Future<Result<void>> save(UserProfile profile) => _guard(
    'write',
    () async => (await _opened).put(
      _key,
      jsonEncode({
        'v': _version,
        'owner': profile.ownerId,
        'name': profile.displayName,
        'currency': profile.currency.code,
        'created': profile.createdAt.millisecondsSinceEpoch,
      }),
    ),
  );

  @override
  Future<Result<void>> clear() =>
      _guard('clear', () async => (await _opened).delete(_key));

  static UserProfile? _decode(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    if (json
        case {
          'v': final int v,
          'owner': final String owner,
          'name': final String name,
          'currency': final String code,
          'created': final int created,
        }
        when v <= _version && owner.isNotEmpty) {
      final currency = Currency.tryParse(code);
      if (currency == null) return null;
      return UserProfile(
        ownerId: owner,
        displayName: name,
        currency: currency,
        createdAt: DateTime.fromMillisecondsSinceEpoch(created, isUtc: true),
      );
    }
    return null;
  }

  Future<Result<T>> _guard<T>(
    String operation,
    Future<T> Function() body,
  ) async {
    try {
      return Ok(await body());
    } on HiveError catch (error, stackTrace) {
      return _fail(operation, error, stackTrace);
    } on FileSystemException catch (error, stackTrace) {
      return _fail(operation, error, stackTrace);
    } on FormatException catch (error, stackTrace) {
      return _fail(operation, error, stackTrace);
    } on PlatformException catch (error, stackTrace) {
      return _fail(operation, error, stackTrace);
    } on StateError catch (error, stackTrace) {
      return _fail(operation, error, stackTrace);
    }
  }

  Result<T> _fail<T>(String operation, Object error, StackTrace stackTrace) {
    developer.log(
      'Profile $operation failed',
      name: 'profile',
      error: error,
      stackTrace: stackTrace,
    );
    return Err(StorageFailure(cause: error));
  }
}
