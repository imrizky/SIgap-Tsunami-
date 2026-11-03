import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/api_record.dart';
import '../../services/sigap_service.dart';

class EvacuationMapPage extends StatefulWidget {
  const EvacuationMapPage({
    super.key,
    required this.service,
    required this.authenticated,
    required this.onLogin,
    required this.active,
  });

  final SigapService service;
  final bool authenticated;
  final VoidCallback onLogin;
  final bool active;

  @override
  State<EvacuationMapPage> createState() => _EvacuationMapPageState();
}

class _EvacuationMapPageState extends State<EvacuationMapPage> {
  String _selectedFilter = 'semua';
  List<ApiRecord> _points = [];
  bool _loading = true;
  String? _error;
  bool _requestInFlight = false;

  @override
  void initState() {
    super.initState();
    if (widget.active && widget.authenticated) {
      _loadPoints();
    } else if (!widget.authenticated) {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(covariant EvacuationMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.authenticated && oldWidget.authenticated) {
      _points = [];
      _error = null;
      _loading = false;
    } else if (widget.authenticated &&
        ((!oldWidget.authenticated && widget.active) ||
            (!oldWidget.active && widget.active))) {
      _loadPoints();
    }
  }

  Future<void> _loadPoints() async {
    if (!widget.authenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (_requestInFlight) return;
    _requestInFlight = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.service.list('evacuation-points');
      if (mounted) {
        setState(() {
          _points = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    } finally {
      _requestInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1E60EC);

    if (!widget.authenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Peta Evakuasi'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 50, color: primary),
                const SizedBox(height: 14),
                const Text(
                  'Masuk untuk Mengakses Peta & Titik Evakuasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Data lokasi dan kapasitas shelter hanya dapat diakses oleh akun yang terdaftar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: widget.onLogin,
                  child: const Text('Masuk Sekarang'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _selectedFilter == 'semua'
        ? _points
        : _points
              .where((p) => p.type.toLowerCase() == _selectedFilter)
              .toList();

    final nearest = _points.isNotEmpty ? _points.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Peta Evakuasi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E60EC)),
            onPressed: _loadPoints,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: ErrorPanel(message: _error!))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                // Visual Map Container (PDF Page 2)
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background Grid Lines
                      Positioned.fill(
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                      // Simulated Campus / Area Map Pins
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    color: Color(0xFF1E60EC),
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Posisi Anda: Padang State University',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final p in _points.take(3))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E60EC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.shield,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          p.title.split(' ').take(3).join(' '),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Zona Evakuasi Padang (UNP)',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Titik Evakuasi Terdekat (PDF Page 2)
                if (nearest != null) ...[
                  const Text(
                    'Titik Evakuasi Terdekat',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.business,
                                color: primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nearest.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.directions_walk,
                                        size: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '± 350 m dari posisi Anda',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (nearest.description.isNotEmpty)
                          Text(
                            nearest.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (nearest.capacity != null)
                              Text(
                                'Kapasitas: ${nearest.capacity} orang',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFDBEAFE),
                                foregroundColor: primary,
                              ),
                              onPressed: () => _showPointDetail(nearest),
                              child: const Text('lihat rute & detail'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Filter Titik Evakuasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Titik Evakuasi Lainnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${filtered.length} Titik',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        active: _selectedFilter == 'semua',
                        onTap: () => setState(() => _selectedFilter = 'semua'),
                      ),
                      _FilterChip(
                        label: 'Tempat Evakuasi',
                        active: _selectedFilter == 'tempat_evakuasi',
                        onTap: () =>
                            setState(() => _selectedFilter = 'tempat_evakuasi'),
                      ),
                      _FilterChip(
                        label: 'Titik Kumpul',
                        active: _selectedFilter == 'titik_kumpul',
                        onTap: () =>
                            setState(() => _selectedFilter = 'titik_kumpul'),
                      ),
                      _FilterChip(
                        label: 'Posko',
                        active: _selectedFilter == 'posko',
                        onTap: () => setState(() => _selectedFilter = 'posko'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (filtered.isEmpty)
                  const EmptyPanel(
                    icon: Icons.place_outlined,
                    message:
                        'Tidak ada titik evakuasi yang sesuai kategori ini.',
                  )
                else
                  for (final point in filtered)
                    _EvacuationPointCard(
                      point: point,
                      onTap: () => _showPointDetail(point),
                    ),
              ],
            ),
    );
  }

  void _showPointDetail(ApiRecord point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.place, color: Color(0xFF1E60EC)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        point.type.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E60EC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (point.description.isNotEmpty) ...[
              const Text(
                'Deskripsi Fasilitas:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                point.description,
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            if (point.address.isNotEmpty) ...[
              const Text(
                'Alamat:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                point.address,
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            if (point.capacity != null) ...[
              Text(
                'Kapasitas Maksimal: ${point.capacity} orang',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (point.latitude != null && point.longitude != null) ...[
              Text(
                'Koordinat GPS: ${point.latitude}, ${point.longitude}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Rute evakuasi vertikal disarankan melalui tangga darurat gedung.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('Mulai Arah Evakuasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 24) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 24) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFFDBEAFE),
        checkmarkColor: const Color(0xFF1E60EC),
        labelStyle: TextStyle(
          color: active ? const Color(0xFF1E60EC) : const Color(0xFF475569),
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EvacuationPointCard extends StatelessWidget {
  const _EvacuationPointCard({required this.point, required this.onTap});

  final ApiRecord point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.place_outlined, color: Color(0xFF1E60EC)),
        ),
        title: Text(
          point.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          point.address.isNotEmpty ? point.address : point.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

// ==========================================
// HALAMAN PERINGATAN & NOTIFIKASI (PDF Page 3 & 7)
// ==========================================

class AlertsPage extends StatefulWidget {
  const AlertsPage({
    super.key,
    required this.service,
    required this.authenticated,
    required this.onLogin,
    required this.active,
  });

  final SigapService service;
  final bool authenticated;
  final VoidCallback onLogin;
  final bool active;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  List<ApiRecord> _alerts = [];
  bool _loading = true;
  bool _refreshing = false;
  bool _hasLoadedOnce = false;
  bool _requestInFlight = false;
  bool _appResumed = true;
  String? _error;
  String? _refreshError;
  DateTime? _lastUpdated;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.authenticated && widget.active) {
      _loadAlerts();
    } else if (!widget.authenticated) {
      _loading = false;
    }
    _syncPolling();
  }

  @override
  void didUpdateWidget(covariant AlertsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.authenticated && oldWidget.authenticated) {
      _alerts = [];
      _error = null;
      _refreshError = null;
      _lastUpdated = null;
      _loading = false;
    }
    _syncPolling();
    if (widget.authenticated &&
        widget.active &&
        (!oldWidget.authenticated || !oldWidget.active)) {
      _loadAlerts();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    _syncPolling();
    if (_appResumed && widget.active && widget.authenticated) {
      _loadAlerts(silent: true);
    }
  }

  void _syncPolling() {
    if (widget.active && widget.authenticated && _appResumed) {
      _pollTimer ??= Timer.periodic(
        const Duration(seconds: 30),
        (_) => _loadAlerts(silent: true),
      );
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts({bool silent = false}) async {
    if (!widget.authenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (_requestInFlight) return;
    _requestInFlight = true;
    if (mounted) {
      setState(() {
        _loading = !_hasLoadedOnce;
        _refreshing = true;
        if (!silent) {
          _error = null;
          _refreshError = null;
        }
      });
    }
    try {
      final list = await widget.service.list('alerts');
      if (mounted) {
        setState(() {
          _alerts = list;
          _loading = false;
          _refreshing = false;
          _hasLoadedOnce = true;
          _lastUpdated = DateTime.now();
          _error = null;
          _refreshError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
          _hasLoadedOnce = true;
          if (_alerts.isEmpty) {
            _error = e.toString().replaceAll('Exception: ', '');
          } else {
            _refreshError = e.toString().replaceAll('Exception: ', '');
          }
        });
      }
    } finally {
      _requestInFlight = false;
    }
  }

  String _formatUpdatedTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifikasi & Peringatan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Color(0xFF1E60EC),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Masuk untuk Melihat Informasi Peringatan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: widget.onLogin,
                  child: const Text('Masuk'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? _alerts
        : _alerts
              .where(
                (a) =>
                    a.title.toLowerCase().contains(query) ||
                    a.description.toLowerCase().contains(query) ||
                    a.affectedArea.toLowerCase().contains(query),
              )
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Notifikasi & Peringatan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Perbarui peringatan',
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF1E60EC)),
            onPressed: _refreshing ? null : _loadAlerts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (PDF Page 7)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari peringatan atau wilayah...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.sync_rounded,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _lastUpdated == null
                        ? 'Menunggu data peringatan...'
                        : 'Diperbarui ${_formatUpdatedTime(_lastUpdated!)} • otomatis tiap 30 detik saat halaman terbuka',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_refreshError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  'Pembaruan gagal. Data yang tampil mungkin sudah lama. $_refreshError',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 11,
                  ),
                ),
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: ErrorPanel(message: _error!))
                : filtered.isEmpty
                ? RefreshIndicator(
                    onRefresh: () => _loadAlerts(silent: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      children: const [
                        SizedBox(
                          height: 280,
                          child: Center(
                            child: EmptyPanel(
                              icon: Icons.notifications_off_outlined,
                              message: 'Belum ada pesan peringatan bencana aktif saat ini.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadAlerts(silent: true),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _AlertItemCard(
                          alert: item,
                          onTap: () => _showAlertDetail(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAlertDetail(ApiRecord alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AlertDetailModal(alert: alert),
    );
  }
}

class _AlertItemCard extends StatelessWidget {
  const _AlertItemCard({required this.alert, required this.onTap});
  final ApiRecord alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDanger =
        alert.severity.toLowerCase() == 'darurat' ||
        alert.severity.toLowerCase() == 'siaga';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDanger ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          width: isDanger ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDanger ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDanger ? Icons.warning_rounded : Icons.info_outline,
            color: isDanger ? const Color(0xFFDC2626) : const Color(0xFFD97706),
            size: 28,
          ),
        ),
        title: Text(
          alert.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              alert.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                if (alert.severity.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDanger
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      alert.severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDanger
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                if (alert.affectedArea.isNotEmpty)
                  Text(
                    'Wilayah: ${alert.affectedArea}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Modal Detail Peringatan Bahaya (PDF Page 3)
class _AlertDetailModal extends StatefulWidget {
  const _AlertDetailModal({required this.alert});
  final ApiRecord alert;

  @override
  State<_AlertDetailModal> createState() => _AlertDetailModalState();
}

class _AlertDetailModalState extends State<_AlertDetailModal> {
  bool _soundAlert = false;

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final isDanger =
        alert.severity.toLowerCase() == 'darurat' ||
        alert.severity.toLowerCase() == 'siaga';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Red Banner (PDF Page 3)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDanger
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF1E60EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Peringatan',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    isDanger ? 'BAHAYA!' : 'WASPADA!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Center(
              child: Icon(
                Icons.warning_amber_rounded,
                size: 56,
                color: isDanger
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              alert.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                alert.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),

            if (alert.affectedArea.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.place, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wilayah Terdampak: ${alert.affectedArea}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            if (alert.source.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  'Sumber: ${alert.source}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            const SizedBox(height: 18),

            // Tombol Evakuasi Sekarang (PDF Page 3)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isDanger
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF1E60EC),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Menuju peta evakuasi dan rute tempat tinggi...',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.directions_run),
              label: const Text(
                'Evakuasi Sekarang',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            // Tombol Suara Peringatan (PDF Page 3)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                setState(() => _soundAlert = !_soundAlert);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _soundAlert
                          ? 'Simulasi suara sirene peringatan diaktifkan.'
                          : 'Suara peringatan dimatikan.',
                    ),
                  ),
                );
              },
              icon: Icon(
                _soundAlert ? Icons.volume_up : Icons.volume_off,
                color: const Color(0xFF1E60EC),
              ),
              label: Text(
                _soundAlert
                    ? 'Matikan Suara Peringatan'
                    : 'Aktifkan Suara Peringatan',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Panels
class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ],
    ),
  );
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 40, color: Color(0xFFDC2626)),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
        ),
      ],
    ),
  );
}

class InfoNotice extends StatelessWidget {
  const InfoNotice({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: Color(0xFF1E60EC), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
          ),
        ),
      ],
    ),
  );
}
