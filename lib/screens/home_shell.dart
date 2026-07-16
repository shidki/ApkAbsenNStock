import 'package:flutter/material.dart';
import '../config.dart';
import 'absen_screen.dart';
import 'riwayat_screen.dart';
import 'dashboard_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  final _pages = const [DashboardScreen(), AbsenScreen(), RiwayatScreen()];

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.qr_code_scanner_outlined, Icons.qr_code_scanner_rounded, 'Absen'),
    (Icons.history_outlined, Icons.history_rounded, 'Riwayat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppTheme.cardShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < _items.length; i++) _navItem(i),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i) {
    final sel = _i == i;
    final it = _items[i];
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _i = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: sel ? AppTheme.brandGradient : null,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sel ? it.$2 : it.$1, size: 23, color: sel ? Colors.white : AppTheme.faint),
              const SizedBox(height: 4),
              Text(
                it.$3,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                  color: sel ? Colors.white : AppTheme.faint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
