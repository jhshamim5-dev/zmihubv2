import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/anilist_models.dart';
import 'dart:math' as math;

class HeroSlider extends StatefulWidget {
  final List<AniListMedia> items;
  final ValueChanged<AniListMedia>? onSelect;

  const HeroSlider({super.key, required this.items, this.onSelect});

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    if (widget.items.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex =
              (_currentIndex + 1) % math.min(widget.items.length, 5);
        });
      }
    });
  }

  @override
  void didUpdateWidget(HeroSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _timer?.cancel();
      setState(() => _currentIndex = 0);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString
        .replaceAll(exp, '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'");
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        color: const Color(
            0xFF171717), // bg-neutral-900 (animate-pulse not strictly req here but acts as skeleton)
      );
    }

    final item = widget.items[_currentIndex];
    final imageUrl = item.bannerImage ?? item.coverImage.extraLarge;
    final title = item.title.display;
    final displayItems = widget.items.take(5).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6, // h-[60vh]
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with crossfade
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: Container(
              key: ValueKey<int>(_currentIndex),
              decoration: BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3),
                      BlendMode.darken), // matches opacity-70
                ),
              ),
            ),
          ),

          // Gradient Overflow
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF0A0A0A), // neutral-950
                  const Color(0xFF0A0A0A).withValues(alpha: 0.4), // neutral-950/40
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Content Box
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24.0, right: 24.0, bottom: 48.0), // p-6 pb-12
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  key: ValueKey<int>(_currentIndex),
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Genres
                      if (item.genres.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: item.genres
                              .take(3)
                              .map((g) => Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 12), // mb-3
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4), // px-2 py-1
                                    decoration: BoxDecoration(
                                      color: Colors.indigoAccent
                                          .withValues(alpha: 0.8), // bg-indigo-500/80
                                      borderRadius: BorderRadius.circular(
                                          4), // rounded-sm
                                    ),
                                    child: Text(
                                      g.toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1), // tracking-wider
                                    ),
                                  ))
                              .toList(),
                        ),

                      // Title
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 30, // text-3xl
                          fontWeight: FontWeight.w900, // font-black
                          color: Colors.white,
                          height: 1.1, // leading-tight
                          shadows: [
                            Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(0, 4))
                          ], // drop-shadow-lg
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      if (item.description.isNotEmpty)
                        Text(
                          _stripHtml(item.description),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14, // text-sm
                            color: Color(0xFFD4D4D4), // text-neutral-300
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 2)
                            ],
                          ),
                        ),
                      const SizedBox(height: 16), // mb-4

                      // Buttons
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                              elevation: 10,
                              shadowColor: Colors.white24,
                            ),
                            onPressed: () => widget.onSelect?.call(item),
                            child: const Text("Play Now",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2), // bg-white/20
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            onPressed: () => widget.onSelect?.call(item),
                            child: const Text("Details",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Dots Indicator
          Positioned(
            left: 24, bottom: 16, // left-6 bottom-4
            child: Row(
              children: List.generate(displayItems.length, (idx) {
                final isActive = idx == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 8), // gap-2
                  height: 6, // h-1.5
                  width: isActive ? 24 : 8, // w-6 : w-2
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.indigoAccent
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(50),
                  ),
                );
              }),
            ),
          )
        ],
      ),
    );
  }
}
