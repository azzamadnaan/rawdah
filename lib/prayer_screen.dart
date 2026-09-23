import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'colors.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});
  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Coordinates _coords = Coordinates(21.4225, 39.8262); // مكة افتراضياً
  String _locNote = 'جارٍ تحديد الموقع...';
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => mounted ? setState(() => _now = DateTime.now()) : null);
    _locate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _locate() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('lat'), lng = prefs.getDouble('lng');
    if (lat != null && lng != null) {
      _coords = Coordinates(lat, lng);
      _locNote = 'آخر موقع محفوظ';
    }
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _locNote = lat == null ? 'الموقع غير مفعّل — عرض مواقيت مكة المكرمة' : _locNote;
      } else {
        final p = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.medium));
        _coords = Coordinates(p.latitude, p.longitude);
        await prefs.setDouble('lat', p.latitude);
        await prefs.setDouble('lng', p.longitude);
        _locNote = 'حسب موقعك الحالي';
      }
    } catch (_) {
      _locNote = 'تعذّر تحديد الموقع';
    }
    if (mounted) setState(() {});
  }

  PrayerTimes _times(DateTime d) => PrayerTimes(
      _coords,
      DateComponents.from(d),
      CalculationMethod.muslim_world_league.getParameters()
        ..madhab = Madhab.shafi);

  List<MapEntry<String, DateTime>> _list(PrayerTimes t) => [
        MapEntry('الفجر', t.fajr.toLocal()),
        MapEntry('الشروق', t.sunrise.toLocal()),
        MapEntry('الظهر', t.dhuhr.toLocal()),
        MapEntry('العصر', t.asr.toLocal()),
        MapEntry('المغرب', t.maghrib.toLocal()),
        MapEntry('العشاء', t.isha.toLocal()),
      ];

  String _hms(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

  String _hm(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'م' : 'ص'}';
  }

  Future<void> _open(String user) => launchUrl(
      Uri.parse('https://instagram.com/@az_zoom_'),
      mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final today = _list(_times(_now));
    var next = today.where((e) => e.value.isAfter(_now)).toList();
    final MapEntry<String, DateTime> nextPrayer = next.isNotEmpty
        ? next.first
        : MapEntry('الفجر', _list(_times(_now.add(const Duration(days: 1)))).first.value);
    final diff = nextPrayer.value.difference(_now);
    final cd = '${diff.inHours.toString().padLeft(2, '0')}:'
        '${(diff.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(diff.inSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: RefreshIndicator(
        color: C.gold,
        onRefresh: _locate,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Text(_hms(_now),
                  style: const TextStyle(
                      fontSize: 44, color: C.gold, fontWeight: FontWeight.bold)),
            ),
            Center(
                child: Text(_locNote,
                    style: const TextStyle(color: Colors.white54, fontSize: 12))),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: C.navy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.gold, width: 1.5),
              ),
              child: Column(children: [
                Text('الصلاة القادمة: ${nextPrayer.key}',
                    style: const TextStyle(fontSize: 18, color: C.white)),
                const SizedBox(height: 8),
                Text(cd,
                    style: const TextStyle(
                        fontSize: 40, color: C.gold, fontWeight: FontWeight.bold)),
                Text('عند ${_hm(nextPrayer.value)}',
                    style: const TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 14),
            ...today.map((e) {
              final isNext = e.key == nextPrayer.key;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: isNext ? C.gold : Colors.transparent, width: 1.2),
                ),
                child: ListTile(
                  leading: Icon(Icons.access_time,
                      color: isNext ? C.gold : Colors.white54),
                  title: Text(e.key, style: const TextStyle(fontSize: 18)),
                  trailing: Text(_hm(e.value),
                      style: const TextStyle(color: C.gold, fontSize: 17)),
                ),
              );
            }),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  const Text('تواصل معنا',
                      style: TextStyle(color: C.gold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    ActionChip(
                        avatar: const Icon(Icons.camera_alt, color: C.gold, size: 18),
                        label: const Text('منصة روضة @hii0i5'),
                        onPressed: () => _open('hii0i5')),
                    ActionChip(
                        avatar: const Icon(Icons.camera_alt, color: C.gold, size: 18),
                        label: const Text('المطوّر @az_zoom_'),
                        onPressed: () => _open('az_zoom_')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            const Text(kRights,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            const Text(kRightsNote,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
