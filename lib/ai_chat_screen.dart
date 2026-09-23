import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'colors.dart';

const String kAiUrl = 'https://text.pollinations.ai/openai';
const String kSystem =
    'أنت "روضة"، مساعد إسلامي. أجب بالعربية الفصحى وبأدب وإيجاز. '
    'التزم بما اتفق عليه أهل السنة والجماعة، واذكر الخلاف الفقهي المعتبر عند وجوده دون ترجيح جازم. '
    'لا تُصدر فتاوى، وانصح بالرجوع لأهل العلم في المسائل الدقيقة. لا تختلق آيات أو أحاديث، '
    'وإن لم تتأكد فقل ذلك صراحة.';

class _Msg {
  final String text;
  final bool user;
  _Msg(this.text, this.user);
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
    _Msg('السلام عليكم ورحمة الله وبركاته، أنا روضة. اسألني في أمور دينك وسأجيبك بما أستطيع.', false)
  ];
  bool _busy = false;

  static const _kb = <List<dynamic>>[
    [['وضوء', 'الوضوء'], 'الوضوء: النية، ثم غسل الكفين، فالمضمضة والاستنشاق، فغسل الوجه، فاليدين إلى المرفقين، فمسح الرأس والأذنين، فغسل الرجلين إلى الكعبين، مع الترتيب والموالاة.'],
    [['صلاة', 'الصلاة', 'صلوات'], 'الصلوات المفروضة خمس: الفجر (ركعتان)، الظهر (4)، العصر (4)، المغرب (3)، العشاء (4).'],
    [['زكاة', 'الزكاة'], 'زكاة المال ربع العشر (2.5%) إذا بلغ النصاب ومرّ عليه حول هجري كامل. راجع جهة الإفتاء في بلدك لتقدير النصاب.'],
    [['صيام', 'صوم', 'رمضان'], 'صيام رمضان فرض على كل مسلم بالغ عاقل قادر، من طلوع الفجر الصادق إلى غروب الشمس مع النية. وللمريض والمسافر الرخصة مع القضاء.'],
    [['استخارة'], 'صلاة الاستخارة ركعتان من غير الفريضة، ثم دعاء الاستخارة الوارد عن النبي ﷺ، ثم المضيّ فيما ينشرح له الصدر مع الأخذ بالأسباب.'],
    [['توبة', 'ذنب', 'ذنوب'], 'باب التوبة مفتوح: إقلاع عن الذنب، وندم عليه، وعزم على عدم العودة، ورد الحقوق لأصحابها إن وُجدت.'],
  ];

  String _local(String q) {
    for (final e in _kb) {
      if ((e[0] as List).cast<String>().any(q.contains)) return e[1] as String;
    }
    return 'الخدمة الذكية غير متاحة الآن ولم أجد إجابة محلية لسؤالك. '
        'للمسائل الفقهية أنصحك بسؤال أهل العلم الموثوقين.';
  }

  Future<String> _answer(String q) async {
    try {
      final history = _msgs.length > 7 ? _msgs.sublist(_msgs.length - 7) : _msgs;
      final r = await http
          .post(Uri.parse(kAiUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'model': 'openai',
                'private': true,
                'messages': [
                  {'role': 'system', 'content': kSystem},
                  for (final m in history)
                    {'role': m.user ? 'user' : 'assistant', 'content': m.text},
                ],
              }))
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        final reply = jsonDecode(utf8.decode(r.bodyBytes))['choices'][0]['message']['content'];
        if (reply is String && reply.trim().isNotEmpty) return reply.trim();
      }
    } catch (_) {}
    return _local(q);
  }

  Future<void> _send() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty || _busy) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(q, true));
      _busy = true;
    });
    final a = await _answer(q);
    if (!mounted) return;
    setState(() {
      _msgs.add(_Msg(a, false));
      _busy = false;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('روضة AI')),
        body: Column(children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF3A2F0B),
            padding: const EdgeInsets.all(10),
            child: const Text(
              'تنبيه: الإجابات إرشادية وتثقيفية وليست فتوى شرعية معتمدة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.gold, fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                return Align(
                  alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: m.user ? C.navy : C.card,
                      borderRadius: BorderRadius.circular(16),
                      border: m.user ? Border.all(color: C.gold, width: 0.8) : null,
                    ),
                    child: SelectableText(m.text, style: const TextStyle(height: 1.6)),
                  ),
                );
              },
            ),
          ),
          if (_busy) const LinearProgressIndicator(color: C.gold),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'اكتب سؤالك...',
                      filled: true,
                      fillColor: C.card,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: C.gold,
                  child: IconButton(icon: const Icon(Icons.send, color: C.bg), onPressed: _send),
                ),
              ]),
            ),
          ),
        ]),
      );
}
