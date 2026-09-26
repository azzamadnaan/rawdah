import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'colors.dart';

enum _St { loading, needPermission, needGps, error, ready }

const _names = {
  'Fajr': 'الفجر',
  'Sunrise': 'الشروق',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};
const _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});
  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  _St _st = _St.loading;
  Map<String, String> _today = {}, _tomorrow = {};
  String _method = '';
  String _city = '';
  int _loadedDay = 0;
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      if (_st == _St.ready && _now.day != _loadedDay) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  /// اسم المدينة الفعلي من إحداثيات المستخدم (خدمة مجانية بدون مفتاح).
  Future<String> _cityName(double lat, double lng, SharedPreferences prefs) async {
    final key = 'city_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';
    try {
      final r = await http.get(Uri.parse(
              'https://api.bigdatacloud.net/data/reverse-geocode-client'
              '?latitude=$lat&longitude=$lng&localityLanguage=ar'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final j = jsonDecode(utf8.decode(r.bodyBytes));
        final parts = <String>[
          for (final k in ['city', 'locality', 'principalSubdivision', 'countryName'])
            if ((j[k] ?? '').toString().trim().isNotEmpty) j[k].toString().trim()
        ];
        final uniq = <String>[];
        for (final p in parts) {
          if (!uniq.contains(p)) uniq.add(p);
        }
        if (uniq.isNotEmpty) {
          final s = uniq.take(3).join('، ');
          await prefs.setString(key, s);
          return s;
        }
      }
    } catch (_) {}
    return prefs.getString(key) ?? '';
  }

  Future<Map<String, String>?> _fetch(
      DateTime d, double lat, double lng, SharedPreferences prefs) async {
    final ds = '${_two(d.day)}-${_two(d.month)}-${d.year}';
    final key = 'times_${lat.toStringAsFixed(1)}_${lng.toStringAsFixed(1)}_$ds';
    try {
      final r = await http
          .get(Uri.parse(
              'https://api.aladhan.com/v1/timings/$ds?latitude=$lat&longitude=$lng'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body)['data'];
        final t = Map<String, dynamic>.from(data['timings']);
        final out = <String, String>{
          for (final k in _names.keys) k: t[k].toString().substring(0, 5),
          '_method': data['meta']['method']['name'].toString(),
        };
        await prefs.setString(key, jsonEncode(out));
        return out;
      }
    } catch (_) {}
    final c = prefs.getString(key);
    return c == null ? null : Map<String, String>.from(jsonDecode(c));
  }

  Future<void> _load() async {
    if (mounted) setState(() => _st = _St.loading);
    final prefs = await SharedPreferences.getInstance();
    Position? p;
    _St? fail;

    if (!await Geolocator.isLocationServiceEnabled()) {
      fail = _St.needGps;
    } else {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        fail = _St.needPermission;
      } else {
        try {
          p = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 20));
        } catch (_) {
          fail = _St.error;
        }
      }
    }

    double? lat = p?.latitude, lng = p?.longitude;
    if (lat == null || lng == null) {
      lat = prefs.getDouble('lat');
      lng = prefs.getDouble('lng');
    } else {
      await prefs.setDouble('lat', lat);
      await prefs.setDouble('lng', lng);
    }
    if (lat == null || lng == null) {
      if (mounted) setState(() => _st = fail ?? _St.error);
      return;
    }

    final today = await _fetch(DateTime.now(), lat, lng, prefs);
    final tom = await _fetch(
        DateTime.now().add(const Duration(days: 1)), lat, lng, prefs);
    final city = await _cityName(lat, lng, prefs);
    if (!mounted) return;
    if (today == null) {
      setState(() => _st = _St.error);
      return;
    }
    setState(() {
      _today = today;
      _tomorrow = tom ?? today;
      _method = today['_method'] ?? '';
      _city = city;
      _loadedDay = DateTime.now().day;
      _st = _St.ready;
    });
  }

  DateTime _dt(DateTime d, String hm) {
    final p = hm.split(':');
    return DateTime(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]));
  }

  String _hms(DateTime d) =>
      '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

  String _hm(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${_two(d.minute)} ${d.hour >= 12 ? 'م' : 'ص'}';
  }

  Future<void> _open(String user) => launchUrl(
      Uri.parse('https://instagram.com/$user'),
      mode: LaunchMode.externalApplication);

  Widget _stateView() {
    String msg;
    String btn = 'إعادة المحاولة';
    VoidCallback action = _load;
    switch (_st) {
      case _St.needPermission:
        msg = 'لحساب مواقيت الصلاة بدقة نحتاج إذن الموقع.';
        btn = 'السماح بالموقع';
        action = () async {
          final perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.deniedForever) {
            await Geolocator.openAppSettings();
          } else {
            _load();
          }
        };
        break;
      case _St.needGps:
        msg = 'خدمة الموقع (GPS) مغلقة. فعّلها لعرض مواقيت مدينتك.';
        btn = 'فتح إعدادات الموقع';
        action = () async {
          await Geolocator.openLocationSettings();
          _load();
        };
        break;
      case _St.error:
        msg = 'تعذّر جلب المواقيت. تحقق من الإنترنت والموقع ثم أعد المحاولة.';
        break;
      default:
        return const Center(child: CircularProgressIndicator(color: C.gold));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on, color: C.gold, size: 64),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 16),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: C.gold, foregroundColor: C.bg),
              onPressed: action,
              child: Text(btn)),
          const SizedBox(height: 24),
          const Text(kRights,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: _st != _St.ready ? _stateView() : _ready(),
    );
  }

  Widget _ready() {
    final list = [
      for (final k in _names.keys) MapEntry(k, _dt(_now, _today[k]!))
    ];
    String nextKey = 'Fajr';
    DateTime nextTime =
        _dt(_now.add(const Duration(days: 1)), _tomorrow['Fajr']!);
    for (final k in _prayers) {
      final t = _dt(_now, _today[k]!);
      if (t.isAfter(_now)) {
        nextKey = k;
        nextTime = t;
        break;
      }
    }
    final diff = nextTime.difference(_now);
    final cd =
        '${_two(diff.inHours)}:${_two(diff.inMinutes % 60)}:${_two(diff.inSeconds % 60)}';

    return RefreshIndicator(
      color: C.gold,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Center(
              child: Text(_hms(_now),
                  style: const TextStyle(
                      fontSize: 44, color: C.gold, fontWeight: FontWeight.bold))),
          Center(
              child: Text(
                  _city.isEmpty ? 'حسب موقعك الحالي' : '📍 $_city',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: C.white, fontSize: 15))),
          Center(
              child: Text('طريقة الحساب: $_method',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 11))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: C.navy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.gold, width: 1.5)),
            child: Column(children: [
              Text('الصلاة القادمة: ${_names[nextKey]}',
                  style: const TextStyle(fontSize: 18, color: C.white)),
              const SizedBox(height: 8),
              Text(cd,
                  style: const TextStyle(
                      fontSize: 40, color: C.gold, fontWeight: FontWeight.bold)),
              Text('عند ${_hm(nextTime)}',
                  style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 14),
          ...list.map((e) {
            final isNext = e.key == nextKey;
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: isNext ? C.gold : Colors.transparent, width: 1.2)),
              child: ListTile(
                leading: Icon(Icons.access_time,
                    color: isNext ? C.gold : Colors.white54),
                title: Text(_names[e.key]!, style: const TextStyle(fontSize: 18)),
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
                      label: const Text('منصة روضة @raw.da_h'),
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
    );
  }
}
