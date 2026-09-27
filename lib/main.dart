import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'colors.dart';
import 'prayer_screen.dart';
import 'ai_chat_screen.dart';
import 'athkar_screen.dart';
import 'quran_screen.dart';
import 'daily_messages_screen.dart';

const _introKey = 'intro_seen_v2';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RawdahApp());
}

class RawdahApp extends StatelessWidget {
  const RawdahApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'روضة',
        debugShowCheckedModeBanner: false,
        theme: rawdahTheme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _vc;
  bool _done = false;
  bool _played = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_introKey) ?? false) return _finish(markSeen: false);
    try {
      final vc = VideoPlayerController.asset('assets/videos/welcome.mp4');
      await vc.initialize().timeout(const Duration(seconds: 10));
      if (vc.value.duration <= Duration.zero) {
        throw Exception('الفيديو صفر ثانية أو تالف');
      }
      vc.addListener(() {
        final v = vc.value;
        if (v.isInitialized &&
            v.duration > Duration.zero &&
            v.position >= v.duration) {
          _finish(markSeen: true);
        }
      });
      if (!mounted) return;
      setState(() => _vc = vc);
      _played = true;
      await vc.play();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _finish({required bool markSeen}) async {
    if (_done || !mounted) return;
    _done = true;
    if (markSeen || _played) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introKey, true);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = _vc;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        if (vc != null && vc.value.isInitialized)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
                width: vc.value.size.width,
                height: vc.value.size.height,
                child: VideoPlayer(vc)),
          )
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 48),
                const SizedBox(height: 12),
                Text('تعذّر تشغيل الفيديو:\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () => _finish(markSeen: false),
                    child: const Text('الدخول للتطبيق')),
              ]),
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: C.gold)),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: C.gold,
                    side: const BorderSide(color: C.gold),
                    backgroundColor: Colors.black54),
                onPressed: () => _finish(markSeen: true),
                child: const Text('تخطي'),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  final _pages = const [
    PrayerScreen(),
    AiChatScreen(),
    AthkarScreen(),
    QuranScreen(),
    DailyMessagesScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _i, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _i,
          onTap: (v) => setState(() => _i = v),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'الصلاة'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'روضة AI'),
            BottomNavigationBarItem(icon: Icon(Icons.bubble_chart), label: 'الأذكار'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'القرآن'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'رسائل'),
          ],
        ),
      );
}
