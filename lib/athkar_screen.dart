import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

// ───────────────────────── النماذج ─────────────────────────

class Dhikr {
  final String text;
  final int count;
  const Dhikr(this.text, this.count);
}

class AthkarCategory {
  final String title;
  final List<Dhikr> items;
  const AthkarCategory(this.title, this.items);
}

// ───────────────────────── البيانات (نسخة تجريبية تُراجع لاحقاً) ─────────────────────────

const _ayatKursi = Dhikr(
    'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ.',
    1);
const _ikhlas = Dhikr(
    'قُلْ هُوَ اللَّهُ أَحَدٌ * اللَّهُ الصَّمَدُ * لَمْ يَلِدْ وَلَمْ يُولَدْ * وَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ.',
    3);
const _falaq = Dhikr(
    'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ * مِنْ شَرِّ مَا خَلَقَ * وَمِنْ شَرِّ غَاسِقٍ إِذَا وَقَبَ * وَمِنْ شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ * وَمِنْ شَرِّ حَاسِدٍ إِذَا حَسَدَ.',
    3);
const _nas = Dhikr(
    'قُلْ أَعُوذُ بِرَبِّ النَّاسِ * مَلِكِ النَّاسِ * إِلَهِ النَّاسِ * مِنْ شَرِّ الْوَسْوَاسِ الْخَنَّاسِ * الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ * مِنَ الْجِنَّةِ وَالنَّاسِ.',
    3);
const _sayyid = Dhikr(
    'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.',
    1);
const _radeetu = Dhikr(
    'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.', 3);
const _bismillah = Dhikr(
    'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.',
    3);
const _ashhadok = Dhikr(
    'اللَّهُمَّ إِنِّي أَشْهَدُكَ وَأُشْهِدُ حَمَلَةَ عَرْشِكَ وَمَلَائِكَتَكَ وَجَمِيعَ خَلْقِكَ أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ.',
    4);
const _tasbihEnd = <Dhikr>[
  Dhikr('سُبْحَانَ اللَّهِ.', 33),
  Dhikr('الْحَمْدُ لِلَّهِ.', 33),
  Dhikr('اللَّهُ أَكْبَرُ.', 34),
];

const _common = <Dhikr>[
  Dhikr('اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ.', 3),
  Dhikr('اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ.', 3),
  Dhikr('حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.', 7),
  Dhikr('اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ وَمِنْ خَلْفِي وَعَنْ يَمِينِي وَعَنْ شِمَالِي وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي.', 1),
  Dhikr('اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءًا أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ.', 1),
  Dhikr('يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.', 1),
  Dhikr('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.', 3),
  Dhikr('لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.', 10),
  Dhikr('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.', 100),
  Dhikr('أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ.', 100),
  Dhikr('اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ.', 10),
];

const athkarDb = <AthkarCategory>[
  AthkarCategory('الصباح', [
    _ayatKursi, _ikhlas, _falaq, _nas,
    Dhikr('أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ.', 1),
    Dhikr('اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.', 1),
    _sayyid,
    _ashhadok,
    Dhikr('اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ.', 1),
    _radeetu,
    _bismillah,
    Dhikr('أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ.', 1),
    Dhikr('اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا.', 1),
    ..._common,
  ]),
  AthkarCategory('المساء', [
    _ayatKursi, _ikhlas, _falaq, _nas,
    Dhikr('أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا.', 1),
    Dhikr('اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ.', 1),
    _sayyid,
    _ashhadok,
    Dhikr('اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ.', 1),
    Dhikr('أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.', 3),
    _radeetu,
    _bismillah,
    Dhikr('أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ ﷺ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ.', 1),
    ..._common,
  ]),
  AthkarCategory('بعد الصلاة', [
    Dhikr('أَسْتَغْفِرُ اللَّهَ.', 3),
    Dhikr('اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ.', 1),
    Dhikr('لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.', 1),
    Dhikr('اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ.', 1),
    ..._tasbihEnd,
    _ayatKursi, _ikhlas, _falaq, _nas,
  ]),
  AthkarCategory('النوم', [
    Dhikr('بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.', 1),
    _ayatKursi, _ikhlas, _falaq, _nas,
    Dhikr('اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.', 3),
    ..._tasbihEnd,
  ]),
  AthkarCategory('الاستيقاظ', [
    Dhikr('الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ.', 1),
    Dhikr('الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي فِي جَسَدِي، وَرَدَّ عَلَيَّ رُوحِي، وَأَذِنَ لِي بِذِكْرِهِ.', 1),
  ]),
];

// ───────────────────────── الشاشة ─────────────────────────

class AthkarScreen extends StatelessWidget {
  const AthkarScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: athkarDb.length + 1,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الأذكار'),
            bottom: TabBar(
              isScrollable: true,
              indicatorColor: C.gold,
              labelColor: C.gold,
              unselectedLabelColor: Colors.white60,
              tabs: [
                for (final c in athkarDb) Tab(text: c.title),
                const Tab(text: 'المسبحة'),
              ],
            ),
          ),
          body: TabBarView(children: [
            for (final c in athkarDb) _DhikrList(items: c.items),
            const _Tasbih(),
          ]),
        ),
      );
}

class _DhikrList extends StatefulWidget {
  final List<Dhikr> items;
  const _DhikrList({required this.items});
  @override
  State<_DhikrList> createState() => _DhikrListState();
}

class _DhikrListState extends State<_DhikrList>
    with AutomaticKeepAliveClientMixin {
  late List<int> _left;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _left = widget.items.map((e) => e.count).toList();
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() => _left = widget.items.map((e) => e.count).toList());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final doneCount = _left.where((e) => e == 0).length;
    return Column(children: [
      Container(
        color: C.navy,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Text('أُنجز $doneCount من ${widget.items.length}',
              style: const TextStyle(color: C.gold)),
          const Spacer(),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, color: C.gold, size: 18),
            label: const Text('إعادة', style: TextStyle(color: C.gold)),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: widget.items.length,
          itemBuilder: (_, i) {
            final done = _left[i] == 0;
            return Card(
              color: done ? C.navy : C.card,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (_left[i] > 0) {
                    HapticFeedback.selectionClick();
                    setState(() => _left[i]--);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Text(widget.items[i].text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20,
                            height: 1.9,
                            color: done ? Colors.white38 : C.white)),
                    const SizedBox(height: 8),
                    Text(
                        done
                            ? '✓ تم'
                            : 'المتبقي: ${_left[i]} من ${widget.items[i].count}',
                        style: const TextStyle(color: C.gold)),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _Tasbih extends StatefulWidget {
  const _Tasbih();
  @override
  State<_Tasbih> createState() => _TasbihState();
}

class _TasbihState extends State<_Tasbih> with AutomaticKeepAliveClientMixin {
  int _count = 0;
  int _target = 33;

  @override
  bool get wantKeepAlive => true;

  void _tap() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    setState(() => _count++);
    if (_count % _target == 0) HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$_count',
            style: const TextStyle(
                fontSize: 64, color: C.gold, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _tap,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.navy,
              border: Border.all(color: C.gold, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x55D4AF37), blurRadius: 24)
              ],
            ),
            child: const Center(
                child: Text('سبّح',
                    style: TextStyle(fontSize: 28, color: C.gold))),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(spacing: 8, children: [
          for (final t in [33, 99, 100])
            ChoiceChip(
              label: Text('$t'),
              selected: _target == t,
              selectedColor: C.gold,
              onSelected: (_) => setState(() => _target = t),
            ),
          ActionChip(
              avatar: const Icon(Icons.refresh, size: 18),
              label: const Text('تصفير'),
              onPressed: () => setState(() => _count = 0)),
        ]),
      ]),
    );
  }
}
