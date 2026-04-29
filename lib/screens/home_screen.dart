import 'package:flutter/material.dart';
import '../models/anilist_models.dart';
import '../services/anilist_service.dart';
import '../widgets/hero_slider.dart';
import '../widgets/media_row.dart';

class HomeScreen extends StatefulWidget {
  final String type; // 'ANIME' or 'MANGA'
  final ValueChanged<int> onSelectMedia;

  const HomeScreen({
    Key? key,
    required this.type,
    required this.onSelectMedia,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AniListHomeResponse? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    if (oldWidget.type != widget.type) {
      _fetchData();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AniListService.fetchHomeData(widget.type);
      if (mounted) {
        setState(() {
          _data = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.indigoAccent),
      );
    }

    if (_error != null || _data == null) {
      return Center(
        child: Text("Failed to load: $_error",
            style: const TextStyle(color: Colors.redAccent)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 112), // pb-28
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroSlider(
            items: _data!.trending,
            onSelect: widget.onSelectMedia,
          ),
          const SizedBox(height: 8), // mt-2
          MediaRow(
            title: "New & Trending",
            items: _data!.trending.length > 5 ? _data!.trending.sublist(5) : [],
            onSelect: widget.onSelectMedia,
          ),
          MediaRow(
            title: "Most Popular",
            items: _data!.popular,
            onSelect: widget.onSelectMedia,
          ),
          MediaRow(
            title: "Recently Added",
            items: _data!.recentlyAdded,
            onSelect: widget.onSelectMedia,
          ),
        ],
      ),
    );
  }
}
