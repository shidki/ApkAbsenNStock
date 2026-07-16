// Konfigurasi global aplikasi Absensi Karyawan Andromeda.
//
// Nyambung ke backend FastAPI yang SAMA dengan web shid-konten (backend/app).
// Endpoint yang dipakai:
//   POST /api/auth/apk/absensi-login  → login khusus app absensi
//   GET  /api/auth/me                 → refresh profil
//   GET  /api/absensi/me              → info karyawan (link) + status hari ini
//   POST /api/absensi/clock           → clock in/out (kode dari scan QR kantor)
//   GET  /api/absensi/my/history      → riwayat absensi
//   GET  /api/absensi/my/summary      → dashboard pribadi
//   GET/POST /api/absensi/my/overtime → lembur (lihat / ajukan)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Config {
  // ── ALAMAT BACKEND ──────────────────────────────────────────────
  // Sekarang selalu nunjuk ke server produksi online (bukan lokal lagi).
  //   • Produksi (server online)  → https://api.myandromeda.store   ← AKTIF
  //   • Emulator Android (dev)    → http://10.0.2.2:8000
  //   • HP fisik dev (1 wifi)     → http://<IP-LAPTOP>:8000
  static const String baseHost = 'https://api.myandromeda.store';

  static const String apiBase = '$baseHost/api';
  static const String authBase = '$apiBase/auth';
  static const String absBase = '$apiBase/absensi';
  // Modul stok (Product Management) — dipakai modul Stok di app gabungan.
  static const String pmBase = '$apiBase/product-management';

  // Modul yang wajib dipunya akun buat login di app ini (samain APK di backend).
  static const String requiredModule = 'abs';
  // Permission umbrella modul stok (samain dgn backend product_management).
  static const String stockPerm = 'product_management';

  // ── AUTO-UPDATE (di luar Play Store) ────────────────────────────
  // App cek file JSON ini tiap dibuka. Kalau versi di JSON lebih baru dari
  // versi terpasang → muncul dialog update. Upload file ini + APK ke cPanel.
  // GANTI sesuai domain/subfolder tempat kamu naruh file di cPanel.
  static const String updateManifestUrl =
      'https://myandromeda.store/apkabsensi/update.json';
}

/// Palet & tema aplikasi — teal→cyan, modern, lembut, banyak ruang napas.
class AppTheme {
  static const Color primary = Color(0xFF0D9488); // teal-600
  static const Color primaryDark = Color(0xFF0F766E); // teal-700
  static const Color primaryLight = Color(0xFF2DD4BF); // teal-400
  static const Color accent = Color(0xFF06B6D4); // cyan-500

  static const Color bg = Color(0xFFEFF4F4); // canvas sejuk lembut
  static const Color surface = Colors.white;
  static const Color soft = Color(0xFFF1F6F5);
  static const Color border = Color(0xFFE8EEED);
  static const Color ink = Color(0xFF0B211D);
  static const Color muted = Color(0xFF5B716B);
  static const Color faint = Color(0xFF95A6A0);

  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF06B6D4);

  // Radii standar biar konsisten & membulat.
  static const double rSm = 14, rMd = 18, rLg = 22, rXl = 28;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF06B6D4)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33FFFFFF), Color(0x0DFFFFFF)],
  );

  /// Bayangan lembut buat kartu — dua lapis biar terasa "melayang", bukan kaku berbingkai.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(color: const Color(0xFF0B211D).withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 12)),
        BoxShadow(color: const Color(0xFF0B211D).withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
      ];

  static List<BoxShadow> get softShadow => cardShadow;

  /// Glow lembut berwarna — buat tombol/elemen aksen.
  static List<BoxShadow> glow(Color c, {double blur = 26, double a = 0.34}) =>
      [BoxShadow(color: c.withValues(alpha: a), blurRadius: blur, offset: const Offset(0, 10))];

  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      brightness: Brightness.light,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      fontFamily: 'Roboto',
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.2),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: ink, fontWeight: FontWeight.w800, letterSpacing: -0.4),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: ink),
        bodySmall: TextStyle(color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: soft,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: faint, fontSize: 14),
        labelStyle: const TextStyle(color: muted, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryDark, fontWeight: FontWeight.w700),
        prefixIconColor: muted,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(rSm), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(rSm), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(rSm), borderSide: const BorderSide(color: primary, width: 1.8)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(rSm), borderSide: const BorderSide(color: danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(rSm), borderSide: const BorderSide(color: danger, width: 1.8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          backgroundColor: surface,
          side: const BorderSide(color: border, width: 1.4),
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryDark)),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rLg)),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rLg)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
