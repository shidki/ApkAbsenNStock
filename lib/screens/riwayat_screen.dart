import 'package:flutter/material.dart';
import '../api.dart';
import '../config.dart';
import '../models.dart';
import '../ui.dart';

const _bulanNama = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});
  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late int _tahun;
  late int _bulan;
  List<Attendance> _rows = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tahun = now.year;
    _bulan = now.month;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final r = await api.myHistory(tahun: _tahun, bulan: _bulan);
      if (mounted) setState(() { _rows = r; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.primary,
                    child: _err != null
                        ? _scrollable(ErrorView(msg: _err!, onRetry: _load))
                        : _rows.isEmpty
                            ? _scrollable(const EmptyView(icon: Icons.event_note_rounded, title: 'Belum ada data', subtitle: 'Tidak ada absensi pada bulan ini'))
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(screenPad(context), 20, screenPad(context), bottomGap(context)),
                                itemCount: _rows.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (_, i) => _row(_rows[i]),
                              ),
                  ),
          ),
        ],
      ),
    );
  }

  // Bikin konten pendek (error/kosong) tetap bisa ditarik untuk refresh.
  Widget _scrollable(Widget child) => LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: child,
          ),
        ),
      );

  Widget _header() {
    return Container(
      padding: EdgeInsets.fromLTRB(screenPad(context), topInset(context) + 12, screenPad(context), 18),
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Riwayat Absensi', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          Text('Pilih periode untuk melihat rekap', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 3, child: _dropdown<int>(
                icon: Icons.calendar_month_rounded,
                value: _bulan,
                items: [for (var i = 1; i <= 12; i++) i],
                labelOf: (v) => _bulanNama[v - 1],
                onChanged: (v) { setState(() => _bulan = v!); _load(); },
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _dropdown<int>(
                icon: Icons.event_rounded,
                value: _tahun,
                items: [for (var y = DateTime.now().year; y >= DateTime.now().year - 3; y--) y],
                labelOf: (v) => '$v',
                onChanged: (v) { setState(() => _tahun = v!); _load(); },
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({required IconData icon, required T value, required List<T> items, required String Function(T) labelOf, required ValueChanged<T?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppTheme.rSm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.rSm),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelOf(e), style: const TextStyle(color: AppTheme.ink)))).toList(),
          selectedItemBuilder: (_) => items.map((e) => Row(children: [
            Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 8),
            Expanded(child: Text(labelOf(e), overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ])).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _row(Attendance a) {
    final st = statusStyle(a.status);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Icon(_iconOf(a.status), color: st.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fmtTgl(a.tanggal), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'Masuk ${fmtJam(a.jamMasuk)}  ·  Pulang ${fmtJam(a.jamPulang)}'
                  '${a.durasiMenit > 0 ? '  ·  ${fmtDurasi(a.durasiMenit)}' : ''}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12.5),
                ),
                if (a.menitTelat > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(children: [
                      const Icon(Icons.timelapse_rounded, size: 13, color: AppTheme.warning),
                      const SizedBox(width: 4),
                      Text('Telat ${a.menitTelat} menit', style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ],
            ),
          ),
          Pill(st.label, color: st.color, bg: st.bg),
        ],
      ),
    );
  }

  IconData _iconOf(String s) {
    switch (s) {
      case 'hadir': return Icons.check_rounded;
      case 'terlambat': return Icons.timelapse_rounded;
      case 'izin':
      case 'sakit':
      case 'cuti': return Icons.event_busy_rounded;
      case 'alpha': return Icons.close_rounded;
      default: return Icons.remove_rounded;
    }
  }
}
