import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anilist_models.dart';

class HistoryEntry {
  final AniListMedia media;
  final int progress;
  final int updatedAt;

  HistoryEntry(
      {required this.media, required this.progress, required this.updatedAt});

  Map<String, dynamic> toJson() => {
        'media': _mediaToJson(media),
        'progress': progress,
        'updatedAt': updatedAt,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        media: AniListMedia.fromJson(json['media']),
        progress: json['progress'],
        updatedAt: json['updatedAt'],
      );
}

class FavoriteEntry {
  final String type; // Needed for tab filtering
  final int id;
  final AniListMedia media;
  final int addedAt;

  FavoriteEntry(
      {required this.type,
      required this.id,
      required this.media,
      required this.addedAt});

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'media': _mediaToJson(media),
        'addedAt': addedAt,
      };

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) => FavoriteEntry(
        type: json['type'] ?? json['media']['type'],
        id: json['id'] ?? json['media']['id'],
        media: AniListMedia.fromJson(json['media']),
        addedAt: json['addedAt'],
      );
}

// A simple manual toJson adapter since the original api parsing didn't require full reverse mapping.
Map<String, dynamic> _mediaToJson(AniListMedia m) {
  return {
    'id': m.id,
    'type': m.type,
    'title': {'romaji': m.title.romaji, 'english': m.title.english},
    'coverImage': {
      'extraLarge': m.coverImage.extraLarge,
      'large': m.coverImage.large
    },
    'bannerImage': m.bannerImage,
    'description': m.description,
    'episodes': m.episodes,
    'chapters': m.chapters,
    'averageScore': m.averageScore,
    'genres': m.genres,
    'status': m.status,
    'format': m.format,
    'studios': {
      'nodes': [
        {'name': m.studio}
      ]
    },
    // Minimally reconstruct the necessary fields to allow caching
  };
}

class LibraryProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  List<FavoriteEntry> _favorites = [];
  List<HistoryEntry> _history = [];
  SharedPreferences? _prefs;

  bool get isLoggedIn => _isLoggedIn;
  List<FavoriteEntry> get favorites => List.unmodifiable(_favorites);
  List<HistoryEntry> get history => List.unmodifiable(_history);

  LibraryProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    _isLoggedIn = _prefs!.getString('mockAniListAuth') == 'true';

    final storedFavs = _prefs!.getString('library_favorites');
    if (storedFavs != null) {
      final List decoded = jsonDecode(storedFavs);
      _favorites = decoded.map((e) => FavoriteEntry.fromJson(e)).toList();
    }

    final storedHist = _prefs!.getString('library_history');
    if (storedHist != null) {
      final List decoded = jsonDecode(storedHist);
      _history = decoded.map((e) => HistoryEntry.fromJson(e)).toList();
    }

    notifyListeners();
  }

  void _saveFavorites() {
    if (_isLoggedIn && _prefs != null) {
      _prefs!.setString('library_favorites',
          jsonEncode(_favorites.map((e) => e.toJson()).toList()));
    }
  }

  void _saveHistory() {
    if (_prefs != null) {
      _prefs!.setString('library_history',
          jsonEncode(_history.map((e) => e.toJson()).toList()));
    }
  }

  void login() {
    _isLoggedIn = true;
    _prefs?.setString('mockAniListAuth', 'true');
    _saveFavorites();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _prefs?.remove('mockAniListAuth');
    _favorites.clear();
    notifyListeners();
  }

  bool isFavorite(int mediaId) {
    return _favorites.any((f) => f.id == mediaId);
  }

  void toggleFavorite(AniListMedia media) {
    if (!_isLoggedIn) return;

    final existingIndex = _favorites.indexWhere((f) => f.id == media.id);
    if (existingIndex >= 0) {
      _favorites.removeAt(existingIndex);
    } else {
      _favorites.add(FavoriteEntry(
          type: media.type,
          id: media.id,
          media: media,
          addedAt: DateTime.now().millisecondsSinceEpoch));
    }

    _saveFavorites();
    notifyListeners();
  }

  void updateHistory(AniListMedia media, int progress) {
    _history.removeWhere((h) => h.media.id == media.id);
    _history.insert(
        0,
        HistoryEntry(
            media: media,
            progress: progress,
            updatedAt: DateTime.now().millisecondsSinceEpoch));

    _saveHistory();
    notifyListeners();
  }

  void removeFromHistory(int mediaId) {
    _history.removeWhere((h) => h.media.id == mediaId);
    _saveHistory();
    notifyListeners();
  }
}
