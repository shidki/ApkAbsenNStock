import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import '../api.dart';
import '../config.dart';
import '../models.dart';
import '../ui.dart';

class AbsenScreen extends StatefulWidget {
  const AbsenScreen({super.key});
  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  AbsenMe? _me;
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final m = await api.absenMe();
      if (mounted) setState(() { _me = m; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  Future<void> _scan() async {
    final result = await Navigator.push<ClockResult>(
      context, MaterialPageRoute(builder: (_) => const _ScannerPage()),
    );
    if (result != null && mounted) {
      await _showResult(result);
      _load();
    }
  }

  Future<void> _showResult(ClockResult r) async {
    final ok = r.action != 'sudah_lengkap';
    final late = r.status == 'terlambat' || r.menitPulangCepat > 0;
    final color = !ok ? AppTheme.muted : (late ? AppTheme.warning : AppTheme.success);
    final title = r.action == 'masuk'
        ? (r.status == 'terlambat' ? 'Clock In — Terlambat' : 'Clock In Berhasil')
        : r.action == 'pulang'
            ? 'Clock Out Berhasil'
            : 'Sudah Lengkap';
    final meta = r.action == 'masuk'
        ? 'Jam ${r.jam}${r.menitTelat > 0 ? ' · telat ${r.menitTelat} menit' : ' · tepat waktu'}'
        : r.action == 'pulang'
            ? 'Jam ${r.jam} · kerja ${fmtDurasi(r.durasiMenit)}${r.menitPulangCepat > 0 ? ' · pulang cepat ${r.menitPulangCepat}m' : ''}'
            : r.message;
    await showDialog(
      context: context,
      builder: (c) => Dialog(
        insetPadding: const EdgeInsets.all(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(
                  ok ? (late ? Icons.timelapse_rounded : Icons.check_circle_rounded) : Icons.info_outline_rounded,
                  color: color, size: 46,
                ),
              ),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: AppTheme.ink)),
              const SizedBox(height: 8),
              Text('${r.karyawan}\n$meta', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, height: 1.5)),
              const SizedBox(height: 22),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Oke, Mengerti'))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _err != null
                ? _refreshable(ErrorView(msg: _err!, onRetry: _load))
                : _me!.linked
                    ? _content()
                    : _refreshable(_notLinked()),
      ),
    );
  }

  // Bungkus state non-scroll (error / belum terhubung) biar tetap bisa pull-to-refresh.
  Widget _refreshable(Widget child) => RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: child,
            ),
          ),
        ),
      );

  Widget _notLinked() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.link_off_rounded, size: 38, color: AppTheme.warning),
          ),
          const SizedBox(height: 16),
          const Text('Akun Belum Terhubung', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.ink)),
          const SizedBox(height: 6),
          const Text('Akun kamu belum di-link ke data karyawan.\nHubungi admin/HR, lalu tarik ke bawah untuk muat ulang.',
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted, height: 1.5)),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Muat ulang')),
          ),
        ]),
      );

  Widget _content() {
    final m = _me!;
    final next = m.berikutnya;
    final done = next == 'selesai';
    final label = next == 'pulang' ? 'Scan QR — Clock Out' : 'Scan QR — Clock In';
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        padding: EdgeInsets.fromLTRB(screenPad(context) + 4, 20, screenPad(context) + 4, bottomGap(context)),
        children: [
          const SizedBox(height: 12),
          Center(child: _PulseBadge(done: done)),
          const SizedBox(height: 22),
          Text('Halo, ${m.nama} 👋', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.ink, letterSpacing: -0.3)),
          const SizedBox(height: 6),
          Text(
            m.jamMasuk == null ? 'Kamu belum clock in hari ini' : 'Masuk ${m.jamMasuk}${m.jamPulang != null ? '  ·  Pulang ${m.jamPulang}' : ''}',
            textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 14),
          ),
          const SizedBox(height: 30),
          if (done)
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, color: AppTheme.success, size: 34),
                ),
                const SizedBox(height: 14),
                const Text('Absen Hari Ini Sudah Lengkap',
                    textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink, fontSize: 15.5)),
                const SizedBox(height: 4),
                const Text('Sampai jumpa besok! 🎉', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
              ]),
            )
          else
            _ScanButton(label: label, onTap: _scan),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.soft, borderRadius: BorderRadius.circular(AppTheme.rMd)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.muted),
              SizedBox(width: 10),
              Expanded(
                child: Text('Arahkan kamera ke QR absen yang dipajang di kantor.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 12.5, height: 1.4)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Lencana besar dengan cincin denyut (idle) atau ceklis (selesai).
class _PulseBadge extends StatefulWidget {
  final bool done;
  const _PulseBadge({required this.done});
  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.done ? AppTheme.success : AppTheme.primary;
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!widget.done)
            AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = _c.value;
                return Container(
                  width: 100 + t * 60,
                  height: 100 + t * 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: base.withValues(alpha: (1 - t) * 0.22),
                  ),
                );
              },
            ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: AppTheme.glow(base, blur: 30, a: 0.4),
            ),
            child: Icon(widget.done ? Icons.check_rounded : Icons.qr_code_scanner_rounded, color: Colors.white, size: 50),
          ),
        ],
      ),
    );
  }
}

/// Tombol scan besar bergradien dengan glow.
class _ScanButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ScanButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.rSm),
        boxShadow: AppTheme.glow(AppTheme.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.rSm),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Halaman scanner kamera (qr_code_dart_scan — decode QR murni Dart, tanpa MLKit) ──
class _ScannerPage extends StatefulWidget {
  const _ScannerPage();
  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  bool _busy = false;

  Future<void> _onCapture(Result result) async {
    if (_busy) return;
    final raw = result.text.trim();
    if (raw.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await api.clock(extractKode(raw));
      if (mounted) Navigator.pop(context, res);
    } catch (e) {
      if (mounted) {
        toast(context, e.toString(), error: true);
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scan QR Absen'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          QRCodeDartScanView(
            typeScan: TypeScan.live,
            scanInvertedQRCode: true,
            onCapture: _onCapture,
          ),
          // bingkai target dengan 4 sudut
          IgnorePointer(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  _corner(Alignment.topLeft),
                  _corner(Alignment.topRight),
                  _corner(Alignment.bottomLeft),
                  _corner(Alignment.bottomRight),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_busy ? Icons.sync_rounded : Icons.qr_code_2_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(_busy ? 'Memproses…' : 'Arahkan ke QR absen kantor',
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(color: Color(0x88000000), child: Center(child: CircularProgressIndicator(color: Colors.white))),
            ),
        ],
      ),
    );
  }

  Widget _corner(Alignment a) {
    final top = a.y < 0, left = a.x < 0;
    return Align(
      alignment: a,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: AppTheme.primaryLight, width: 4) : BorderSide.none,
            bottom: !top ? const BorderSide(color: AppTheme.primaryLight, width: 4) : BorderSide.none,
            left: left ? const BorderSide(color: AppTheme.primaryLight, width: 4) : BorderSide.none,
            right: !left ? const BorderSide(color: AppTheme.primaryLight, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(16) : Radius.zero,
            topRight: top && !left ? const Radius.circular(16) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(16) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(16) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
