import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';

/// رابط ملف JSON تستضيفه أنت (مصفوفة نصوص) لاستيراد رسائل بديلة تلقائياً.
/// اتركه فارغاً لتعطيل الاستيراد (سيُعاد تدوير الرسائل بدل ذلك).
const String kRefillUrl = String.fromEnvironment('MESSAGES_REFILL_URL');
const int kRefillCount = 100;

class MessageStore {
  final SharedPreferences prefs;
  List<String> all = [];
  Set<int> seen = {};
  MessageStore(this.prefs);

  Future<void> load() async {
    final base = (jsonDecode(await rootBundle.loadString('assets/data/messages.json'))
            as List)
        .cast<String>();
    final extra = prefs.getStringList('extra_msgs') ?? [];
    all = [...base, ...extra];
    seen = (prefs.getStringList('seen_msgs') ?? []).map(int.parse).toSet();
  }

  Future<bool> _refill() async {
    if (kRefillUrl.isEmpty) return false;
    try {
      final r = await http.get(Uri.parse(kRefillUrl)).timeout(const Duration(seconds: 10));
      final incoming = (jsonDecode(utf8.decode(r.bodyBytes)) as List).cast<String>();
      final existing = all.toSet();
      final fresh = incoming.where((m) => !existing.contains(m)).take(kRefillCount).toList();
      if (fresh.isEmpty) return false;
      final extra = prefs.getStringList('extra_msgs') ?? [];
      await prefs.setStringList('extra_msgs', [...extra, ...fresh]);
      all.addAll(fresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// يعيد رسالة لم تُعرض من قبل؛ عند النفاد يستورد جديداً، وإن تعذر يبدأ دورة جديدة.
  Future<String> next() async {
    if (all.isEmpty) return 'لا توجد رسائل. أضف ملف messages.json.';
    var unseen = [for (var i = 0; i < all.length; i++) if (!seen.contains(i)) i];
    if (unseen.isEmpty) {
      if (await _refill()) {
        unseen = [for (var i = 0; i < all.length; i++) if (!seen.contains(i)) i];
      } else {
        seen.clear();
        unseen = List.generate(all.length, (i) => i);
      }
    }
    final pick = unseen[Random().nextInt(unseen.length)];
    seen.add(pick);
    await prefs.setStringList('seen_msgs', seen.map((e) => '$e').toList());
    return all[pick];
  }
}

class DailyMessagesScreen extends StatefulWidget {
  const DailyMessagesScreen({super.key});
  @override
  State<DailyMessagesScreen> createState() => _DailyMessagesScreenState();
}

class _DailyMessagesScreenState extends State<DailyMessagesScreen> {
  MessageStore? _store;
  String _msg = '...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = MessageStore(await SharedPreferences.getInstance());
    await s.load();
    _store = s;
    _msg = await s.next();
    if (mounted) setState(() {});
  }

  Future<void> _next() async {
    final m = await _store!.next();
    if (mounted) setState(() => _msg = m);
  }

  @override
  Widget build(BuildContext context) {
    final s = _store;
    return Scaffold(
      appBar: AppBar(title: const Text('رسائل')),
      body: s == null
          ? const Center(child: CircularProgressIndicator(color: C.gold))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: C.navy,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: C.gold, width: 1.5),
                  ),
                  child: Text(_msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, height: 1.9)),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: C.gold, foregroundColor: C.bg),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('رسالة جديدة'),
                    onPressed: _next,
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: C.gold),
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _msg));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('تم النسخ')));
                    },
                  ),
                ]),
                const SizedBox(height: 12),
                Text('عُرضت ${s.seen.length} من ${s.all.length}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            ),
    );
  }
}
