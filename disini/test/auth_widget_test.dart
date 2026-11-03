import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_tsunami_flutter/app/app.dart';
import 'package:sigap_tsunami_flutter/core/storage/token_store.dart';
import 'package:sigap_tsunami_flutter/features/auth/auth_page.dart';
import 'package:sigap_tsunami_flutter/features/emergency/emergency_page.dart';
import 'package:sigap_tsunami_flutter/features/auth/welcome_page.dart';
import 'package:sigap_tsunami_flutter/features/home/home_page.dart';
import 'package:sigap_tsunami_flutter/features/information/information_pages.dart';
import 'package:sigap_tsunami_flutter/models/api_record.dart';
import 'package:sigap_tsunami_flutter/models/app_user.dart';
import 'package:sigap_tsunami_flutter/services/device_location_service.dart';
import 'package:sigap_tsunami_flutter/services/sigap_service.dart';

void main() {
  testWidgets('SOS page automatically fills coordinates from a location fix', (
    tester,
  ) async {
    final locationService = _FakeDeviceLocationService(
      DeviceLocation(
        latitude: -6.2,
        longitude: 106.816666,
        accuracyMeters: 15.6,
        timestamp: DateTime(2026, 10, 27, 10, 30),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EmergencyPage(
          service: _FakeSigapService(),
          locationService: locationService,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(locationService.calls, 1);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('sos-latitude')))
          .controller
          ?.text,
      '-6.2000000',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('sos-longitude')))
          .controller
          ?.text,
      '106.8166660',
    );
    expect(find.textContaining('akurasi sekitar ±16 m'), findsOneWidget);
  });

  testWidgets('successful SOS appears immediately in the visible history', (
    tester,
  ) async {
    final service = _FakeSigapService()
      ..emergencyResponse = {
        'id': 17,
        'report_code': 'SOS-TEST123',
        'incident_type': 'tsunami',
        'description': 'Butuh bantuan',
        'latitude': -6.2,
        'longitude': 106.8,
        'status': 'menunggu',
        'created_at': '2026-11-03T10:15:00.000000Z',
      };

    await tester.pumpWidget(
      MaterialApp(
        home: EmergencyPage(
          service: service,
          locationService: _FakeDeviceLocationService(
            DeviceLocation(
              latitude: -6.2,
              longitude: 106.8,
              accuracyMeters: 10,
              timestamp: DateTime(2026, 11, 3, 10, 15),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sos-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim S.O.S Sekarang'));
    await tester.pumpAndSettle();

    expect(service.emergencyCalls, 1);
    expect(find.text('Riwayat laporan SOS'), findsOneWidget);
    expect(find.text('SOS-TEST123'), findsOneWidget);
    expect(find.text('MENUNGGU'), findsOneWidget);
    expect(find.text('Butuh bantuan'), findsOneWidget);
  });

  testWidgets(
    'boot animation stays visible before opening the welcome screen',
    (tester) async {
      await tester.pumpWidget(
        SigapApp(
          tokenStore: _FakeTokenStore(),
          service: _FakeSigapService(),
          bootDuration: const Duration(seconds: 2),
        ),
      );

      expect(find.text('SIGAP TSUNAMI'), findsOneWidget);
      expect(find.text('Menyiapkan aplikasi...'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const ValueKey('welcome-login')), findsOneWidget);
    },
  );

  testWidgets('home clock updates using the device time', (tester) async {
    final service = _FakeSigapService();
    var mockTime = DateTime(2026, 10, 27, 10);
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          user: null,
          service: service,
          onNavigate: (_) {},
          onSos: () {},
          nowProvider: () =>
              mockTime = mockTime.add(const Duration(seconds: 1)),
        ),
      ),
    );
    await tester.pump();

    final before = tester
        .widget<Text>(find.byKey(const ValueKey('home-live-clock')))
        .data;
    await tester.pump(const Duration(seconds: 1));
    final after = tester
        .widget<Text>(find.byKey(const ValueKey('home-live-clock')))
        .data;

    expect(before, contains('•'));
    expect(after, isNot(before));
  });

  testWidgets('alerts refresh automatically every 30 seconds', (tester) async {
    final service = _FakeSigapService();

    await tester.pumpWidget(
      MaterialApp(
        home: AlertsPage(
          service: service,
          authenticated: true,
          onLogin: () {},
          active: true,
        ),
      ),
    );
    await tester.pump();

    expect(service.alertListCalls, 1);
    expect(find.textContaining('otomatis tiap 30 detik'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    await tester.pump();

    expect(service.alertListCalls, 2);
  });

  testWidgets('alerts only fetch and poll while their tab is active', (
    tester,
  ) async {
    final service = _FakeSigapService();
    var active = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              TextButton(
                key: const ValueKey('toggle-alert-tab'),
                onPressed: () => setState(() => active = !active),
                child: const Text('Toggle tab'),
              ),
              Expanded(
                child: AlertsPage(
                  service: service,
                  authenticated: true,
                  onLogin: () {},
                  active: active,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(service.alertListCalls, 0);

    await tester.tap(find.byKey(const ValueKey('toggle-alert-tab')));
    await tester.pump();
    await tester.pump();
    expect(service.alertListCalls, 1);

    await tester.tap(find.byKey(const ValueKey('toggle-alert-tab')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    expect(service.alertListCalls, 1);
  });

  testWidgets('SigapApp opens the login page from its welcome screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SigapApp(
        tokenStore: _FakeTokenStore(),
        service: _FakeSigapService(),
        bootDuration: Duration.zero,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('welcome-login')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Masuk ke Sigap Tsunami'), findsOneWidget);
  });

  testWidgets('SigapApp opens registration from its welcome screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SigapApp(
        tokenStore: _FakeTokenStore(),
        service: _FakeSigapService(),
        bootDuration: Duration.zero,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('welcome-register')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Daftar Akun'), findsOneWidget);
  });

  testWidgets('welcome screen opens login and registration entry points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var loginOpened = false;
    var registrationOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: WelcomePage(
          onLogin: () => loginOpened = true,
          onRegister: () => registrationOpened = true,
          onContinueAsGuest: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('welcome-login')));
    await tester.tap(find.byKey(const ValueKey('welcome-register')));

    expect(loginOpened, isTrue);
    expect(registrationOpened, isTrue);
  });

  testWidgets('login form validates and submits to the login service', (
    tester,
  ) async {
    final service = _FakeSigapService();
    await _openAuth(tester, service);

    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pump();
    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(service.loginCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'warga@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(service.loginCalls, 1);
    expect(service.lastEmail, 'warga@example.com');
    expect(find.text('AUTH_RESULT: Warga'), findsOneWidget);
  });

  testWidgets('registration toggle and submit call the register service', (
    tester,
  ) async {
    final service = _FakeSigapService();
    await _openAuth(tester, service);

    await tester.tap(find.byKey(const ValueKey('auth-mode-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Akun'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('auth-name')),
      'Siti Warga',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'siti@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirm')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();

    expect(service.registerCalls, 1);
    expect(service.lastName, 'Siti Warga');
    expect(service.lastEmail, 'siti@example.com');
    expect(find.text('AUTH_RESULT: Warga'), findsOneWidget);
  });
}

Future<void> _openAuth(WidgetTester tester, _FakeSigapService service) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey('open-auth'),
              onPressed: () async {
                final user = await Navigator.of(context).push<AppUser>(
                  MaterialPageRoute(builder: (_) => AuthPage(service: service)),
                );
                if (context.mounted && user != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('AUTH_RESULT: ${user.roleLabel}')),
                  );
                }
              },
              child: const Text('Open auth'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-auth')));
  await tester.pumpAndSettle();
}

class _FakeSigapService extends Fake implements SigapService {
  int loginCalls = 0;
  int registerCalls = 0;
  int alertListCalls = 0;
  int emergencyCalls = 0;
  Map<String, dynamic> emergencyResponse = {};
  String? lastName;
  String? lastEmail;

  @override
  Future<List<ApiRecord>> list(String path) async {
    if (path == 'alerts') alertListCalls++;
    return const [];
  }

  @override
  Future<List<ApiRecord>> myReports() async => const [];

  @override
  Future<Map<String, dynamic>> sendEmergency({
    required String incidentType,
    required String description,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    emergencyCalls++;
    return emergencyResponse;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    loginCalls++;
    lastEmail = email;
    return const AppUser(
      id: 1,
      name: 'Pengguna Uji',
      email: 'uji@example.com',
      role: 'warga',
    );
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    registerCalls++;
    lastName = name;
    lastEmail = email;
    return const AppUser(
      id: 1,
      name: 'Pengguna Uji',
      email: 'uji@example.com',
      role: 'warga',
    );
  }
}

class _FakeDeviceLocationService extends DeviceLocationService {
  _FakeDeviceLocationService(this.location);

  final DeviceLocation location;
  int calls = 0;

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    calls++;
    return location;
  }
}

class _FakeTokenStore extends Fake implements TokenStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> clear() async {}

  @override
  Future<void> save(String token) async {}
}
