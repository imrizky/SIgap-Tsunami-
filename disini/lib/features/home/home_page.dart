import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/api_record.dart';
import '../../models/app_user.dart';
import '../../services/sigap_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.service,
    required this.onNavigate,
    required this.onSos,
    this.nowProvider,
    this.active = true,
  });

  final AppUser? user;
  final SigapService service;
  final ValueChanged<int> onNavigate;
  final VoidCallback onSos;

  @visibleForTesting
  final DateTime Function()? nowProvider;

  final bool active;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<ApiRecord> _activeAlerts = [];
  bool _loadingAlerts = true;
  bool _alertsFailed = false;
  bool _alertRequestInFlight = false;
  DateTime _lastAlertFetch = DateTime.fromMillisecondsSinceEpoch(0);
  bool _appResumed = true;
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = _readNow();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = _readNow();
      if (widget.active && _appResumed) {
        setState(() => _now = now);
      }
      if (widget.active &&
          _appResumed &&
          widget.user != null &&
          now.difference(_lastAlertFetch) >= const Duration(seconds: 30)) {
        _fetchAlerts();
      }
    });
    if (widget.user != null) {
      _fetchAlerts();
    } else {
      _loadingAlerts = false;
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user == null && oldWidget.user != null) {
      _activeAlerts = [];
      _alertsFailed = false;
      _loadingAlerts = false;
    } else if (widget.user != null &&
        widget.active &&
        (oldWidget.user == null || !oldWidget.active)) {
      if (oldWidget.user == null) _loadingAlerts = true;
      _fetchAlerts();
    }
    if (widget.active) _now = _readNow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed && widget.active) {
      setState(() => _now = _readNow());
      if (widget.user != null) _fetchAlerts();
    }
  }

  DateTime _readNow() => widget.nowProvider?.call() ?? DateTime.now();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    if (widget.user == null || _alertRequestInFlight) return;
    _alertRequestInFlight = true;
    _lastAlertFetch = _readNow();
    try {
      final alerts = await widget.service.list('alerts');
      if (mounted) {
        setState(() {
          _activeAlerts = alerts
              .where((a) => a.status.toLowerCase() == 'aktif')
              .toList();
          _loadingAlerts = false;
          _alertsFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingAlerts = false;
          _alertsFailed = true;
        });
      }
    } finally {
      _alertRequestInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1E60EC);
    final hasActiveDanger = _activeAlerts.any(
      (a) =>
          a.severity.toLowerCase() == 'darurat' ||
          a.severity.toLowerCase() == 'siaga',
    );
    final statusKey = widget.user == null
        ? 'guest'
        : _loadingAlerts
        ? 'loading'
        : _alertsFailed
        ? 'failed'
        : hasActiveDanger
        ? 'danger'
        : 'clear';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // Ocean-inspired brand header.
          SliverAppBar(
            expandedHeight: 136,
            floating: false,
            pinned: true,
            backgroundColor: primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF073B66), Color(0xFF126D9B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.26),
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/sigap_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Sigap Tsunami',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            widget.user == null
                                ? 'Kesiapsiagaan Wilayah Pesisir'
                                : 'Halo, ${widget.user!.name.split(' ').first} (${widget.user!.roleLabel})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDateTime(_now),
                            key: const ValueKey('home-live-clock'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .76),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: .15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .18),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            widget.onNavigate(2), // Navigate to Info/Notifikasi
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, progress, child) => Opacity(
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - progress)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWelcomeHero(primary),
                    const SizedBox(height: 20),
                    _sectionHeading('KONDISI WILAYAH', 'Pembaruan keselamatan'),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 340),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .035),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(statusKey),
                        child: _buildStatusCard(primary, hasActiveDanger),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _sectionHeading('AKSI CEPAT', 'Siap saat dibutuhkan'),
                    const SizedBox(height: 12),

                    _SosHomeButton(onTap: widget.onSos),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _QuickMenuButton(
                            title: 'Peta Lokasi',
                            subtitle: 'Temukan jalur aman',
                            icon: Icons.location_on_outlined,
                            iconColor: primary,
                            bgColor: const Color(0xFFDBEAFE),
                            borderColor: const Color(0xFFBFDBFE),
                            onTap: () => widget.onNavigate(1), // ke Peta
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickMenuButton(
                            title: 'Peringatan',
                            subtitle: 'Info terkini wilayah',
                            icon: Icons.notifications_active_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFF3E8FF),
                            borderColor: const Color(0xFFE9D5FF),
                            onTap: () => widget.onNavigate(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // Section Informasi Tsunami (PDF Page 1)
                    _sectionHeading(
                      'BEKAL PENGETAHUAN',
                      'Langkah kecil, dampak besar',
                    ),
                    const SizedBox(height: 12),

                    _EducationTile(
                      icon: Icons.tsunami_outlined,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Kenali Tanda Tanda Tsunami',
                      subtitle:
                          'pelajari ciri ciri tsunami sebelum terjadi bencana',
                      onTap: () => _showGuideDetail(
                        context,
                        'Kenali Tanda-tanda Tsunami',
                        [
                          'Gempa bumi berkekuatan kuat atau berlangsung lebih dari 20 detik di wilayah dekat pantai.',
                          'Air laut tiba-tiba surut secara drastis hingga dasar laut terlihat.',
                          'Terdengar suara gemuruh keras seperti pesawat jet atau ledakan dari arah laut lepas.',
                          'Perilaku hewan laut dan pesisir yang gelisah atau menjauhi garis pantai.',
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    _EducationTile(
                      icon: Icons.backpack_outlined,
                      iconColor: const Color(0xFFEA580C),
                      title: 'Siapkan Tas Darurat',
                      subtitle: 'Apa saja yang di perlukan',
                      onTap: () => _showGuideDetail(
                        context,
                        'Isi Tas Siaga Bencana (Tas Darurat)',
                        [
                          'Air minum kemasan dan makanan tahan lama (minimal untuk 3 hari).',
                          'Kotak P3K, obat-obatan pribadi rutin, dan masker.',
                          'Senter tahan air beserta baterai cadangan.',
                          'Peluit untuk meminta bantuan jika terjebak.',
                          'Uang tunai secukupnya dan dokumen penting dalam plastik kedap air.',
                          'Pakaian ganti, selimut hangat, dan jas hujan.',
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    _EducationTile(
                      icon: Icons.directions_run_outlined,
                      iconColor: const Color(0xFF16A34A),
                      title: 'Tips Keselamatan',
                      subtitle: 'Langkah yang harus di lakukan saat bencana',
                      onTap: () => _showGuideDetail(
                        context,
                        'Langkah Keselamatan Saat Tsunami',
                        [
                          'Tetap tenang, jangan panik, dan segera tinggalkan daerah pantai.',
                          'Segera berlari ke tempat yang lebih tinggi (bukit, perbukitan, atau bangunan vertikal evakuasi tsunami).',
                          'Jangan menunggu sirene atau peringatan resmi jika tanda-tanda alam tsunami sudah terlihat.',
                          'Patuhi jalur evakuasi resmi yang telah ditandai petugas BPBD/SAR.',
                          'Jangan kembali ke pantai sebelum otoritas resmi menyatakan situasi aman sepenuhnya.',
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer Motivational Banner (PDF Page 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 38,
                            color: Color(0xFF1E60EC),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bersama Kita lebih siap',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'menghadapi Tsunami',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]} '
        '• $hour:$minute:$second';
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F5684),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHero(Color primary) {
    final firstName = widget.user?.name.trim().split(' ').first;
    return Container(
      height: 184,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B416B), Color(0xFF087E9B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF075985).withValues(alpha: .2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -54,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .1),
                  width: 24,
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: -34,
            child: Icon(
              Icons.waves_rounded,
              size: 158,
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .18),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.waves_rounded,
                        color: Color(0xFFB8F3FF),
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'SIAGA TSUNAMI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  firstName == null || firstName.isEmpty
                      ? 'Siap menghadapi\nsituasi darurat?'
                      : 'Tetap sigap,\n${firstName.trim()}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFFB8F3FF),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(_now),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .92),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 17,
            bottom: 17,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .26)),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Color primary, bool hasActiveDanger) {
    if (_loadingAlerts) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (hasActiveDanger) {
      final dangerAlert = _activeAlerts.firstWhere(
        (a) =>
            a.severity.toLowerCase() == 'darurat' ||
            a.severity.toLowerCase() == 'siaga',
      );
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'PERINGATAN DARURAT AKTIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              dangerAlert.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dangerAlert.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
            if (dangerAlert.source.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Sumber: ${dangerAlert.source}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () => widget.onNavigate(2),
              child: const Text(
                'Lihat Tindakan Evakuasi Segera',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // No alert record is not proof that the area is safe.
    final isGuest = widget.user == null;
    final failed = _alertsFailed;
    final title = isGuest
        ? 'Pantau peringatan wilayah'
        : failed
        ? 'Status belum tersedia'
        : 'Belum ada peringatan aktif';
    final description = isGuest
        ? 'Masuk untuk memuat data aplikasi. Tetap ikuti BMKG dan BPBD setempat.'
        : failed
        ? 'Data belum berhasil dimuat. Periksa koneksi dan kanal resmi BMKG/BPBD.'
        : 'Data aplikasi tidak menunjukkan peringatan aktif. Ini bukan konfirmasi bahwa wilayah aman; ikuti BMKG/BPBD.';
    final statusColor = failed
        ? const Color(0xFFB45309)
        : const Color(0xFF0F766E);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .045),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  failed ? Icons.cloud_off_rounded : Icons.shield_outlined,
                  color: statusColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS KESELAMATAN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.05,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'PANTAU',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
              fontSize: 12,
            ),
          ),
          if (isGuest) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => widget.onNavigate(2),
                icon: const Icon(Icons.notifications_active_outlined, size: 17),
                label: const Text('Buka halaman peringatan'),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showGuideDetail(
    BuildContext context,
    String title,
    List<String> items,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF1E60EC),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SosHomeButton extends StatelessWidget {
  const _SosHomeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          height: 126,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(23),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: .22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -42,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .1),
                      width: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 19,
                bottom: 17,
                child: Icon(
                  Icons.sos_rounded,
                  size: 58,
                  color: Colors.white.withValues(alpha: .92),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 15, 94, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'AKSES DARURAT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Butuh bantuan?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Kirim lokasi ke petugas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFFFE4E6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                top: 14,
                child: Icon(
                  Icons.arrow_outward_rounded,
                  color: Colors.white.withValues(alpha: .9),
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickMenuButton extends StatelessWidget {
  const _QuickMenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EducationTile extends StatelessWidget {
  const _EducationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
