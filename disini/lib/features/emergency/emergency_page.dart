import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/api_record.dart';
import '../../services/device_location_service.dart';
import '../../services/sigap_service.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key, required this.service, this.locationService});

  final SigapService service;
  final DeviceLocationService? locationService;

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  final _description = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _address = TextEditingController();

  final String _incidentType = 'tsunami';
  late final DeviceLocationService _locationService;
  bool _busy = false;
  bool _locationBusy = false;
  String? _locationError;
  double? _locationAccuracy;
  DateTime? _locationTimestamp;
  LocationSettingsAction? _locationSettingsAction;
  List<ApiRecord> _myReports = [];
  bool _loadingReports = true;
  bool _refreshingReports = false;
  bool _showAllReports = false;
  String? _reportsError;
  int _reportsRequestVersion = 0;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? const DeviceLocationService();
    _fetchMyReports();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _useCurrentLocation();
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _lat.dispose();
    _lon.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _fetchMyReports() async {
    final requestVersion = ++_reportsRequestVersion;
    if (mounted && !_loadingReports) {
      setState(() {
        _refreshingReports = true;
        _reportsError = null;
      });
    }
    try {
      final reports = await widget.service.myReports();
      if (mounted && requestVersion == _reportsRequestVersion) {
        setState(() {
          _myReports = reports;
          _loadingReports = false;
          _refreshingReports = false;
          _reportsError = null;
        });
      }
    } catch (error) {
      if (mounted && requestVersion == _reportsRequestVersion) {
        setState(() {
          _loadingReports = false;
          _refreshingReports = false;
          _reportsError = error.toString();
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locationBusy || _busy) return;
    setState(() {
      _locationBusy = true;
      _locationError = null;
      _locationSettingsAction = null;
    });
    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;
      _lat.text = location.latitude.toStringAsFixed(7);
      _lon.text = location.longitude.toStringAsFixed(7);
      setState(() {
        _locationAccuracy = location.accuracyMeters;
        _locationTimestamp = location.timestamp.toLocal();
        _locationError = null;
      });
    } on DeviceLocationException catch (error) {
      if (mounted) {
        setState(() {
          _locationError = error.message;
          _locationSettingsAction = error.settingsAction;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError = 'Lokasi otomatis tidak tersedia. Periksa GPS atau masukkan koordinat manual.';
        });
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _openLocationSettings() async {
    final action = _locationSettingsAction;
    if (action == null) return;
    try {
      final opened = await _locationService.openSettings(action);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan lokasi tidak dapat dibuka.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan lokasi tidak tersedia.')),
        );
      }
    }
  }

  void _manualCoordinateChanged() {
    if (_locationAccuracy != null || _locationTimestamp != null) {
      setState(() {
        _locationAccuracy = null;
        _locationTimestamp = null;
      });
    }
  }

  Future<void> _triggerSos() async {
    final latitude = double.tryParse(_lat.text.trim());
    final longitude = double.tryParse(_lon.text.trim());
    if (latitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude == null ||
        longitude < -180 ||
        longitude > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Masukkan koordinat lokasi yang valid sebelum mengirim SOS.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Konfirmasi S.O.S'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda benar-benar memerlukan bantuan darurat?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Koordinat $latitude, $longitude akan disertakan dalam laporan. Pastikan lokasinya benar. Laporan disimpan server dan tidak mengirim notifikasi langsung ke petugas. Jika perlu pertolongan segera, hubungi kontak darurat.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim S.O.S Sekarang'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final res = await widget.service.sendEmergency(
        incidentType: _incidentType,
        description: _description.text.trim(),
        latitude: latitude,
        longitude: longitude,
        address: _address.text.trim(),
      );

      final code = res['report_code']?.toString() ?? 'SOS';
      if (mounted) {
        final report = ApiRecord({
          ...res,
          'id': res['id'] ?? 'local-${DateTime.now().microsecondsSinceEpoch}',
          'report_code': code,
          'incident_type': res['incident_type'] ?? _incidentType,
          'description': res['description'] ?? _description.text.trim(),
          'latitude': res['latitude'] ?? latitude,
          'longitude': res['longitude'] ?? longitude,
          'address': res['address'] ?? _address.text.trim(),
          'status': res['status'] ?? 'menunggu',
          'created_at': res['created_at'] ?? DateTime.now().toIso8601String(),
        });
        _reportsRequestVersion++;
        setState(() {
          _myReports = [
            report,
            ..._myReports.where(
              (existing) =>
                  existing.id != report.id &&
                  existing.reportCode != report.reportCode,
            ),
          ];
          _loadingReports = false;
          _refreshingReports = false;
          _reportsError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('Laporan $code tersimpan • status menunggu.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Pengiriman gagal: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Panggilan telepon ke $number tidak didukung di perangkat ini.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Panggilan ke $number tidak tersedia.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const dangerColor = Color(0xFFDC2626);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Bantuan Darurat',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSosHero(dangerColor),
            const SizedBox(height: 18),
            _buildMyReportsSection(),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: .035),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFF0F5684),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Lokasi perangkat',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Ambil koordinat HP secara otomatis atau isi manual jika GPS tidak tersedia. Lokasi hanya masuk ke laporan setelah Anda menekan S.O.S dan mengonfirmasi.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('sos-use-current-location'),
              onPressed: _locationBusy || _busy ? null : _useCurrentLocation,
              icon: _locationBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _locationBusy
                    ? 'Mencari lokasi...'
                    : _locationTimestamp == null
                    ? 'Gunakan lokasi saya'
                    : 'Perbarui lokasi saat ini',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: const Color(0xFF1E60EC),
                side: const BorderSide(color: Color(0xFF93C5FD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            if (_locationTimestamp != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Color(0xFF047857),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationAccuracy == null
                            ? 'Lokasi terisi • akurasi tidak tersedia • ${_formatTime(_locationTimestamp!)}'
                            : 'Lokasi terisi • akurasi sekitar ±${_locationAccuracy!.round()} m • ${_formatTime(_locationTimestamp!)}',
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_locationError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _locationError!,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                      ),
                    ),
                    if (_locationSettingsAction != null)
                      TextButton.icon(
                        onPressed: _openLocationSettings,
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: Text(
                          _locationSettingsAction == LocationSettingsAction.app
                              ? 'Buka pengaturan aplikasi'
                              : 'Buka pengaturan lokasi',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF92400E),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('sos-latitude'),
              controller: _lat,
              onChanged: (_) => _manualCoordinateChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitude lokasi Anda',
                hintText: 'Contoh format: -0.1234567',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('sos-longitude'),
              controller: _lon,
              onChanged: (_) => _manualCoordinateChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitude lokasi Anda',
                hintText: 'Contoh format: 100.1234567',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Alamat / patokan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Kontak Darurat List (PDF Page 8)
            const Text(
              'Kontak Darurat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),

            _EmergencyContactCard(
              title: 'Ambulans & Medis',
              phone: '118/119',
              icon: Icons.local_hospital_outlined,
              iconColor: const Color(0xFFDC2626),
              onCall: () => _call('119'),
            ),
            const SizedBox(height: 8),

            _EmergencyContactCard(
              title: 'Pemadam Kebakaran',
              phone: '113',
              icon: Icons.fire_truck_outlined,
              iconColor: const Color(0xFFEA580C),
              onCall: () => _call('113'),
            ),
            const SizedBox(height: 8),

            _EmergencyContactCard(
              title: 'Kepolisian',
              phone: '110',
              icon: Icons.local_police_outlined,
              iconColor: const Color(0xFF1E60EC),
              onCall: () => _call('110'),
            ),
            const SizedBox(height: 8),

            _EmergencyContactCard(
              title: 'BASARNAS (Pencarian & Pertolongan)',
              phone: '115',
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF0D9488),
              onCall: () => _call('115'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSosHero(Color dangerColor) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF991B1B), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: dangerColor.withValues(alpha: .2),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -55,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .12),
                  width: 25,
                ),
              ),
            ),
          ),
          Positioned(
            right: 19,
            top: 56,
            child: Icon(
              Icons.sos_rounded,
              size: 82,
              color: Colors.white.withValues(alpha: .16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'BANTUAN DARURAT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Butuh bantuan\nsekarang?',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.06,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kirim lokasi dan laporan SOS ke server.',
                  style: TextStyle(
                    color: Color(0xFFFFE4E6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    key: const ValueKey('sos-submit'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFB91C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _busy ? null : _triggerSos,
                    icon: _busy
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              color: Color(0xFFB91C1C),
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.sos_rounded, size: 26),
                    label: Text(
                      _busy ? 'Mengirim laporan...' : 'KIRIM S.O.S',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white70,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Laporan tersimpan di server; notifikasi petugas tidak dikirim otomatis.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReportsSection() {
    final visibleReports = _showAllReports ? _myReports : _myReports.take(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Riwayat laporan SOS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            if (_myReports.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_myReports.length}',
                  style: const TextStyle(
                    color: Color(0xFF1E60EC),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Muat ulang riwayat laporan',
              onPressed: _refreshingReports ? null : _fetchMyReports,
              icon: _refreshingReports
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _loadingReports
              ? const Padding(
                  key: ValueKey('reports-loading'),
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              : _myReports.isEmpty
              ? _ReportMessageCard(
                  key: ValueKey(
                    _reportsError == null ? 'reports-empty' : 'reports-error',
                  ),
                  icon: _reportsError == null
                      ? Icons.inbox_outlined
                      : Icons.cloud_off_outlined,
                  message: _reportsError == null
                      ? 'Laporan yang berhasil dikirim akan muncul di sini.'
                      : 'Riwayat belum bisa dimuat. Periksa koneksi lalu coba lagi.',
                  actionLabel: _reportsError == null ? null : 'Coba lagi',
                  onAction: _reportsError == null ? null : _fetchMyReports,
                )
              : Column(
                  key: ValueKey(
                    'reports-${_myReports.length}-${_myReports.first.id}',
                  ),
                  children: [
                    if (_reportsError != null)
                      _ReportMessageCard(
                        icon: Icons.info_outline_rounded,
                        message: 'Pembaruan riwayat gagal. Laporan yang sudah tampil tetap disimpan di layar.',
                        actionLabel: 'Coba lagi',
                        onAction: _fetchMyReports,
                        compact: true,
                      ),
                    for (final report in visibleReports)
                      _ReportHistoryTile(
                        key: ValueKey(
                          'report-${report.id}-${report.reportCode}',
                        ),
                        report: report,
                      ),
                    if (_myReports.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(
                            () => _showAllReports = !_showAllReports,
                          ),
                          icon: Icon(
                            _showAllReports
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                          label: Text(
                            _showAllReports
                                ? 'Tampilkan terbaru saja'
                                : 'Lihat semua ${_myReports.length} laporan',
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.title,
    required this.phone,
    required this.icon,
    required this.iconColor,
    required this.onCall,
  });

  final String title;
  final String phone;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
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
                  phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFF1E60EC)),
            onPressed: onCall,
          ),
        ],
      ),
    );
  }
}

class _ReportMessageCard extends StatelessWidget {
  const _ReportMessageCard({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: compact ? 8 : 0),
      padding: EdgeInsets.all(compact ? 11 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _ReportHistoryTile extends StatelessWidget {
  const _ReportHistoryTile({super.key, required this.report});
  final ApiRecord report;

  @override
  Widget build(BuildContext context) {
    Color statusBg;
    Color statusColor;
    switch (report.status.toLowerCase()) {
      case 'selesai':
        statusBg = const Color(0xFFDCFCE7);
        statusColor = const Color(0xFF16A34A);
        break;
      case 'diproses':
        statusBg = const Color(0xFFDBEAFE);
        statusColor = const Color(0xFF1E60EC);
        break;
      case 'menunggu':
      default:
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFFD97706);
        break;
    }

    final createdAt = DateTime.tryParse(report.createdAt)?.toLocal();
    final createdAtLabel = createdAt == null
        ? null
        : '${createdAt.day.toString().padLeft(2, '0')}/'
              '${createdAt.month.toString().padLeft(2, '0')}/'
              '${createdAt.year} • '
              '${createdAt.hour.toString().padLeft(2, '0')}:'
              '${createdAt.minute.toString().padLeft(2, '0')}';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - progress)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: .035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.reportCode.isEmpty ? 'SOS' : report.reportCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (createdAtLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                'Dikirim $createdAtLabel',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                report.description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
            if (report.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.address,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
