import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFF121212);
  static const gold = Color(0xFFD4AF37);
  static const navy = Color(0xFF0A192F);
  static const card = Color(0xFF1E293B);
  static const white = Color(0xFFFFFFFF);
}

const String kRights =
    'جميع الحقوق محفوظة © 2026 — لدى المبرمج عزام عدنان المخلافي وإدارة روضة';
const String kRightsNote =
    'حقوق التطبيق وتصميمه وبرمجته محفوظة للمطوّر. أما القرآن الكريم والأذكار النبوية '
    'فهي من كلام الله ورسوله ﷺ، ولا يملكها أحد.';

ThemeData rawdahTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(primary: C.gold, surface: C.card),
      appBarTheme: const AppBarTheme(
        backgroundColor: C.navy,
        foregroundColor: C.gold,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: C.navy,
        selectedItemColor: C.gold,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    );
