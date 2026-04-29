import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/custom_api_models.dart';

class CustomApiService {
  static const String animeBaseUrl = 'https://moruro-api-v2.vercel.app';
  static const String mangaBaseUrl = 'https://weebcentral-scraper.vercel.app';

  // --- ANIME ---
  static Future<List<CustomEpisode>> fetchEpisodes(int anilistId) async {
    final res =
        await http.get(Uri.parse('$animeBaseUrl/api/episodes?id=$anilistId'));
    if (res.statusCode != 200) throw Exception('Failed to fetch episodes');

    final data = jsonDecode(res.body);
    final List episodesList = data['episodes'] ?? [];
    return episodesList.map((e) => CustomEpisode.fromJson(e)).toList();
  }

  static Future<CustomStream> fetchStream(
      int anilistId, int ep, String server, String type) async {
    final res = await http.get(Uri.parse(
        '$animeBaseUrl/api/stream?id=$anilistId&ep=$ep&server=$server&type=$type'));
    if (res.statusCode != 200) throw Exception('Failed to fetch stream');
    return CustomStream.fromJson(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>?> fetchAniSkip(
      int anilistId, num episode) async {
    try {
      final anilistRes = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': 'query(\$id: Int) { Media(id: \$id) { idMal } }',
          'variables': {'id': anilistId}
        }),
      );
      if (anilistRes.statusCode != 200) return null;
      final malId = jsonDecode(anilistRes.body)['data']?['Media']?['idMal'];
      if (malId == null) return null;

      final url =
          'https://corsproxy.io/?https://api.aniskip.com/v2/skip-times/$malId/episode/${episode.toInt()}?types=op&types=ed&types=recap&episodeLength=0';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body);
    } catch (e) {
      return null;
    }
  }

  // --- MANGA ---
  static Future<List<CustomChapter>> fetchMangaChapters(int anilistId) async {
    final res = await http
        .get(Uri.parse('$mangaBaseUrl/api/chapter-list?id=$anilistId'));
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch manga chapters');
    }

    final data = jsonDecode(res.body);
    final List chaptersList = data['chapters'] ?? [];

    var mappedChapters =
        chaptersList.map((c) => CustomChapter.fromJson(c)).toList();
    // Sort ascending so chapter 1 starts first (Exactly like we fixed in Web!)
    mappedChapters.sort((a, b) => a.number.compareTo(b.number));
    return mappedChapters;
  }

  static Future<List<String>> fetchMangaPages(
      int anilistId, int chapterNum) async {
    final res = await http.get(
        Uri.parse('$mangaBaseUrl/api/chapters?id=$anilistId&cp=$chapterNum'));
    if (res.statusCode != 200) throw Exception('Failed to fetch manga pages');

    final data = jsonDecode(res.body);
    final List imagesList = data['images'] ?? [];
    return imagesList.cast<String>();
  }
}
