import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anilist_models.dart';

class AniListHomeResponse {
  final List<AniListMedia> trending;
  final List<AniListMedia> popular;
  final List<AniListMedia> recentlyAdded;

  AniListHomeResponse({
    required this.trending,
    required this.popular,
    required this.recentlyAdded,
  });
}

class AniListService {
  static const String _url = 'https://graphql.anilist.co';

  static const String _homeQuery = '''
    query (\$type: MediaType) {
      trending: Page(page: 1, perPage: 15) {
        media(type: \$type, sort: TRENDING_DESC, isAdult: false) {
          id title { romaji english } coverImage { extraLarge large } bannerImage description episodes chapters genres averageScore status format
        }
      }
      popular: Page(page: 1, perPage: 15) {
        media(type: \$type, sort: POPULARITY_DESC, isAdult: false) {
          id title { romaji english } coverImage { large } episodes chapters averageScore status format
        }
      }
      recentlyAdded: Page(page: 1, perPage: 15) {
        media(type: \$type, sort: UPDATED_AT_DESC, status: RELEASING, isAdult: false) {
          id title { romaji english } coverImage { large } episodes chapters status format
        }
      }
    }
  ''';

  static Future<AniListHomeResponse> fetchHomeData(String type) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        'query': _homeQuery,
        'variables': {'type': type}
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['errors'] != null) throw Exception(json['errors'][0]['message']);

      final data = json['data'];
      return AniListHomeResponse(
        trending: (data['trending']['media'] as List)
            .map((e) => AniListMedia.fromJson(e))
            .toList(),
        popular: (data['popular']['media'] as List)
            .map((e) => AniListMedia.fromJson(e))
            .toList(),
        recentlyAdded: (data['recentlyAdded']['media'] as List)
            .map((e) => AniListMedia.fromJson(e))
            .toList(),
      );
    } else {
      throw Exception('Failed to load AniList home data');
    }
  }

  static const String _searchQuery = '''
    query (\$search: String, \$type: MediaType) {
      Page(page: 1, perPage: 30) {
        media(search: \$search, type: \$type, sort: SEARCH_MATCH, isAdult: false) {
          id title { romaji english } coverImage { large } type averageScore status format
        }
      }
    }
  ''';

  static Future<List<AniListMedia>> searchMedia(
      String query, String type) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        'query': _searchQuery,
        'variables': {'search': query, 'type': type}
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['errors'] != null) throw Exception(json['errors'][0]['message']);
      return (json['data']['Page']['media'] as List)
          .map((e) => AniListMedia.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load search results');
    }
  }

  static const String _detailsQuery = '''
    query (\$id: Int) {
      Media(id: \$id) {
        id idMal type title { romaji english } coverImage { extraLarge large } bannerImage description episodes chapters status averageScore format genres
        nextAiringEpisode { airingAt timeUntilAiring episode }
        trailer { id site thumbnail }
        studios(isMain: true) { nodes { name } }
        characters(sort: ROLE, perPage: 15) { edges { role node { id name { full } image { large } } } }
        staff(perPage: 15) { edges { role node { id name { full } image { large } } } }
        recommendations(perPage: 10, sort: RATING_DESC) { nodes { mediaRecommendation { id title { romaji english } coverImage { large } averageScore type format status } } }
      }
    }
  ''';

  static Future<AniListMedia> getMediaDetails(int id) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        'query': _detailsQuery,
        'variables': {'id': id}
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['errors'] != null) throw Exception(json['errors'][0]['message']);
      return AniListMedia.fromJson(json['data']['Media']);
    } else {
      throw Exception('Failed to load media details');
    }
  }
}
