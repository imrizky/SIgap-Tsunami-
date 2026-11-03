import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationSettingsAction { app, deviceLocation }

enum DeviceLocationErrorKind {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timedOut,
  unavailable,
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.kind, this.message, {this.settingsAction});

  final DeviceLocationErrorKind kind;
  final String message;
  final LocationSettingsAction? settingsAction;

  @override
  String toString() => message;
}

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracyMeters;
}

class DeviceLocationService {
  const DeviceLocationService();

  Future<DeviceLocation> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const DeviceLocationException(
          DeviceLocationErrorKind.serviceDisabled,
          'Layanan lokasi HP belum aktif. Aktifkan GPS lalu coba lagi.',
          settingsAction: LocationSettingsAction.deviceLocation,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const DeviceLocationException(
          DeviceLocationErrorKind.permissionDeniedForever,
          'Izin lokasi diblokir. Buka pengaturan aplikasi untuk mengizinkannya.',
          settingsAction: LocationSettingsAction.app,
        );
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw const DeviceLocationException(
          DeviceLocationErrorKind.permissionDenied,
          'Izin lokasi belum diberikan. Izinkan lokasi saat aplikasi digunakan.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        accuracyMeters: position.hasAccuracy ? position.accuracy : null,
      );
    } on DeviceLocationException {
      rethrow;
    } on TimeoutException {
      throw const DeviceLocationException(
        DeviceLocationErrorKind.timedOut,
        'Lokasi belum ditemukan setelah 25 detik. Coba di area yang lebih terbuka atau isi koordinat manual.',
      );
    } on LocationServiceDisabledException {
      throw const DeviceLocationException(
        DeviceLocationErrorKind.serviceDisabled,
        'Layanan lokasi HP belum aktif. Aktifkan GPS lalu coba lagi.',
        settingsAction: LocationSettingsAction.deviceLocation,
      );
    } on PermissionDeniedException {
      throw const DeviceLocationException(
        DeviceLocationErrorKind.permissionDenied,
        'Izin lokasi belum diberikan. Izinkan lokasi saat aplikasi digunakan.',
      );
    } catch (_) {
      throw const DeviceLocationException(
        DeviceLocationErrorKind.unavailable,
        'Lokasi otomatis tidak tersedia. Periksa GPS atau masukkan koordinat manual.',
      );
    }
  }

  Future<bool> openSettings(LocationSettingsAction action) =>
      action == LocationSettingsAction.app
      ? Geolocator.openAppSettings()
      : Geolocator.openLocationSettings();
}
