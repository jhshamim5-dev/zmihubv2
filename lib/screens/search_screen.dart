import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/anilist_models.dart';
import '../services/anilist_service.dart';

class SearchScreen extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<int> onSelectMedia;
  final String initialType;

  const SearchScreen({
    Key? key,
    required this.onBack,
    required this.onSelectMedia,
    this.initialType = 'ANIME',
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryCtrl = TextEditingController();
  String _type = 'ANIME';
  List<AniListMedia> _results = [];
  bool _loading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _queryCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _queryCtrl.text.trim();
    if (query.length < 3) {
      if (_results.isNotEmpty) setState(() => _results = []);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query, _type);
    });
  }

  Future<void> _performSearch(String query, String type) async {
    setState(() => _loading = true);
    try {
      final res = await AniListService.searchMedia(query, type);
      if (mounted) setState(() => _results = res);
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setType(String type) {
    setState(() => _type = type);
    if (_queryCtrl.text.trim().length >= 3) {
      _performSearch(_queryCtrl.text.trim(), type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // bg-neutral-950
      body: Column(
        children: [
          // Search Header
          Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF171717), // bg-neutral-900
              border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, offset: Offset(0, 4), blurRadius: 6)
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFFA3A3A3)), // text-neutral-400
                      hoverColor: Colors.white,
                    ),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF262626), // bg-neutral-800
                          borderRadius: BorderRadius.circular(12), // rounded-xl
                        ),
                        child: TextField(
                          controller: _queryCtrl,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Search anime, manga...",
                            hintStyle: TextStyle(
                                color: Color(0xFF737373)), // text-neutral-500
                            prefixIcon:
                                Icon(Icons.search, color: Color(0xFF737373)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Type Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48), // px-12
                  child: Row(
                    children: [
                      Expanded(child: _buildToggleButton('Anime', 'ANIME')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildToggleButton('Manga', 'MANGA')),
                    ],
                  ),
                )
              ],
            ),
          ),

          // Results Area
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Colors.indigoAccent))
                : _queryCtrl.text.trim().length >= 3 &&
                        _results.isEmpty &&
                        !_loading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search,
                                size: 48, color: Colors.white.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text("No results found for \"${_queryCtrl.text}\"",
                                style:
                                    const TextStyle(color: Color(0xFF737373))),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 16, bottom: 80), // pb-20
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              3, // Roughly matches md:grid-cols-4 for mobile
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.55, // Extra height for text
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return GestureDetector(
                            onTap: () => widget.onSelectMedia(item.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 2 / 3,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF262626),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                  item.coverImage.large),
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                      if (item.averageScore != null)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.8),
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star,
                                                    color: Colors.amber,
                                                    size: 10),
                                                const SizedBox(width: 4),
                                                Text(
                                                    "${item.averageScore! / 10}",
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title.display,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Color(0xFFE5E5E5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2),
                                )
                              ],
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, String type) {
    final isActive = _type == type;
    return GestureDetector(
      onTap: () => _setType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6), // py-1.5
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.indigoAccent : const Color(0xFF262626),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFFA3A3A3)),
        ),
      ),
    );
  }
}
