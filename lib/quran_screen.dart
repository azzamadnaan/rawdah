import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';

const _recitersUrls = [
  'https://mp3quran.net/api/v3/reciters?language=ar',
  'https://www.mp3quran.net/api/v3/reciters?language=ar',
  'https://mp3quran.net/api/v3/reciters?language=eng',
];
const _headers = {
  'User-Agent': 'Mozilla/5.0 (Linux; Android 13) Rawdah/1.0',
  'Accept': 'application/json',
};

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

bool _isMsaad(String name) {
  final n = name.replaceAll(' ', '').replaceAll('ـ', '').toLowerCase();
  return n.contains('مسعد') ||
      n.contains('msaad') ||
      n.contains('masaad') ||
      n.contains('massad') ||
      n.contains('mosaad') ||
      n.contains('msad');
}

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
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
  File _file(int n) => File('${_dir.path}/masaad_${_id(n)}.mp3');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _problem = null;
    });
    final docs = await getApplicationDocumentsDirectory();
    _dir = Directory('${docs.path}/quran');
    if (!await _dir.exists()) await _dir.create(recursive: true);
    final prefs = await SharedPreferences.getInstance();

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
        Map? rec;
        for (final e in reciters) {
          if (_isMsaad(e['name'].toString())) {
            rec = e as Map;
            break;
          }
        }
        if (rec == null) {
          lastError = 'لم يُعثر على القارئ في القائمة';
          continue;
        }
        final moshafs = List<Map>.from((rec['moshaf'] as List).map((m) => Map.from(m)));
        moshafs.sort((a, b) => (int.tryParse('${b['surah_total']}') ?? 0)
            .compareTo(int.tryParse('${a['surah_total']}') ?? 0));
        final m = moshafs.first;
        var server = m['server'].toString();
        if (!server.endsWith('/')) server += '/';
        await prefs.setString('rec_name', 'عبد الرحمن مسعد');
        await prefs.setString('rec_server', server);
        await prefs.setString('rec_list', m['surah_list'].toString());
        lastError = '';
        break;
      } catch (e) {
        lastError = e.toString();
      }
    }

    _reciter = prefs.getString('rec_name') ?? '';
    _server = prefs.getString('rec_server') ?? '';
    _available = (prefs.getString('rec_list') ?? '')
        .split(',')
        .where((e) => e.trim().isNotEmpty)
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((e) => e > 0)
        .toSet();

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
    if (_server.isEmpty) return _snack('خادم التلاوات غير متاح. اضغط إعادة المحاولة.');
    try {
      await _player.setUrl('$_server${_id(n)}.mp3');
      setState(() => _playing = n);
      await _player.play();
    } catch (_) {
      _snack('تعذّر التشغيل. تحقق من الإنترنت.');
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
    if (_server.isEmpty) return _snack('خادم التلاوات غير متاح. اضغط إعادة المحاولة.');
    setState(() => _progress[n] = 0);
    final tmp = '${_file(n).path}.part';
    try {
      await _dio.download('$_server${_id(n)}.mp3', tmp,
          onReceiveProgress: (r, t) {
        if (t > 0 && mounted) setState(() => _progress[n] = r / t);
      });
      await File(tmp).rename(_file(n).path);
      _downloaded.add(n);
      _snack('تم تنزيل سورة ${kSurahNames[n - 1]}');
    } catch (_) {
      _snack('فشل التنزيل.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.gold))
          : Column(children: [
              Container(
                width: double.infinity,
                color: C.navy,
                padding: const EdgeInsets.all(8),
                child: _problem == null
                    ? Text('القارئ: $_reciter',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: C.gold))
                    : Column(children: [
                        Text(_problem!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                        TextButton(
                            onPressed: _load,
                            child: const Text('إعادة المحاولة',
                                style: TextStyle(color: C.gold))),
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
                                      icon: const Icon(Icons.offline_pin,
                                          color: Colors.greenAccent),
                                      onPressed: () => _playOffline(n)),
                                  IconButton(
                                      tooltip: 'حذف التنزيل',
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.white54),
                                      onPressed: () => _delete(n)),
                                ] else
                                  IconButton(
                                      tooltip: 'تنزيل هذه السورة',
                                      icon: const Icon(Icons.download, color: Colors.white70),
                                      onPressed: prog == null ? () => _download(n) : null),
                              ]),
                      ),
                    );
                  },
                ),
              ),
              _PlayerBar(
                  player: _player,
                  title: _playing == null ? null : kSurahNames[_playing! - 1]),
            ]),
    );
  }
}

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
