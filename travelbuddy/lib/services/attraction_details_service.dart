// Fetches live information about an attraction using two free, key-less HTTP APIs:
//   1. OpenStreetMap Nominatim  -> address, coordinates, phone, website and opening hours (OSM "opening_hours" tag).
//   2. Wikipedia REST summary   -> a short description and a photo.
// Results are cached in memory so re-opening the same attraction does not make another request. 
// AttractionDetails also has toJson/fromJson so it can be saved for offline use later (local storage / offline support).

import 'dart:convert';

import 'package:http/http.dart' as http;

class AttractionDetails {
  const AttractionDetails({
    this.displayName,
    this.address,
    this.category,
    this.latitude,
    this.longitude,
    this.phone,
    this.website,
    this.openingHoursRaw,
    this.description,
    this.imageUrl,
    this.wikipediaUrl,
  });

  final String? displayName;
  final String? address;
  final String? category;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? website;

  /// The raw OpenStreetMap opening_hours string, e.g. "Mo-Fr 09:00-17:00".
  final String? openingHoursRaw;

  /// Short summary from Wikipedia, when an article exists.
  final String? description;
  final String? imageUrl;
  final String? wikipediaUrl;

  OpeningHours? get openingHours => OpeningHours.tryParse(openingHoursRaw);

  bool get hasAnyData =>
      address != null ||
      phone != null ||
      website != null ||
      openingHoursRaw != null ||
      description != null;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'address': address,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'website': website,
        'openingHoursRaw': openingHoursRaw,
        'description': description,
        'imageUrl': imageUrl,
        'wikipediaUrl': wikipediaUrl,
      };

  factory AttractionDetails.fromJson(Map<String, dynamic> json) {
    return AttractionDetails(
      displayName: json['displayName'] as String?,
      address: json['address'] as String?,
      category: json['category'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      openingHoursRaw: json['openingHoursRaw'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      wikipediaUrl: json['wikipediaUrl'] as String?,
    );
  }
}

class AttractionDetailsService {
  // Nominatim's usage policy requires an identifying User-Agent.
  static const Map<String, String> _headers = {
    'User-Agent': 'TravelBuddy (CSCI 3101U student project) idk what to put here',
    'Accept': 'application/json',
  };
  static const Duration _timeout = Duration(seconds: 12);

  static final Map<String, AttractionDetails> _cache = {};

  /// Looks up [name] (optionally near [location], e.g. "Oshawa, Ontario").
  ///
  /// Returns an [AttractionDetails] whose fields are null when nothing was
  /// found. Throws if the network request itself fails (no internet,
  /// timeout, server error) so the UI can show a retry button.
  static Future<AttractionDetails> fetchDetails({
    required String name,
    String location = '',
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${name.trim().toLowerCase()}|${location.trim().toLowerCase()}';
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final place = await _searchPlace(name, location);
    final extratags = (place?['extratags'] as Map?)?.cast<String, dynamic>() ?? {};
    final addressParts = (place?['address'] as Map?)?.cast<String, dynamic>() ?? {};

    final city = _firstString(addressParts, ['city', 'town', 'village', 'municipality']);

    // Wikipedia is a "nice to have": if it fails we still return OSM data.
    _WikiSummary? wiki;
    try {
      wiki = await _fetchWikipedia(
        name: name,
        wikipediaTag: extratags['wikipedia'] as String?,
        checkWords: _locationWords(location, city),
      );
    } catch (_) {
      wiki = null;
    }

    final details = AttractionDetails(
      displayName: place?['name'] as String?,
      address: place == null ? null : _formatAddress(addressParts, place['display_name'] as String?),
      category: place?['type'] as String?,
      latitude: double.tryParse('${place?['lat']}'),
      longitude: double.tryParse('${place?['lon']}'),
      phone: _firstString(extratags, ['phone', 'contact:phone']),
      website: _firstString(extratags, ['website', 'contact:website', 'url']),
      openingHoursRaw: _firstString(extratags, ['opening_hours']),
      description: wiki?.extract,
      imageUrl: wiki?.imageUrl,
      wikipediaUrl: wiki?.pageUrl,
    );

    _cache[cacheKey] = details;
    return details;
  }

  /// Searches Nominatim, first with the location for accuracy and then with the name alone if that found nothing.
  static Future<Map<String, dynamic>?> _searchPlace(String name, String location) async {
    final queries = <String>{
      if (location.trim().isNotEmpty) '${name.trim()}, ${location.trim()}',
      name.trim(),
    };

    for (final query in queries) {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'extratags': '1',
        'addressdetails': '1',
        'limit': '1',
      });
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception('Place lookup failed (HTTP ${response.statusCode})');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return (decoded.first as Map).cast<String, dynamic>();
      }
    }
    return null;
  }

  static Future<_WikiSummary?> _fetchWikipedia({
    required String name,
    required String? wikipediaTag,
    required Set<String> checkWords,
  }) async {
    var language = 'en';
    var title = name.trim();
    var trusted = false; 

    // OSM stores the article as "en:Article Title".
    if (wikipediaTag != null && wikipediaTag.contains(':')) {
      final split = wikipediaTag.indexOf(':');
      final lang = wikipediaTag.substring(0, split);
      if (lang.length >= 2 && lang.length <= 3) {
        language = lang;
        title = wikipediaTag.substring(split + 1).trim();
        trusted = true;
      }
    }

    final encodedTitle = Uri.encodeComponent(title.replaceAll(' ', '_'));
    final uri = Uri.parse('https://$language.wikipedia.org/api/rest_v1/page/summary/$encodedTitle');
    final response = await http.get(uri, headers: _headers).timeout(_timeout);
    if (response.statusCode != 200) return null;

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (json['type'] == 'disambiguation') return null;

    final extract = (json['extract'] as String?)?.trim();
    if (extract == null || extract.isEmpty) return null;

    if (!trusted && checkWords.isNotEmpty) {
      final haystack = '${json['description'] ?? ''} $extract'.toLowerCase();
      if (!checkWords.any(haystack.contains)) return null;
    }

    final thumbnail = (json['thumbnail'] as Map?)?['source'] as String?;
    final pages = (json['content_urls'] as Map?)?['mobile'] as Map?;
    return _WikiSummary(
      extract: extract,
      imageUrl: thumbnail,
      pageUrl: pages?['page'] as String?,
    );
  }

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String? _formatAddress(Map<String, dynamic> parts, String? fallback) {
    final street = [parts['house_number'], parts['road']]
        .whereType<String>()
        .join(' ');
    final pieces = [
      if (street.isNotEmpty) street,
      _firstString(parts, ['city', 'town', 'village', 'municipality']),
      _firstString(parts, ['state']),
      _firstString(parts, ['postcode']),
    ].whereType<String>().toList();
    if (pieces.length >= 2) return pieces.join(', ');
    return fallback;
  }

  static const Set<String> _genericWords = {
    'park', 'street', 'road', 'avenue', 'downtown', 'city', 'centre',
    'center', 'north', 'south', 'east', 'west', 'ontario', 'canada',
  };

  static Set<String> _locationWords(String location, String? city) {
    final words = <String>{
      if (city != null) city.toLowerCase(),
      ...location
          .toLowerCase()
          .split(RegExp(r'[^a-z]+'))
          .where((word) => word.length >= 4 && !_genericWords.contains(word)),
    };
    return words;
  }
}

class _WikiSummary {
  const _WikiSummary({required this.extract, this.imageUrl, this.pageUrl});

  final String extract;
  final String? imageUrl;
  final String? pageUrl;
}

// ---------------------------------------------------------------------------
// Opening hours
// ---------------------------------------------------------------------------

/// One opening period, in minutes after midnight. If [end] <= [start] the
/// period runs past midnight (e.g. 18:00-02:00).
class TimeRange {
  const TimeRange(this.start, this.end);

  final int start;
  final int end;

  bool get crossesMidnight => end <= start;

  @override
  String toString() => '${formatMinutes(start)} – ${formatMinutes(end)}';

  static String formatMinutes(int minutes) {
    final m = minutes % 1440;
    final hour24 = m ~/ 60;
    final minute = (m % 60).toString().padLeft(2, '0');
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }
}

class DayHours {
  const DayHours({required this.dayName, required this.ranges, required this.isToday});

  final String dayName;

  /// Empty list = closed all day.
  final List<TimeRange> ranges;
  final bool isToday;

  bool get isClosed => ranges.isEmpty;

  String get label {
    if (ranges.isEmpty) return 'Closed';
    if (ranges.length == 1 && ranges.first.start == 0 && ranges.first.end == 1440) {
      return 'Open 24 hours';
    }
    return ranges.join(', ');
  }
}

/// Parses the common forms of the OpenStreetMap opening_hours format, such as
///   "Mo-Fr 09:00-17:00; Sa 10:00-16:00; Su off"
///   "Tu-Su 10:00-17:00"
///   "24/7"
/// Unusual formats (seasons, sunrise/sunset, week numbers) return null from
/// [tryParse]; the UI then just shows the raw text.
class OpeningHours {
  OpeningHours._(this.raw, this._days);

  final String raw;

  /// Index 0 = Monday ... 6 = Sunday.
  final List<List<TimeRange>> _days;

  static const List<String> _dayCodes = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static final RegExp _rulePattern = RegExp(
    r'^((?:Mo|Tu|We|Th|Fr|Sa|Su)(?:\s*[-,]\s*(?:Mo|Tu|We|Th|Fr|Sa|Su))*)\s*(.*)$',
  );
  static final RegExp _timePattern = RegExp(r'^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\+?$');

  static OpeningHours? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.trim();

    if (text == '24/7') {
      return OpeningHours._(text, List.generate(7, (_) => [const TimeRange(0, 1440)]));
    }

    final days = List<List<TimeRange>?>.filled(7, null);
    var anyRule = false;

    for (final part in text.split(';')) {
      // Public/school holiday rules can't be shown on a weekly table.
      final rule = part.trim().replaceAll(RegExp(r',\s*(PH|SH)\b'), '');
      if (rule.isEmpty || rule.startsWith('PH') || rule.startsWith('SH')) continue;

      List<int> targetDays;
      String timePart;
      final match = _rulePattern.firstMatch(rule);
      if (match != null) {
        targetDays = _expandDays(match.group(1)!);
        timePart = match.group(2)!.trim();
      } else {
        targetDays = List.generate(7, (i) => i); 
        timePart = rule;
      }

      final ranges = _parseTimes(timePart);
      if (ranges == null) return null; 
      for (final day in targetDays) {
        days[day] = ranges; 
      }
      anyRule = true;
    }

    if (!anyRule) return null;
    // In OSM, days that are not mentioned are closed.
    return OpeningHours._(text, days.map((d) => d ?? <TimeRange>[]).toList());
  }

  static List<int> _expandDays(String spec) {
    final result = <int>{};
    for (final piece in spec.split(',')) {
      final bounds = piece.split('-').map((s) => s.trim()).toList();
      final start = _dayCodes.indexOf(bounds.first);
      final end = _dayCodes.indexOf(bounds.last);
      if (start < 0 || end < 0) continue;
      var day = start;
      result.add(day);
      while (day != end) {
        day = (day + 1) % 7; // handles wrap-around like "Fr-Mo"
        result.add(day);
      }
    }
    return result.toList();
  }

  static List<TimeRange>? _parseTimes(String text) {
    final lower = text.toLowerCase();
    if (lower == 'off' || lower == 'closed') return <TimeRange>[];
    if (text.isEmpty) return null;

    final ranges = <TimeRange>[];
    for (final piece in text.split(',')) {
      final match = _timePattern.firstMatch(piece.trim());
      if (match == null) return null;
      final start = int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
      final end = int.parse(match.group(3)!) * 60 + int.parse(match.group(4)!);
      ranges.add(TimeRange(start, end));
    }
    return ranges;
  }

  /// Monday-first list of the week with today's row flagged.
  List<DayHours> week([DateTime? now]) {
    final today = (now ?? DateTime.now()).weekday - 1;
    return List.generate(
      7,
      (i) => DayHours(dayName: _dayNames[i], ranges: _days[i], isToday: i == today),
    );
  }

  bool isOpenAt(DateTime time) {
    final day = time.weekday - 1;
    final minutes = time.hour * 60 + time.minute;

    for (final range in _days[day]) {
      if (range.crossesMidnight) {
        if (minutes >= range.start) return true;
      } else if (minutes >= range.start && minutes < range.end) {
        return true;
      }
    }
    final yesterday = (day + 6) % 7;
    for (final range in _days[yesterday]) {
      if (range.crossesMidnight && minutes < range.end) return true;
    }
    return false;
  }
}
