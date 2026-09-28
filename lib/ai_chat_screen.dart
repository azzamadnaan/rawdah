import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'colors.dart';

const String _kKey = String.fromEnvironment('GEMINI_API_KEY');
const String _kBaseEnv = String.fromEnvironment('GEMINI_BASE_URL');
const String _kDefaultBase = 'https://generativelanguage.googleapis.com';

String get _base {
  final b = _kBaseEnv.trim().isEmpty ? _kDefaultBase : _kBaseEnv.trim();
  return b.endsWith('/') ? b.substring(0, b.length - 1) : b;
}

const _geminiModels = [
  'gemini-flash-lite-latest',
  'gemini-flash-latest',
  'gemini-2.5-flash-lite',
];

const String kSystem =
    'أنت "روضة"، مساعد إسلامي. أجب بالعربية الفصحى وبأدب وإيجاز. '
    'التزم بما اتفق عليه أهل السنة والجماعة، واذكر الخلاف الفقهي المعتبر عند وجوده دون ترجيح جازم. '
    'لا تُصدر فتاوى، وانصح بالرجوع لأهل العلم في المسائل الدقيقة. لا تختلق آيات أو أحاديث، '
    'وإن لم تتأكد فقل ذلك صراحة.';

const String _imageRule =
    ', any human face must be a smooth blank featureless skin-colored oval '
    'with no eyes, no nose, no mouth, no ears; animals, birds and nature '
    'fully detailed and natural; islamic art style, high quality';

class _Msg {
  final String text;
  final bool user;
  final String? note;
  final String? imageB64;
  _Msg(this.text, this.user, {this.note, this.imageB64});
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
    _Msg(
        'السلام عليكم ورحمة الله وبركاته، أنا روضة. اسألني في أمور دينك، أو اطلب مني رسم صورة (زخرفة، طبيعة، مسجد...) بالضغط على أيقونة الصورة.',
        false)
  ];
  bool _busy = false;
  String _lastError = '';

  static const _kb = <List<dynamic>>[
    [
      ['وضوء', 'الوضوء'],
      'الوضوء: النية، ثم غسل الكفين، فالمضمضة والاستنشاق، فغسل الوجه، فاليدين إلى المرفقين، فمسح الرأس والأذنين، فغسل الرجلين إلى الكعبين، مع الترتيب والموالاة.'
    ],
    [
      ['صلاة', 'الصلاة', 'صلوات'],
      'الصلوات المفروضة خمس: الفجر (ركعتان)، الظهر (4)، العصر (4)، المغرب (3)، العشاء (4).'
    ],
    [
      ['زكاة', 'الزكاة'],
      'زكاة المال ربع العشر (2.5%) إذا بلغ النصاب ومرّ عليه حول هجري كامل. راجع جهة الإفتاء في بلدك لتقدير النصاب.'
    ],
    [
      ['صيام', 'صوم', 'رمضان'],
      'صيام رمضان فرض على كل مسلم بالغ عاقل قادر، من طلوع الفجر الصادق إلى غروب الشمس مع النية. وللمريض والمسافر الرخصة مع القضاء.'
    ],
    [
      ['استخارة'],
      'صلاة الاستخارة ركعتان من غير الفريضة، ثم دعاء الاستخارة الوارد عن النبي ﷺ، ثم المضيّ فيما ينشرح له الصدر مع الأخذ بالأسباب.'
    ],
    [
      ['توبة', 'ذنب', 'ذنوب'],
      'باب التوبة مفتوح: إقلاع عن الذنب، وندم عليه، وعزم على عدم العودة، ورد الحقوق لأصحابها إن وُجدت.'
    ],
  ];

  String _local(String q) {
    for (final e in _kb) {
      if ((e[0] as List).cast<String>().any(q.contains)) return e[1] as String;
    }
    return 'الخدمة الذكية غير متاحة الآن ولم أجد إجابة محلية لسؤالك. '
        'للمسائل الفقهية أنصحك بسؤال أهل العلم الموثوقين.';
  }

  // ───────────── الدردشة النصية ─────────────

  Future<String?> _gemini(List<_Msg> hist) async {
    final usable = _kKey.isNotEmpty || _kBaseEnv.trim().isNotEmpty;
    if (!usable) {
      _lastError = 'المفتاح غير مضبوط في البناء';
      return null;
    }
    final turns = hist.skipWhile((m) => !m.user).toList();
    final contents = [
      for (final m in turns)
        if (m.imageB64 == null && m.text.isNotEmpty)
          {
            'role': m.user ? 'user' : 'model',
            'parts': [
              {'text': m.text}
            ]
          }
    ];
    final headers = {
      'Content-Type': 'application/json',
      if (_kKey.isNotEmpty) 'x-goog-api-key': _kKey,
    };
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': kSystem}
        ]
      },
      'contents': contents,
      'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 900},
    });

    for (final model in _geminiModels) {
      try {
        final r = await http
            .post(Uri.parse('$_base/v1beta/models/$model:generateContent'),
                headers: headers, body: body)
            .timeout(const Duration(seconds: 30));
        if (r.statusCode == 200) {
          final j = jsonDecode(utf8.decode(r.bodyBytes));
          final parts = j['candidates']?[0]?['content']?['parts'] as List?;
          final text = parts?.map((p) => p['text'] ?? '').join('').trim() ?? '';
          if (text.isNotEmpty) return text;
          _lastError = 'رد فارغ (قد يكون حُجب)';
        } else {
          _lastError = 'Gemini ${r.statusCode}';
          if (r.statusCode == 400 || r.statusCode == 403) break;
        }
      } catch (e) {
        _lastError = 'تعذّر الاتصال';
      }
    }
    return null;
  }

  Future<String?> _backup(List<_Msg> hist) async {
    try {
      final r = await http
          .post(Uri.parse('https://gen.pollinations.ai/v1/chat/completions'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'model': 'openai',
                'private': true,
                'messages': [
                  {'role': 'system', 'content': kSystem},
                  for (final m in hist)
                    if (m.imageB64 == null && m.text.isNotEmpty)
                      {
                        'role': m.user ? 'user' : 'assistant',
                        'content': m.text
                      },
                ],
              }))
          .timeout(const Duration(seconds: 25));
      if (r.statusCode == 200) {
        final t = jsonDecode(utf8.decode(r.bodyBytes))['choices'][0]['message']
            ['content'];
        if (t is String && t.trim().isNotEmpty) return t.trim();
      }
    } catch (_) {}
    return null;
  }

  Future<_Msg> _answer(String q) async {
    final hist = _msgs.length > 9
        ? _msgs.sublist(_msgs.length - 9)
        : List<_Msg>.from(_msgs);
    final g = await _gemini(hist);
    if (g != null) return _Msg(g, false);
    final b = await _backup(hist);
    if (b != null) return _Msg(b, false);
    return _Msg(_local(q), false, note: 'إجابة محلية — السبب: $_lastError');
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
      _msgs.add(a);
      _busy = false;
    });
    _scrollDown();
  }

  // ───────────── توليد الصور ─────────────

  Future<void> _generateImage() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty || _busy) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg('🎨 رسم: $q', true));
      _busy = true;
    });

    final full = '$q$_imageRule';
    final enc = Uri.encodeComponent(full);
    final seed = DateTime.now().millisecondsSinceEpoch % 100000;
    final urls = [
      'https://gen.pollinations.ai/image/$enc?model=flux&width=768&height=768&nologo=true&seed=$seed',
      'https://gen.pollinations.ai/image/$enc?model=turbo&width=768&height=768&seed=$seed',
      'https://image.pollinations.ai/prompt/$enc?model=flux&width=768&height=768&nologo=true&seed=$seed',
      'https://image.pollinations.ai/prompt/$enc?width=512&height=512&nologo=true&seed=$seed',
    ];

    List<int>? bytes;
    final errs = <String>[];
    for (final u in urls) {
      try {
        final r = await http.get(Uri.parse(u), headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13) Rawdah/1.0',
        }).timeout(const Duration(seconds: 40));
        final isImg = (r.headers['content-type'] ?? '').startsWith('image');
        if (r.statusCode == 200 && isImg && r.bodyBytes.length > 2000) {
          bytes = r.bodyBytes;
          break;
        }
        errs.add('HTTP ${r.statusCode}');
      } catch (_) {
        errs.add('اتصال/مهلة');
      }
    }
    bytes ??= await _geminiImage(full, errs);

    if (!mounted) return;
    setState(() {
      if (bytes != null) {
        _msgs.add(_Msg('', false, imageB64: base64Encode(bytes!)));
      } else {
        _msgs.add(_Msg('تعذّر توليد الصورة الآن.', false,
            note: 'الأسباب: ${errs.join(' | ')}'));
      }
      _busy = false;
    });
    _scrollDown();
  }

  Future<List<int>?> _geminiImage(String prompt, List<String> errs) async {
    if (_kKey.isEmpty && _kBaseEnv.trim().isEmpty) return null;
    final headers = {
      'Content-Type': 'application/json',
      if (_kKey.isNotEmpty) 'x-goog-api-key': _kKey,
    };
    for (final model in [
      'gemini-2.5-flash-image',
      'gemini-2.0-flash-preview-image-generation'
    ]) {
      try {
        final r = await http
            .post(Uri.parse('$_base/v1beta/models/$model:generateContent'),
                headers: headers,
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {'text': prompt}
                      ]
                    }
                  ],
                  'generationConfig': {
                    'responseModalities': ['TEXT', 'IMAGE']
                  },
                }))
            .timeout(const Duration(seconds: 50));
        if (r.statusCode == 200) {
          final j = jsonDecode(utf8.decode(r.bodyBytes));
          final parts = j['candidates']?[0]?['content']?['parts'] as List?;
          for (final p in parts ?? []) {
            final d = p['inlineData']?['data'] ?? p['inline_data']?['data'];
            if (d is String && d.isNotEmpty) return base64Decode(d);
          }
          errs.add('Gemini بلا صورة');
        } else {
          errs.add('Gemini ${r.statusCode}');
        }
      } catch (_) {
        errs.add('Gemini اتصال');
      }
    }
    return null;
  }

  void _scrollDown() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
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
              'تنبيه: الإجابات إرشادية وتثقيفية وليست فتوى شرعية معتمدة، والصور تُولَّد آلياً فقد تحتوي أخطاء.',
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
                  alignment:
                      m.user ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: m.user ? C.navy : C.card,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          m.user ? Border.all(color: C.gold, width: 0.8) : null,
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (m.imageB64 != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(base64Decode(m.imageB64!)),
                            )
                          else
                            SelectableText(m.text,
                                style: const TextStyle(height: 1.6)),
                          if (m.note != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('(${m.note})',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                            ),
                        ]),
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
                      hintText: 'اكتب سؤالك أو وصف صورة...',
                      filled: true,
                      fillColor: C.card,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'توليد صورة من النص',
                  onPressed: _busy ? null : _generateImage,
                  icon: const Icon(Icons.image, color: C.gold),
                ),
                CircleAvatar(
                  backgroundColor: C.gold,
                  child: IconButton(
                      icon: const Icon(Icons.send, color: C.bg),
                      onPressed: _busy ? null : _send),
                ),
              ]),
            ),
          ),
        ]),
      );
}
