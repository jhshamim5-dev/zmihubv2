import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/library_provider.dart';

class LibraryScreen extends StatefulWidget {
  final ValueChanged<int> onSelectMedia;

  const LibraryScreen({Key? key, required this.onSelectMedia})
      : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _tab = 'ANIME';

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final filteredHistory =
        lib.history.where((h) => h.media.type == _tab).toList();
    final filteredFavs = lib.favorites.where((f) => f.type == _tab).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 40, // pt-24 approx
        left: 16, right: 16,
        bottom: 112, // pb-28
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Auth
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("My Library",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900)),
              lib.isLoggedIn
                  ? Row(
                      children: [
                        const Text("● Connected",
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFA3A3A3),
                              backgroundColor: const Color(0xFF171717),
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.1)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8)),
                          onPressed: lib.logout,
                          child: const Text("Disconnect",
                              style: TextStyle(fontSize: 12)),
                        )
                      ],
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                        elevation: 10,
                        shadowColor: Colors.indigoAccent.withOpacity(0.4),
                      ),
                      onPressed: lib.login,
                      child: const Text("Login to AniList",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    )
            ],
          ),
          const SizedBox(height: 32),

          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Row(
              children: [
                Expanded(child: _buildMainTab('ANIME')),
                Expanded(child: _buildMainTab('MANGA')),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Continue Watching / Reading
          Row(
            children: [
              Icon(_tab == 'ANIME' ? Icons.play_circle : Icons.menu_book,
                  color: _tab == 'ANIME'
                      ? Colors.indigoAccent
                      : Colors.pinkAccent),
              const SizedBox(width: 8),
              Text("Continue ${_tab == 'ANIME' ? 'Watching' : 'Reading'}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          if (filteredHistory.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: const Color(0xFF171717).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Text("No history yet for ${_tab.toLowerCase()}.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF737373))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: filteredHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = filteredHistory[index];
                return GestureDetector(
                  onTap: () => widget.onSelectMedia(item.media.id),
                  child: Container(
                    height: 112, // h-28
                    decoration: BoxDecoration(
                        color: const Color(0xFF171717),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.05))),
                    child: Row(
                      children: [
                        Container(
                          width: 80, // w-20
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                12), // FIXED: Removed const from BorderRadius.circular
                            image: DecorationImage(
                                image: CachedNetworkImageProvider(
                                    item.media.coverImage.large),
                                fit: BoxFit.cover),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.media.title.display,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color:
                                          Colors.indigoAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                      "${_tab == 'ANIME' ? 'Ep' : 'Ch'} ${item.progress}",
                                      style: const TextStyle(
                                          color: Colors.indigoAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => lib.removeFromHistory(item.media.id),
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.redAccent.withOpacity(0.1),
                              side: BorderSide(
                                  color: Colors.redAccent.withOpacity(0.2))),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 48),

          // Favorites
          const Row(
            children: [
              Icon(Icons.favorite, color: Colors.redAccent),
              SizedBox(width: 8),
              Text("Favorites",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          if (!lib.isLoggedIn)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: const Color(0xFF171717).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Column(
                children: [
                  const Icon(Icons.favorite,
                      size: 48, color: Color(0xFF404040)),
                  const SizedBox(height: 16),
                  const Text("Login to AniList to view your saved favorites.",
                      style: TextStyle(
                          color: Color(
                              0xFFA3A3A3))), // FIXED: removed const Text if style has const child
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50))),
                    onPressed: lib.login,
                    child: const Text("Login Now",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
          else if (filteredFavs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: const Color(0xFF171717).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Text("No favorites saved for ${_tab.toLowerCase()}.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF737373))),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2 / 3,
              ),
              itemCount: filteredFavs.length,
              itemBuilder: (context, index) {
                final item = filteredFavs[index]; // item is FavoriteEntry
                return GestureDetector(
                  onTap: () => widget
                      .onSelectMedia(item.media.id), // FIXED: added .media
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                  item.media.coverImage.large),
                              fit: BoxFit.cover), // FIXED: added .media
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.black.withOpacity(0.9),
                                Colors.transparent
                              ]),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => lib.toggleFavorite(
                              item.media), // FIXED: added .media
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2))),
                            child: const Icon(Icons.favorite,
                                color: Colors.redAccent, size: 16),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8, left: 8, right: 8,
                        child: Text(item.media.title.display,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.1)), // FIXED: added .media
                      )
                    ],
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildMainTab(String label) {
    final isActive = _tab == label;
    return GestureDetector(
      onTap: () => setState(() => _tab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? (label == 'ANIME' ? Colors.indigoAccent : Colors.pinkAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : const Color(0xFFA3A3A3)),
        ),
      ),
    );
  }
}
