import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../config.dart';
import '../models.dart';
import '../ui.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MySummary? _s;
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
      final s = await api.mySummary();
      if (mounted) setState(() { _s = s; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final nama = _s?.karyawan ?? user?.nama ?? 'Karyawan';
    final pad = screenPad(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(nama)),
            if (_loading)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
            else if (_err != null)
              SliverFillRemaining(hasScrollBody: false, child: ErrorView(msg: _err!, onRetry: _load))
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, bottomGap(context)),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _TodayCard(s: _s!),
                    const SizedBox(height: 20),
                    const SectionTitle('Rekap Bulan Ini'),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 3, bottom: 12),
                      child: Text(_s!.periode, style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
                    ),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Tinggi tile dikunci -> konsisten & anti-overflow di semua HP.
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 108,
                      ),
                      children: [
                        _Kpi(label: 'Hadir', value: '${_s!.hadir}', icon: Icons.check_circle_rounded, color: AppTheme.success),
                        _Kpi(label: 'Terlambat', value: '${_s!.terlambat}', icon: Icons.timelapse_rounded, color: AppTheme.warning),
                        _Kpi(label: 'Izin/Sakit/Cuti', value: '${_s!.izin + _s!.sakit + _s!.cuti}', icon: Icons.event_busy_rounded, color: AppTheme.info),
                        _Kpi(label: 'Alpha', value: '${_s!.alpha}', icon: Icons.report_gmailerrorred_rounded, color: AppTheme.danger),
                        _Kpi(label: 'Total Telat', value: fmtDurasi(_s!.menitTelat), icon: Icons.hourglass_bottom_rounded, color: AppTheme.warning),
                        _Kpi(label: 'Lembur', value: fmtDurasi(_s!.lemburMenit), icon: Icons.more_time_rounded, color: AppTheme.primary),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SectionTitle('Cuti'),
                    const SizedBox(height: 12),
                    _CutiCard(s: _s!),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(String nama) {
    final pad = screenPad(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        padding: EdgeInsets.fromLTRB(pad, topInset(context) + 16, pad, 22),
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: Stack(
          children: [
            // Aksen cahaya lembut — DI-CLIP di dalam header, jadi nggak bleeding.
            Positioned(top: -50, right: -30, child: _blob(130, 0.10)),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    nama.trim().isEmpty ? 'U' : nama.trim().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo,', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                      Text(nama, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                      Text('${_s?.jabatan ?? '-'} · ${_s?.kode ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _iconBtn(Icons.grid_view_rounded, () => Navigator.of(context).maybePop()),
                const SizedBox(width: 8),
                _iconBtn(Icons.logout_rounded, _confirmLogout),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(padding: const EdgeInsets.all(11), child: Icon(icon, color: Colors.white, size: 20)),
        ),
      );

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Keluar?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Kamu akan keluar dari aplikasi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger, minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) context.read<AuthProvider>().logout();
  }

  Widget _blob(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: alpha), shape: BoxShape.circle),
      );
}

class _TodayCard extends StatelessWidget {
  final MySummary s;
  const _TodayCard({required this.s});
  @override
  Widget build(BuildContext context) {
    final st = statusStyle(s.statusHariIni ?? (s.jamMasuk != null ? 'hadir' : 'alpha'));
    final showPill = s.jamMasuk != null || s.statusHariIni != null;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconChip(Icons.today_rounded, color: AppTheme.primary, gradient: true),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Absen Hari Ini', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink, fontSize: 15.5)),
              ),
              if (showPill) Pill(st.label, color: st.color, bg: st.bg),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _slot(Icons.login_rounded, 'Masuk', fmtJam(s.jamMasuk), AppTheme.success)),
              Container(width: 1, height: 40, color: AppTheme.border),
              Expanded(child: _slot(Icons.logout_rounded, 'Pulang', fmtJam(s.jamPulang), AppTheme.info)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slot(IconData icon, String label, String value, Color color) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.ink, fontSize: 18)),
        ],
      );
}

class _CutiCard extends StatelessWidget {
  final MySummary s;
  const _CutiCard({required this.s});
  @override
  Widget build(BuildContext context) {
    final sisa = (s.kuotaCuti - s.cutiTerpakai).clamp(0, 9999);
    final ratio = s.kuotaCuti > 0 ? sisa / s.kuotaCuti : 0.0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconChip(Icons.beach_access_rounded, color: AppTheme.info),
              const SizedBox(width: 12),
              const Expanded(child: Text('Sisa Cuti Tahun Ini', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink))),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: '$sisa', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 20)),
                  TextSpan(text: ' / ${s.kuotaCuti} hari', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.muted, fontSize: 13)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.toDouble(),
              minHeight: 8,
              backgroundColor: AppTheme.soft,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Kpi({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 19),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.ink, letterSpacing: -0.5)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
