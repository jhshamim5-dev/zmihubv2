import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/anilist_models.dart';

class MediaRow extends StatelessWidget {
  final String title;
  final List<AniListMedia> items;
  final ValueChanged<int>? onSelect;

  const MediaRow({
    Key? key,
    required this.title,
    required this.items,
    this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0), // py-4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Title
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, bottom: 16.0), // px-4 mb-4
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18, // text-lg
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0, // tracking-wide
              ),
            ),
          ),

          // Horizontal scrolling container (flex overflow-x-auto gap-4 px-4)
          SizedBox(
            height: 250, // Enough height for aspect-[2/3] + title
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // px-4
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 16), // gap-4
              itemBuilder: (context, index) {
                final item = items[index];
                final titleText = item.title
                    .display; // Handles english || romaji based on your model

                return GestureDetector(
                  onTap: () => onSelect?.call(item.id),
                  child: SizedBox(
                    width: 140, // shrink-0 w-[140px]
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Image Container
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF262626), // bg-neutral-800
                                  borderRadius:
                                      BorderRadius.circular(12), // rounded-xl
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4))
                                  ], // shadow-md
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        item.coverImage.large),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Score Badge (if available)
                              if (item.averageScore != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2), // px-1.5 py-0.5
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withOpacity(0.6), // bg-black/60
                                      borderRadius: BorderRadius.circular(
                                          6), // rounded-md
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.amber,
                                            size: 10), // fill-yellow-500
                                        const SizedBox(width: 4),
                                        Text(
                                          (item.averageScore! / 10)
                                              .toStringAsFixed(
                                                  1), // format 85 -> 8.5
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                        const SizedBox(height: 8), // gap-2
                        // Title Text
                        Text(
                          titleText,
                          maxLines: 2, // line-clamp-2
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14, // text-sm
                            fontWeight: FontWeight.w500, // font-medium
                            color: Color(0xFFE5E5E5), // text-neutral-200
                            height: 1.2, // leading-tight
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
