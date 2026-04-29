class TitleInfo {
  final String romaji;
  final String? english;

  TitleInfo({required this.romaji, this.english});

  String get display =>
      english != null && english!.isNotEmpty ? english! : romaji;

  factory TitleInfo.fromJson(Map<String, dynamic> json) {
    return TitleInfo(
      romaji: json['romaji'] ?? '',
      english: json['english'],
    );
  }
}

class CoverImage {
  final String extraLarge;
  final String large;

  CoverImage({required this.extraLarge, required this.large});

  factory CoverImage.fromJson(Map<String, dynamic> json) {
    return CoverImage(
      extraLarge: json['extraLarge'] ?? '',
      large: json['large'] ?? '',
    );
  }
}

class Character {
  final int id;
  final String name;
  final String image;
  final String role;

  Character(
      {required this.id,
      required this.name,
      required this.image,
      required this.role});
}

class NextAiringEpisode {
  final int airingAt;
  final int timeUntilAiring;
  final int episode;

  NextAiringEpisode(
      {required this.airingAt,
      required this.timeUntilAiring,
      required this.episode});

  factory NextAiringEpisode.fromJson(Map<String, dynamic> json) {
    return NextAiringEpisode(
      airingAt: json['airingAt'] ?? 0,
      timeUntilAiring: json['timeUntilAiring'] ?? 0,
      episode: json['episode'] ?? 0,
    );
  }
}

class Trailer {
  final String id;
  final String site;
  final String thumbnail;

  Trailer({required this.id, required this.site, required this.thumbnail});

  factory Trailer.fromJson(Map<String, dynamic> json) {
    return Trailer(
      id: json['id'] ?? '',
      site: json['site'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }
}

class AniListMedia {
  final int id;
  final int? idMal;
  final String type;
  final TitleInfo title;
  final CoverImage coverImage;
  final String? bannerImage;
  final String description;
  final int? episodes;
  final int? chapters;
  final int? averageScore;
  final List<String> genres;
  final String status;
  final String format;
  final NextAiringEpisode? nextAiringEpisode;
  final Trailer? trailer;
  final String studio;
  final List<Character> characters;
  final List<AniListMedia> recommendations;

  AniListMedia({
    required this.id,
    this.idMal,
    required this.type,
    required this.title,
    required this.coverImage,
    this.bannerImage,
    required this.description,
    this.episodes,
    this.chapters,
    this.averageScore,
    required this.genres,
    required this.status,
    required this.format,
    this.nextAiringEpisode,
    this.trailer,
    required this.studio,
    required this.characters,
    required this.recommendations,
  });

  factory AniListMedia.fromJson(Map<String, dynamic> json) {
    String studioName = '';
    if (json['studios'] != null &&
        json['studios']['nodes'] != null &&
        (json['studios']['nodes'] as List).isNotEmpty) {
      studioName = json['studios']['nodes'][0]['name'] ?? '';
    }

    List<Character> mappedChars = [];
    if (json['characters'] != null && json['characters']['edges'] != null) {
      for (var edge in json['characters']['edges']) {
        mappedChars.add(Character(
          id: edge['node']['id'],
          name: edge['node']['name']['full'],
          image: edge['node']['image']['large'],
          role: edge['role'] ?? 'UNKNOWN',
        ));
      }
    }

    List<AniListMedia> mappedRecs = [];
    if (json['recommendations'] != null &&
        json['recommendations']['nodes'] != null) {
      for (var node in json['recommendations']['nodes']) {
        if (node['mediaRecommendation'] != null) {
          try {
            // Just basic mapping for recs
            mappedRecs.add(AniListMedia.fromJson(node['mediaRecommendation']));
          } catch (e) {
            // skip broken recs
          }
        }
      }
    }

    return AniListMedia(
      id: json['id'] ?? 0,
      idMal: json['idMal'],
      type: json['type'] ?? 'ANIME',
      title: TitleInfo.fromJson(json['title'] ?? {}),
      coverImage: CoverImage.fromJson(json['coverImage'] ?? {}),
      bannerImage: json['bannerImage'],
      description: json['description'] ?? '',
      episodes: json['episodes'],
      chapters: json['chapters'],
      averageScore: json['averageScore'],
      genres: List<String>.from(json['genres'] ?? []),
      status: json['status'] ?? '',
      format: json['format'] ?? '',
      nextAiringEpisode: json['nextAiringEpisode'] != null
          ? NextAiringEpisode.fromJson(json['nextAiringEpisode'])
          : null,
      trailer:
          json['trailer'] != null ? Trailer.fromJson(json['trailer']) : null,
      studio: studioName,
      characters: mappedChars,
      recommendations: mappedRecs,
    );
  }
}

class AniListHomeResponse {
  final List<AniListMedia> trending;
  final List<AniListMedia> popular;
  final List<AniListMedia> recentlyAdded;

  AniListHomeResponse(
      {required this.trending,
      required this.popular,
      required this.recentlyAdded});
}
