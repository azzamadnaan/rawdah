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

const String kSuwarApi = 'https://mp3quran.net/api/v3/suwar?language=ar';
const String kRecitersApi = 'https://mp3quran.net/api/v3/reciters?language=ar';
const String kReciterKeyword = 'مسعد'; // عبد الرحمن مسعد

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _player = AudioPlayer();
  final _dio = Dio();
  List<String> _names = [];
  Set<int> _available = {};
  final Set<int> _downloaded = {};
  final Map<int, double> _progress = {};
  String _server = '', _reciter = '';
  int? _playing;
  String? _error;
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
    final docs = await getApplicationDocumentsDirectory();
    _dir = Directory('${docs.path}/quran');
    if (!await _dir.exists()) await _dir.create(recursive: true);
    final prefs = await SharedPreferences.getInstance();

    // أسماء السور
    try {
      final r = await http.get(Uri.parse(kSuwarApi)).timeout(const Duration(seconds: 12));
      final list = (jsonDecode(utf8.decode(r.bodyBytes))['suwar'] as List)
          .map((e) => e['name'].toString()).toList();
      if (list.length == 114) {
        _names = list;
        await prefs.setStringList('surah_names', list);
      }
    } catch (_) {}
    if (_names.isEmpty) _names = prefs.getStringList('surah_names') ?? [];

    // القارئ عبد الرحمن مسعد
    try {
      final r = await http.get(Uri.parse(kRecitersApi)).timeout(const Duration(seconds: 15));
      final reciters = jsonDecode(utf8.decode(r.bodyBytes))['reciters'] as List;
      final rec = reciters.firstWhere(
          (e) => e['name'].toString().contains(kReciterKeyword), orElse: () => null);
      if (rec != null) {
        final moshafs = (rec['moshaf'] as List)..sort(
            (a, b) => (b['surah_total'] as int).compareTo(a['surah_total'] as int));
        final m = moshafs.first;
        var server = m['server'].toString();
        if (!server.endsWith('/')) server += '/';
        await prefs.setString('rec_name', rec['name'].toString());
        await prefs.setString('rec_server', server);
        await prefs.setString('rec_list', m['surah_list'].toString());
      }
    } catch (_) {}
    _reciter = prefs.getString('rec_name') ?? '';
    _server = prefs.getString('rec_server') ?? '';
    _available = (prefs.getString('rec_list') ?? '')
        .split(',').where((e) => e.isNotEmpty).map(int.parse).toSet();

    if (_names.isEmpty || _server.isEmpty) {
      _error = 'تعذّر تحميل البيانات. اتصل بالإنترنت لأول مرة.';
    }
    for (var n = 1; n <= 114; n++) {
      if (await _file(n).exists()) _downloaded.add(n);
    }
    if (mounted) setState(() {});
  }

  Future<void> _playOnline(int n) async {
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
    setState(() => _progress[n] = 0);
    final tmp = '${_file(n).path}.part';
    try {
      await _dio.download('$_server${_id(n)}.mp3', tmp, onReceiveProgress: (r, t) {
        if (t > 0 && mounted) setState(() => _progress[n] = r / t);
      });
      await File(tmp).rename(_file(n).path);
      _downloaded.add(n);
      _snack('تم تنزيل سورة ${_names[n - 1]}');
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
      body: _names.isEmpty || _server.isEmpty
          ? Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: () { setState(() => _error = null); _load(); },
                            child: const Text('إعادة المحاولة')),
                      ]))
                  : const CircularProgressIndicator(color: C.gold))
          : Column(children: [
              Container(
                width: double.infinity,
                color: C.navy,
                padding: const EdgeInsets.all(8),
                child: Text('القارئ: $_reciter',
                    textAlign: TextAlign.center, style: const TextStyle(color: C.gold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _names.length,
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
                        title: Text(_names[i],
                            style: GoogleFonts.amiriQuran(
                                fontSize: 22, color: _playing == n ? C.gold : C.white)),
                        subtitle: prog != null
                            ? LinearProgressIndicator(value: prog, color: C.gold)
                            : (!ok ? const Text('غير متوفرة لهذا القارئ',
                                style: TextStyle(fontSize: 11, color: Colors.white38)) : null),
                        trailing: !ok
                            ? null
                            : Row(mainAxisSize: MainAxisSize.min, children: [
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
                                      tooltip: 'تنزيل هذه السورة',
                                      icon: const Icon(Icons.download, color: Colors.white70),
                                      onPressed: prog == null ? () => _download(n) : null),
                              ]),
                      ),
                    );
                  },
                ),
              ),
              _PlayerBar(player: _player, title: _playing == null ? null : _names[_playing! - 1]),
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
