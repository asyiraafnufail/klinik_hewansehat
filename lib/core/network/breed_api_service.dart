import 'dart:convert';
import 'package:http/http.dart' as http;

class BreedApiService {
  static const _defaultHeaders = {
    'User-Agent': 'KlinikHewanSehat/1.0 (Flutter)',
    'Accept': 'application/json',
  };

  final http.Client _client;

  BreedApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch dan parse JSON ras hewan dari Public REST API
  Future<List<String>> fetchBreedsBySpecies(String species) async {
    final normalized = species.trim().toLowerCase();
    if (normalized == 'kucing') {
      final response = await _client
          .get(
            Uri.parse('https://api.thecatapi.com/v1/breeds'),
            headers: _defaultHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data ras kucing (${response.statusCode})');
      }
      final list = parseCatBreedsJson(response.body);
      return ['Campuran / Lokal', 'Domestik / Kampung', ...list];
    }

    if (normalized == 'anjing') {
      final response = await _client
          .get(
            Uri.parse('https://dog.ceo/api/breeds/list/all'),
            headers: _defaultHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data ras anjing (${response.statusCode})');
      }
      final list = parseDogBreedsJson(response.body);
      return ['Campuran / Lokal', ...list];
    }

    return fallbackBreedsFor(species);
  }

  /// Daftar ras umum sebagai fallback bila perangkat offline / API publik tidak terjangkau
  static List<String> fallbackBreedsFor(String species) {
    switch (species.trim().toLowerCase()) {
      case 'kucing':
        return [
          'Campuran / Lokal',
          'Domestik / Kampung',
          'Persia',
          'Anggora',
          'British Shorthair',
          'Scottish Fold',
          'Maine Coon',
          'Bengal',
          'Ragdoll',
          'Siamese',
          'Munchkin',
          'Himalaya',
          'Sphynx',
          'Russian Blue',
          'Lainnya',
        ];
      case 'anjing':
        return [
          'Campuran / Lokal',
          'Anjing Kampung / Kintamani',
          'Golden Retriever',
          'Labrador Retriever',
          'Poodle',
          'Pomeranian',
          'Siberian Husky',
          'Shih Tzu',
          'Beagle',
          'Welsh Corgi',
          'Chihuahua',
          'French Bulldog',
          'German Shepherd',
          'Maltese',
          'Pug',
          'Lainnya',
        ];
      case 'kelinci':
        return ['Anggora', 'Holland Lop', 'Rex', 'Flemish Giant', 'Netherland Dwarf', 'Lokal', 'Lainnya'];
      case 'burung':
        return ['Lovebird', 'Kenari', 'Parkit', 'Murai Batu', 'Cockatiel', 'Kacer', 'Lainnya'];
      default:
        return ['Campuran / Lokal', 'Lainnya'];
    }
  }

  static List<String> parseCatBreedsJson(String rawBody) {
    final decoded = jsonDecode(rawBody) as List<dynamic>;
    final names = decoded
        .map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    names.sort();
    return names;
  }

  static List<String> parseDogBreedsJson(String rawBody) {
    final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
    final message = decoded['message'] as Map<String, dynamic>? ?? {};
    final breeds = <String>[];
    for (final entry in message.entries) {
      final base = _capitalize(entry.key);
      final subs = (entry.value as List<dynamic>).cast<String>();
      if (subs.isEmpty) {
        breeds.add(base);
      } else {
        for (final sub in subs) {
          breeds.add('$base (${_capitalize(sub)})');
        }
      }
    }
    breeds.sort();
    return breeds;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
