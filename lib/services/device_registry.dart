import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceRegistryIdentity {
  const DeviceRegistryIdentity({
    required this.name,
    required this.enrollmentNumber,
  });

  final String name;
  final String enrollmentNumber;
}

class DeviceRegistry {
  DeviceRegistry._();

  static final instance = DeviceRegistry._();
  static const _channel = MethodChannel('channeli/app_info');
  static const _databaseId = 'checker-status';
  static const _app = 'placementv2';
  static const _collection = 'placement_devices';

  DateTime? _lastOpened;

  void endSession() {
    _lastOpened = null;
  }

  Future<void> signedIn(DeviceRegistryIdentity identity) async {
    await _write(identity, isSignIn: true);
  }

  Future<void> opened(DeviceRegistryIdentity? identity) async {
    if (identity == null) return;
    final now = DateTime.now();
    if (_lastOpened != null &&
        now.difference(_lastOpened!) < const Duration(seconds: 5)) {
      return;
    }
    _lastOpened = now;
    await _write(identity, isSignIn: false);
  }

  Future<void> _write(
    DeviceRegistryIdentity identity, {
    required bool isSignIn,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final enrollmentNumber = identity.enrollmentNumber.trim();
    final name = identity.name.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(enrollmentNumber) ||
        name.isEmpty ||
        name.length > 120) {
      return;
    }

    final nameSlug = name
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (nameSlug.isEmpty) return;

    try {
      final deviceIdHash = await _channel.invokeMethod<String>('androidIdHash');
      if (deviceIdHash == null ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(deviceIdHash)) {
        return;
      }

      SharedPreferences? preferences;
      try {
        preferences = await SharedPreferences.getInstance();
      } catch (_) {}
      final firstSeenKey = 'device_registry_' + _app + '_' + deviceIdHash;
      final includeFirstSeen = preferences?.getBool(firstSeenKey) != true;
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _databaseId,
      );
      final accountSlug =
          nameSlug.length > 150 ? nameSlug.substring(0, 150) : nameSlug;
      final account = enrollmentNumber + '_' + accountSlug;
      final accountReference = firestore.collection(_collection).doc(account);
      final deviceReference =
          accountReference.collection('devices').doc(deviceIdHash);
      final accountFields = <String, dynamic>{
        'name': name,
        'enrollmentNumber': enrollmentNumber,
        'lastSeenAt': FieldValue.serverTimestamp(),
        if (isSignIn) 'lastSignInAt': FieldValue.serverTimestamp(),
      };
      final deviceFields = <String, dynamic>{
        ...accountFields,
        'androidIdHash': deviceIdHash,
      };

      await _writeRecord(accountReference, accountFields, includeFirstSeen);
      await _writeRecord(deviceReference, deviceFields, includeFirstSeen);
      await preferences?.setBool(firstSeenKey, true);
    } catch (error) {
      debugPrint('[device registry] Firestore update failed (' +
          error.runtimeType.toString() +
          ')');
    }
  }

  Future<void> _writeRecord(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> fields,
    bool includeFirstSeen,
  ) async {
    final initial = <String, dynamic>{
      ...fields,
      if (includeFirstSeen) 'firstSeenAt': FieldValue.serverTimestamp(),
    };
    try {
      await reference.set(initial, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      final retry = <String, dynamic>{
        ...fields,
        if (!includeFirstSeen) 'firstSeenAt': FieldValue.serverTimestamp(),
      };
      await reference.set(retry, SetOptions(merge: true));
    }
  }
}
