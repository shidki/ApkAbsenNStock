// Apk Absensi — aplikasi kehadiran karyawan Andromeda.
// Nyambung ke backend FastAPI shid-konten (modul /api/absensi).
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'config.dart';
import 'launcher.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  final auth = AuthProvider();
  await auth.boot();
  runApp(ChangeNotifierProvider.value(value: auth, child: const AbsensiApp()));
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Andromeda Absensi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      // Batasi skala teks sistem (0.85–1.2) supaya layout tetap rapi & tidak
      // jebol di HP yang setelan ukuran fontnya sangat besar/kecil.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.2)),
          child: child!,
        );
      },
      home: const _Gate(),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isLoggedIn ? const Launcher() : const LoginScreen();
  }
}
