import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'colors.dart';

const kSurahNames = [
  'الفاتحة','البقرة','آل عمران','النساء','المائدة','الأنعام','الأعراف','الأنفال','التوبة','يونس',
  'هود','يوسف','الرعد','إبراهيم','الحجر','النحل','الإسراء','الكهف','مريم','طه',
  'الأنبياء','الحج','المؤمنون','النور','الفرقان','الشعراء','النمل','القصص','العنكبوت','الروم',
  'لقمان','السجدة','الأحزاب','سبأ','فاطر','يس','الصافات','ص','الزمر','غافر',
  'فصلت','الشورى','الزخرف','الدخان','الجاثية','الأحقاف','محمد','الفتح','الحجرات','ق',
  'الذاريات','الطور','النجم','القمر','الرحمن','الواقعة','الحديد','المجادلة','الحشر','الممتحنة',
  'الصف','الجمعة','المنافقون','التغابن','الطلاق','التحريم','الملك','القلم','الحاقة','المعارج',
  'نوح','الجن','المزمل','المدثر','القيامة','الإنسان','المرسلات','النبأ','النازعات','عبس',
  'التكوير','الانفطار','المطففين','الانشقاق','البروج','الطارق','الأعلى','الغاشية','الفجر','البلد',
  'الشمس','الليل','الضحى','الشرح','التين','العلق','القدر','البينة','الزلزلة','العاديات',
  'القارعة','التكاثر','العصر','الهمزة','الفيل','قريش','الماعون','الكوثر','الكافرون','النصر',
  'المسد','الإخلاص','الفلق','الناس',
];

/// السور الموثّقة فعلياً بصوت عبد الرحمن مسعد (12 سورة فقط، مصدرها Internet Archive).
/// رابط archive.org الرسمي يعيد التوجيه تلقائياً لأقرب خادم متاح.
const _mosaadBase = 'https://archive.org/download/010_20221110';
const Map<int, String> _mosaadSurahs = {
  10: '$_mosaadBase/010.mp3',
  19: '$_mosaadBase/019.mp3',
  23: '$_mosaadBase/023.mp3',
  29: '$_mosaadBase/029.mp3',
  32: '$_mosaadBase/032.mp3',
  49: '$_mosaadBase/049.mp3',
  73: '$_mosaadBase/073.mp3',
  78: '$_mosaadBase/078.mp3',
  87: '$_mosaadBase/087.mp3',
  88: '$_mosaadBase/088.mp3',
  100: '$_mosaadBase/100.mp3',
  107: '$_mosaadBase/107.mp3',
};

const _recitersUrls = [
  'https://mp3quran.net/api/v3/reciters?language=ar',
  'https://www.mp3quran.net/api/v3/reciters?language=ar',
];
const _headers = {
  'User-Agent': 'Mozilla/5.0 (Linux; Android 13) Rawdah/1.0',
  'Accept': 'application/json',
};

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('القرآن الكريم'),
            bottom: const TabBar(
              indicatorColor: C.gold,
              labelColor: C.gold,
              unselectedLabelColor: Colors.white60,
              tabs: [Tab(text: 'المصحف كامل'), Tab(text: 'عبد الرحمن مسعد')],
            ),
          ),
          body: const TabBarView(children: [_FullMushaf(), _MosaadTab()]),
        ),
      );
}

// ═══════════════════ التبويب الأول: مصحف كامل (114 سورة) ═══════════════════

class _FullMushaf extends StatefulWidget {
  const _FullMushaf();
  @override
  State<_FullMushaf> createState() => _FullMushafState();
}

class _FullMushafState extends State<_FullMushaf> {
  final _player = AudioPlayer();
  final _dio = Dio(BaseOptions(headers: _headers));
  Set<int> _available = {};
  final Set<int> _downloaded = {};
  final Map<int, double> _progress = {};
  String _server = '', _reciter = '';
  String? _problem;
  bool _loading = true;
  int? _playing;
  late Directory _dir;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _id(int n) => n.toString().padLeft(3, '0');
  File _file(int n) => File('${_dir.path}/full_${_id(n)}.mp3');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _problem = null;
    });
    final docs = await getApplicationDocumentsDirectory();
    _dir = Directory('${docs.path}/quran');
    if (!await _dir.exists()) await _dir.create(recursive: true);

    String lastError = '';
    for (final url in _recitersUrls) {
      try {
        final r = await http
            .get(Uri.parse(url), headers: _headers)
            .timeout(const Duration(seconds: 25));
        if (r.statusCode != 200) {
          lastError = 'رمز الاستجابة ${r.statusCode}';
          continue;
        }
        final reciters = jsonDecode(utf8.decode(r.bodyBytes))['reciters'] as List;
        Map? best;
        Map? bestMoshaf;
        for (final e in reciters) {
          final moshafs = List<Map>.from((e['moshaf'] as List).map((m) => Map.from(m)));
          for (final m in moshafs) {
            final total = int.tryParse('${m['surah_total']}') ?? 0;
            if (total >= 114) {
              best = e as Map;
              bestMoshaf = m;
              break;
            }
          }
          if (best != null) break;
        }
        if (best == null || bestMoshaf == null) {
          lastError = 'لم يُعثر على مصحف كامل في القائمة';
          continue;
        }
        var server = bestMoshaf['server'].toString();
        if (!server.endsWith('/')) server += '/';
        _reciter = best['name'].toString();
        _server = server;
        _available = (bestMoshaf['surah_list'] ?? '')
            .toString()
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => int.tryParse(e.trim()) ?? 0)
            .where((e) => e > 0)
            .toSet();
        lastError = '';
        break;
      } catch (e) {
        lastError = 'تعذّر الاتصال';
      }
    }

    if (_server.isEmpty) {
      _problem = 'تعذّر الوصول لخادم التلاوات.\nالسبب: $lastError\n'
          'جرّب إيقاف الـ VPN ثم اضغط إعادة المحاولة.';
    }
    for (var n = 1; n <= 114; n++) {
      if (await _file(n).exists()) _downloaded.add(n);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _playOnline(int n) async {
    if (_server.isEmpty) return _snack('الخادم غير متاح. اضغط إعادة المحاولة.');
    try {
      await _player.setUrl('$_server${_id(n)}.mp3');
      setState(() => _playing = n);
      await _player.play();
    } catch (e) {
      _snack('تعذّر التشغيل: $e');
    }
  }

  Future<void> _playOffline(int n) async {
    try {
      await _player.setFilePath(_file(n).path);
      setState(() => _playing = n);
      await _player.play();
    } catch (_) {
      _snack('الملف غير صالح، أعد التنزيل.');
    }
  }

  Future<void> _download(int n) async {
    if (_server.isEmpty) return _snack('الخادم غير متاح. اضغط إعادة المحاولة.');
    setState(() => _progress[n] = 0);
    final tmp = '${_file(n).path}.part';
    try {
      await _dio.download('$_server${_id(n)}.mp3', tmp, onReceiveProgress: (r, t) {
        if (t > 0 && mounted) setState(() => _progress[n] = r / t);
      });
      await File(tmp).rename(_file(n).path);
      _downloaded.add(n);
      _snack('تم تنزيل سورة ${kSurahNames[n - 1]}');
    } catch (e) {
      _snack('فشل التنزيل: $e');
      if (await File(tmp).exists()) await File(tmp).delete();
    }
    if (mounted) setState(() => _progress.remove(n));
  }

  Future<void> _delete(int n) async {
    if (await _file(n).exists()) await _file(n).delete();
    setState(() => _downloaded.remove(n));
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: C.gold));
    return Column(children: [
      Container(
        width: double.infinity,
        color: C.navy,
        padding: const EdgeInsets.all(8),
        child: _problem == null
            ? Text('القارئ: $_reciter',
                textAlign: TextAlign.center, style: const TextStyle(color: C.gold))
            : Column(children: [
                Text(_problem!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                TextButton(
                    onPressed: _load,
                    child: const Text('إعادة المحاولة', style: TextStyle(color: C.gold))),
              ]),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: 114,
          itemBuilder: (_, i) {
            final n = i + 1;
            final ok = _available.isEmpty || _available.contains(n);
            final has = _downloaded.contains(n);
            final prog = _progress[n];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: C.navy,
                    child: Text('$n', style: const TextStyle(color: C.gold))),
                title: Text(kSurahNames[i],
                    style: GoogleFonts.amiriQuran(
                        fontSize: 22, color: _playing == n ? C.gold : C.white)),
                subtitle: prog != null
                    ? LinearProgressIndicator(value: prog, color: C.gold)
                    : (!ok
                        ? const Text('غير متوفرة لهذا القارئ',
                            style: TextStyle(fontSize: 11, color: Colors.white38))
                        : null),
                trailing: (!ok && !has)
                    ? null
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        if (ok)
                          IconButton(
                              tooltip: 'استماع بالإنترنت',
                              icon: const Icon(Icons.play_circle, color: C.gold),
                              onPressed: () => _playOnline(n)),
                        if (has) ...[
                          IconButton(
                              tooltip: 'تشغيل بدون إنترنت',
                              icon: const Icon(Icons.offline_pin, color: Colors.greenAccent),
                              onPressed: () => _playOffline(n)),
                          IconButton(
                              tooltip: 'حذف التنزيل',
                              icon: const Icon(Icons.delete_outline, color: Colors.white54),
                              onPressed: () => _delete(n)),
                        ] else
                          IconButton(
                              tooltip: 'تنزيل',
                              icon: const Icon(Icons.download, color: Colors.white70),
                              onPressed: prog == null ? () => _download(n) : null),
                      ]),
              ),
            );
          },
        ),
      ),
      _PlayerBar(player: _player, title: _playing == null ? null : kSurahNames[_playing! - 1]),
    ]);
  }
}

// ═══════════════════ التبويب الثاني: عبد الرحمن مسعد (12 سورة موثّقة) ═══════════════════

class _MosaadTab extends StatefulWidget {
  const _MosaadTab();
  @override
  State<_MosaadTab> createState() => _MosaadTabState();
}

class _MosaadTabState extends State<_MosaadTab> {
  final _player = AudioPlayer();
  final _dio = Dio();
  final Set<int> _downloaded = {};
  final Map<int, double> _progress = {};
  int? _playing;
  late Directory _dir;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  File _file(int n) => File('${_dir.path}/mosaad_$n.mp3');

  Future<void> _init() async {
    final docs = await getApplicationDocumentsDirectory();
    _dir = Directory('${docs.path}/quran');
    if (!await _dir.exists()) await _dir.create(recursive: true);
    for (final n in _mosaadSurahs.keys) {
      if (await _file(n).exists()) _downloaded.add(n);
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _playOnline(int n) async {
    try {
      await _player.setUrl(_mosaadSurahs[n]!);
      setState(() => _playing = n);
      await _player.play();
    } catch (e) {
      _snack('تعذّر التشغيل: $e');
    }
  }

  Future<void> _playOffline(int n) async {
    try {
      await _player.setFilePath(_file(n).path);
      setState(() => _playing = n);
      await _player.play();
    } catch (_) {
      _snack('الملف غير صالح، أعد التنزيل.');
    }
  }

  Future<void> _download(int n) async {
    setState(() => _progress[n] = 0);
    final tmp = '${_file(n).path}.part';
    try {
      await _dio.download(_mosaadSurahs[n]!, tmp,
          options: Options(headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 13) Rawdah/1.0',
          }), onReceiveProgress: (r, t) {
        if (t > 0 && mounted) setState(() => _progress[n] = r / t);
      });
      await File(tmp).rename(_file(n).path);
      _downloaded.add(n);
      _snack('تم تنزيل سورة ${kSurahNames[n - 1]}');
    } catch (e) {
      _snack('فشل التنزيل: $e');
      if (await File(tmp).exists()) await File(tmp).delete();
    }
    if (mounted) setState(() => _progress.remove(n));
  }

  Future<void> _delete(int n) async {
    if (await _file(n).exists()) await _file(n).delete();
    setState(() => _downloaded.remove(n));
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Center(child: CircularProgressIndicator(color: C.gold));
    final list = _mosaadSurahs.keys.toList()..sort();
    return Column(children: [
      Container(
        width: double.infinity,
        color: C.navy,
        padding: const EdgeInsets.all(10),
        child: const Text(
          'هذا القارئ الشاب لم يسجّل مصحفاً كاملاً بعد. المتوفر حالياً 12 سورة موثّقة فقط.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final n = list[i];
            final has = _downloaded.contains(n);
            final prog = _progress[n];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: C.navy,
                    child: Text('$n', style: const TextStyle(color: C.gold))),
                title: Text(kSurahNames[n - 1],
                    style: GoogleFonts.amiriQuran(
                        fontSize: 22, color: _playing == n ? C.gold : C.white)),
                subtitle: prog != null
                    ? LinearProgressIndicator(value: prog, color: C.gold)
                    : null,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      tooltip: 'استماع بالإنترنت',
                      icon: const Icon(Icons.play_circle, color: C.gold),
                      onPressed: () => _playOnline(n)),
                  if (has) ...[
                    IconButton(
                        tooltip: 'تشغيل بدون إنترنت',
                        icon: const Icon(Icons.offline_pin, color: Colors.greenAccent),
                        onPressed: () => _playOffline(n)),
                    IconButton(
                        tooltip: 'حذف التنزيل',
                        icon: const Icon(Icons.delete_outline, color: Colors.white54),
                        onPressed: () => _delete(n)),
                  ] else
                    IconButton(
                        tooltip: 'تنزيل',
                        icon: const Icon(Icons.download, color: Colors.white70),
                        onPressed: prog == null ? () => _download(n) : null),
                ]),
              ),
            );
          },
        ),
      ),
      _PlayerBar(player: _player, title: _playing == null ? null : kSurahNames[_playing! - 1]),
    ]);
  }
}

// ═══════════════════ شريط التشغيل (مشترك) ═══════════════════

class _PlayerBar extends StatelessWidget {
  final AudioPlayer player;
  final String? title;
  const _PlayerBar({required this.player, this.title});

  @override
  Widget build(BuildContext context) {
    if (title == null) return const SizedBox.shrink();
    return Container(
      color: C.navy,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: StreamBuilder<PlayerState>(
        stream: player.playerStateStream,
        builder: (_, s) {
          final playing = s.data?.playing ?? false;
          return Row(children: [
            IconButton(
                icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: C.gold),
                onPressed: () => playing ? player.pause() : player.play()),
            Expanded(child: Text('سورة $title', style: const TextStyle(color: C.gold))),
          ]);
        },
      ),
    );
  }
}
