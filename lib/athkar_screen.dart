import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

class Dhikr {
  final String text;
  final int count;
  const Dhikr(this.text, this.count);
}

// نماذج موثقة؛ أكمل بقية الأذكار من مصدر موثوق (مثل حصن المسلم) بنفس الصيغة.
const morning = [
  Dhikr('أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ.', 1),
  Dhikr('اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.', 1),
  Dhikr('رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.', 3),
  Dhikr('بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.', 3),
  Dhikr('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.', 100),
];

const evening = [
  Dhikr('أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ.', 1),
  Dhikr('اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ.', 1),
  Dhikr('أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.', 3),
  Dhikr('رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا.', 3),
  Dhikr('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.', 100),
];

class AthkarScreen extends StatelessWidget {
  const AthkarScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الأذكار'),
            bottom: const TabBar(
              indicatorColor: C.gold,
              labelColor: C.gold,
              unselectedLabelColor: Colors.white60,
              tabs: [Tab(text: 'الصباح'), Tab(text: 'المساء'), Tab(text: 'المسبحة')],
            ),
          ),
          body: const TabBarView(children: [
            _DhikrList(items: morning),
            _DhikrList(items: evening),
            _Tasbih(),
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

class _DhikrListState extends State<_DhikrList> with AutomaticKeepAliveClientMixin {
  late final List<int> _left = widget.items.map((e) => e.count).toList();
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
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
                Text(done ? '✓ تم' : 'المتبقي: ${_left[i]}',
                    style: const TextStyle(color: C.gold)),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _Tasbih extends StatefulWidget {
  const _Tasbih();
  @override
  State<_Tasbih> createState() => _TasbihState();
}

class _TasbihState extends State<_Tasbih> with AutomaticKeepAliveClientMixin {
  int _count = 0, _target = 33;
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
            style: const TextStyle(fontSize: 64, color: C.gold, fontWeight: FontWeight.bold)),
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
              boxShadow: const [BoxShadow(color: Color(0x55D4AF37), blurRadius: 24)],
            ),
            child: const Center(
                child: Text('سبّح', style: TextStyle(fontSize: 28, color: C.gold))),
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
