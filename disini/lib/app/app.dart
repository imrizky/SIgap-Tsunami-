import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../models/app_user.dart';
import '../services/sigap_service.dart';
import '../features/auth/auth_page.dart';
import '../features/auth/welcome_page.dart';
import '../features/emergency/emergency_page.dart';
import '../features/home/home_page.dart';
import '../features/information/information_pages.dart';
import '../features/profile/profile_page.dart';
import '../features/splash/boot_splash_page.dart';

class SigapApp extends StatefulWidget {
  const SigapApp({
    super.key,
    this.tokenStore,
    this.service,
    this.bootDuration = const Duration(milliseconds: 2200),
  });

  @visibleForTesting
  final TokenStore? tokenStore;

  @visibleForTesting
  final SigapService? service;

  @visibleForTesting
  final Duration bootDuration;

  @override
  State<SigapApp> createState() => _SigapAppState();
}

class _SigapAppState extends State<SigapApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final _tokens = widget.tokenStore ?? TokenStore();
  late final _service =
      widget.service ?? SigapService(ApiClient(_tokens), _tokens);
  AppUser? _user;
  bool _checkingSession = true;
  bool _bootAnimationDone = false;
  bool _guestMode = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _finishBootAnimation();
  }

  Future<void> _finishBootAnimation() async {
    await Future<void>.delayed(widget.bootDuration);
    if (mounted) setState(() => _bootAnimationDone = true);
  }

  Future<void> _restoreSession() async {
    try {
      if (await _tokens.read() != null) {
        _user = await _service.currentUser();
      }
    } catch (_) {
      await _tokens.clear();
    }
    if (mounted) setState(() => _checkingSession = false);
  }

  Future<void> _openAuth({bool initialRegister = false}) async {
    final user = await _navigatorKey.currentState!.push<AppUser>(
      MaterialPageRoute(
        builder: (_) =>
            AuthPage(service: _service, initialRegister: initialRegister),
      ),
    );
    if (user != null && mounted) {
      setState(() => _user = user);
    }
  }

  Future<void> _logout() async {
    try {
      await _service.logout();
      if (mounted) {
        setState(() {
          _user = null;
          _guestMode = true;
          _tab = 0;
        });
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Anda telah keluar dari akun.')),
        );
      }
    } catch (e) {
      if (mounted) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Logout: $e')),
        );
      }
    }
  }

  Future<void> _openEmergency() async {
    if (_user == null) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan masuk terlebih dahulu untuk mengirim laporan SOS.',
          ),
        ),
      );
      await _openAuth();
      if (_user == null) return;
    }
    if (!mounted) return;
    await _navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => EmergencyPage(service: _service)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1E60EC);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      title: 'Sigap Tsunami',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
      home: !_bootAnimationDone || _checkingSession
          ? const BootSplashPage()
          : _user == null && !_guestMode
          ? WelcomePage(
              onLogin: () => _openAuth(),
              onRegister: () => _openAuth(initialRegister: true),
              onContinueAsGuest: () => setState(() => _guestMode = true),
            )
          : Scaffold(
              body: IndexedStack(
                index: _tab,
                children: [
                  HomePage(
                    user: _user,
                    service: _service,
                    onNavigate: (i) => setState(() => _tab = i),
                    onSos: _openEmergency,
                    active: _tab == 0,
                  ),
                  EvacuationMapPage(
                    service: _service,
                    authenticated: _user != null,
                    onLogin: _openAuth,
                    active: _tab == 1,
                  ),
                  AlertsPage(
                    service: _service,
                    authenticated: _user != null,
                    onLogin: _openAuth,
                    active: _tab == 2,
                  ),
                  ProfilePage(
                    user: _user,
                    onLogin: _openAuth,
                    onLogout: _logout,
                    service: _service,
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFDBEAFE),
                elevation: 4,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home, color: primary),
                    label: 'Beranda',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.location_on_outlined),
                    selectedIcon: Icon(Icons.location_on, color: primary),
                    label: 'Peta',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_none_outlined),
                    selectedIcon: Icon(Icons.notifications, color: primary),
                    label: 'Peringatan',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person, color: primary),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
    );
  }
}
