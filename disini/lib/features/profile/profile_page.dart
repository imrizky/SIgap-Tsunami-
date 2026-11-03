import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/api_record.dart';
import '../../models/app_user.dart';
import '../../services/sigap_service.dart';
import '../information/information_pages.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Panduan Tsunami',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 80),
        children: [
          // Banner Tsunami Illustration (PDF Page 4)
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E60EC), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    Icons.tsunami,
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Kesiapsiagaan Dini',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pahami Gejala & Tindakan\nSebelum Gelombang Tiba',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tanda-tanda Tsunami Checklist (PDF Page 4)
          const Text(
            'Tanda-tanda Tsunami',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                _ChecklistRow(
                  text: 'Gempa Bumi terasa kuat atau berdurasi lama',
                ),
                SizedBox(height: 10),
                _ChecklistRow(
                  text: 'Air laut tiba-tiba surut drastis hingga ikan terlihat',
                ),
                SizedBox(height: 10),
                _ChecklistRow(
                  text: 'Suara gemuruh keras dari arah tengah laut lepas',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Yang Harus Dilakukan (PDF Page 4)
          const Text(
            'Yang Harus Dilakukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.self_improvement,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Tetap Tenang',
                  subtitle: 'Jangan panik, fokus bertindak cepat',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.directions_run,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Jauhi Pantai',
                  subtitle: 'Segera bergerak menjauh dari bibir laut',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _ActionCard(
            icon: Icons.landscape,
            iconColor: const Color(0xFF16A34A),
            title: 'Menuju Tempat Tertinggi',
            subtitle: 'Evakuasi ke perbukitan atau lantai 3+ gedung evakuasi vertikal',
          ),
          const SizedBox(height: 20),

          const InfoNotice(
            text: 'Aplikasi ini bukan pengganti sistem peringatan resmi. Jika tanda alam tsunami terasa, segera lakukan evakuasi mandiri tanpa menunggu konfirmasi.',
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E60EC),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HALAMAN PROFIL & ROLE DASHBOARD (PDF Page 5)
// ==========================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogin,
    required this.onLogout,
    required this.service,
  });

  final AppUser? user;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final SigapService service;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationEnabled = true;

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Panggilan telepon ke $number tidak didukung.'),
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
    const primary = Color(0xFF1E60EC);
    final user = widget.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Profil Pengguna'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 64,
                  color: primary,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Halo Anonim',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masuk ke akun Sigap Tsunami untuk mengelola profil, melihat status tugas, dan laporan darurat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: widget.onLogin,
                  child: const Text('Masuk / Daftar Akun'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Halo, ${user.name.split(' ').first}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 80),
        children: [
          // Detail Pengguna Card (PDF Page 5)
          const Text(
            'Detail Pengguna',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
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
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: Text(
                        user.name.isEmpty ? 'U' : user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Text(
                              user.roleLabel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _ProfileInfoRow(
                  icon: Icons.place_outlined,
                  label: 'Lokasi',
                  value: user.location ?? 'Belum tersedia',
                ),
                const SizedBox(height: 8),
                _ProfileInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Kontak',
                  value: user.phone ?? 'Belum tersedia',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Kirim Status Keselamatan Mandiri
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFDCFCE7),
              foregroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SafetyStatusPage(service: widget.service),
              ),
            ),
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text(
              'Perbarui Status Keselamatan Saya',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),

          // Role-Specific Section
          if (user.isRelawan) ...[
            _VolunteerTaskSection(service: widget.service),
            const SizedBox(height: 20),
          ],

          if (user.isPetugas) ...[
            _StaffDashboardSection(service: widget.service),
            const SizedBox(height: 20),
          ],

          if (user.isAdmin) ...[
            _AdminDashboardSection(service: widget.service),
            const SizedBox(height: 20),
          ],

          // Kontak Darurat Cepat (PDF Page 5)
          const Text(
            'Kontak Darurat Cepat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _QuickCallRow(
                  title: 'Ambulans / Medis',
                  phone: '118 / 119',
                  onCall: () => _call('119'),
                ),
                const Divider(height: 16),
                _QuickCallRow(
                  title: 'Pemadam Kebakaran',
                  phone: '113',
                  onCall: () => _call('113'),
                ),
                const Divider(height: 16),
                _QuickCallRow(
                  title: 'Kepolisian',
                  phone: '110',
                  onCall: () => _call('110'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pengaturan (PDF Page 5)
          const Text(
            'Pengaturan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.notifications_outlined,
                    color: primary,
                  ),
                  title: const Text(
                    'Notifikasi Peringatan',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Terima notifikasi bencana darurat',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _notificationEnabled,
                  onChanged: (v) => setState(() => _notificationEnabled = v),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_outlined, color: primary),
                  title: const Text('Bahasa', style: TextStyle(fontSize: 14)),
                  trailing: const Text(
                    'Bahasa Indonesia',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline, color: primary),
                  title: const Text(
                    'Tentang Aplikasi',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: const Text(
                    'v1.0.0',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Sigap Tsunami',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Sistem Informasi, Evakuasi, dan Kesiapsiagaan Bencana Tsunami.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Keluar (Logout)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFECACA)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            label: const Text(
              'Keluar dari Akun',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickCallRow extends StatelessWidget {
  const _QuickCallRow({
    required this.title,
    required this.phone,
    required this.onCall,
  });

  final String title;
  final String phone;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              phone,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.phone, color: Color(0xFF1E60EC)),
          onPressed: onCall,
        ),
      ],
    );
  }
}

// ==========================================
// FORM STATUS KESELAMATAN MANDIRI
// ==========================================

class SafetyStatusPage extends StatefulWidget {
  const SafetyStatusPage({super.key, required this.service});
  final SigapService service;

  @override
  State<SafetyStatusPage> createState() => _SafetyStatusPageState();
}

class _SafetyStatusPageState extends State<SafetyStatusPage> {
  final _description = TextEditingController();
  String _status = 'aman';
  bool _busy = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await widget.service.sendSafety(
        status: _status,
        description: _description.text.trim(),
        latitude: -0.8973,
        longitude: 100.3508,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('Status keselamatan berhasil dikirim ke server.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Gagal mengirim status: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Status Keselamatan'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Laporkan Kondisi Anda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Data status keselamatan Anda membantu petugas BPBD/SAR mendata korban dan memetakan kebutuhan bantuan.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Kondisi Anda Saat Ini',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'aman',
                  child: Text('Saya Aman (Di Tempat Tinggi / Posko)'),
                ),
                DropdownMenuItem(
                  value: 'butuh_bantuan',
                  child: Text('Saya Butuh Bantuan / Evakuasi'),
                ),
                DropdownMenuItem(
                  value: 'dalam_bahaya',
                  child: Text('Saya Dalam Bahaya (Terjebak / Terluka)'),
                ),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'aman'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Keterangan Tambahan (opsional)',
                hintText: 'Contoh: Berada di lantai 3 Gedung Rektorat UNP bersama 5 orang mahasiswa.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E60EC),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Kirim Status Keselamatan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PANEL ROLE RELAWAN
// ==========================================

class _VolunteerTaskSection extends StatefulWidget {
  const _VolunteerTaskSection({required this.service});
  final SigapService service;

  @override
  State<_VolunteerTaskSection> createState() => _VolunteerTaskSectionState();
}

class _VolunteerTaskSectionState extends State<_VolunteerTaskSection> {
  List<ApiRecord> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final list = await widget.service.volunteerTasks();
      if (mounted) {
        setState(() {
          _tasks = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tugas Penugasan Relawan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _fetchTasks,
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'Belum ada tugas lapangan yang ditugaskan kepada Anda saat ini.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          )
        else
          for (final task in _tasks)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E60EC),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (task.status.toLowerCase() != 'berlangsung')
                        TextButton(
                          onPressed: () async {
                            await widget.service.updateVolunteerTask(
                              task.id,
                              'berlangsung',
                            );
                            _fetchTasks();
                          },
                          child: const Text('Mulai Tugas'),
                        ),
                      if (task.status.toLowerCase() != 'selesai')
                        FilledButton.tonal(
                          onPressed: () async {
                            await widget.service.updateVolunteerTask(
                              task.id,
                              'selesai',
                            );
                            _fetchTasks();
                          },
                          child: const Text('Tandai Selesai'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

// ==========================================
// PANEL ROLE PETUGAS BPBD/SAR
// ==========================================

class _StaffDashboardSection extends StatefulWidget {
  const _StaffDashboardSection({required this.service});
  final SigapService service;

  @override
  State<_StaffDashboardSection> createState() => _StaffDashboardSectionState();
}

class _StaffDashboardSectionState extends State<_StaffDashboardSection> {
  Map<String, dynamic> _stats = {};
  List<ApiRecord> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    try {
      final stats = await widget.service.staffDashboard();
      final reports = await widget.service.allReportsForStaff();
      if (mounted) {
        setState(() {
          _stats = stats;
          _reports = reports;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dashboard Petugas BPBD/SAR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadStaffData,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          // Grid Ringkasan Laporan
          Row(
            children: [
              Expanded(
                child: _CountCard(
                  label: 'Menunggu',
                  count: _stats['menunggu']?.toString() ?? '0',
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountCard(
                  label: 'Diproses',
                  count: _stats['diproses']?.toString() ?? '0',
                  color: const Color(0xFF1E60EC),
                  bgColor: const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountCard(
                  label: 'Selesai',
                  count: _stats['selesai']?.toString() ?? '0',
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Kelola Laporan Masuk
          const Text(
            'Laporan Masuk Menunggu Tindakan:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),

          if (_reports.isEmpty)
            const Text(
              'Tidak ada laporan darurat aktif.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          else
            for (final r in _reports.take(4))
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.reportCode} • ${r.userName.isNotEmpty ? r.userName : 'Warga'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            r.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onSelected: (st) async {
                        await widget.service.updateReportStatus(r.id, st);
                        _loadStaffData();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'menunggu',
                          child: Text('Menunggu'),
                        ),
                        PopupMenuItem(value: 'diproses', child: Text('Proses')),
                        PopupMenuItem(value: 'selesai', child: Text('Selesai')),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ],
    );
  }
}

// ==========================================
// PANEL ROLE ADMINISTRATOR
// ==========================================

class _AdminDashboardSection extends StatefulWidget {
  const _AdminDashboardSection({required this.service});
  final SigapService service;

  @override
  State<_AdminDashboardSection> createState() => _AdminDashboardSectionState();
}

class _AdminDashboardSectionState extends State<_AdminDashboardSection> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final stats = await widget.service.adminStats();
      final users = await widget.service.adminUsers();
      if (mounted) {
        setState(() {
          _stats = stats;
          _users = users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleCounts = _stats['users_by_role'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dashboard Administrator',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadAdminData,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          // Stat overview
          Row(
            children: [
              Expanded(
                child: _CountCard(
                  label: 'Warga',
                  count: roleCounts['warga']?.toString() ?? '0',
                  color: const Color(0xFF1E60EC),
                  bgColor: const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountCard(
                  label: 'Relawan',
                  count: roleCounts['relawan']?.toString() ?? '0',
                  color: const Color(0xFF0D9488),
                  bgColor: const Color(0xFFCCFBF1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CountCard(
                  label: 'Petugas',
                  count: roleCounts['petugas']?.toString() ?? '0',
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Manajemen Peran Pengguna (RBAC):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),

          for (final u in _users.take(5))
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u['name']?.toString() ?? 'Pengguna',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          u['email']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (u['role']?.toString() ?? 'warga').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E60EC),
                        ),
                      ),
                    ),
                    onSelected: (newRole) async {
                      final uid = u['id'] is int
                          ? u['id'] as int
                          : int.parse(u['id'].toString());
                      await widget.service.updateUserRole(uid, newRole);
                      _loadAdminData();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'warga',
                        child: Text('Ubah ke Warga'),
                      ),
                      PopupMenuItem(
                        value: 'relawan',
                        child: Text('Ubah ke Relawan'),
                      ),
                      PopupMenuItem(
                        value: 'petugas',
                        child: Text('Ubah ke Petugas'),
                      ),
                      PopupMenuItem(
                        value: 'admin',
                        child: Text('Ubah ke Admin'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final String count;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
