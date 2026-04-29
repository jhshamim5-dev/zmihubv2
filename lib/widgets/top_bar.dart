import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onSearchClick;

  const TopBar({
    super.key,
    required this.title,
    required this.onSearchClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // absolute top-0 left-0 right-0 z-50 flex items-center justify-between px-4 py-4
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16, // handle safe area
        left: 16,
        right: 16,
        bottom: 16,
      ),
      // bg-gradient-to-b from-black/80 to-transparent
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search Button (p-2 bg-white/10 backdrop-blur-md rounded-full text-white)
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSearchClick,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child:
                        const Icon(Icons.search, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),

          // Title (text-xl font-bold tracking-wider uppercase text-white drop-shadow-md)
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                    color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
          ),

          // Profile Image (w-10 h-10 rounded-full bg-indigo-500 border-2 border-white/20 shadow-lg)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigoAccent,
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: "https://picsum.photos/seed/animeavatar/100/100",
                fit: BoxFit.cover,
              ),
            ),
          )
        ],
      ),
    );
  }
}
