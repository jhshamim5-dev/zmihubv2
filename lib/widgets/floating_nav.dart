import 'dart:ui';
import 'package:flutter/material.dart';

enum TabType { ANIME, LIBRARY, MANGA }

class FloatingNav extends StatelessWidget {
  final TabType currentTab;
  final ValueChanged<TabType> onTabChange;

  const FloatingNav({
    Key? key,
    required this.currentTab,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24, // fixed bottom-6
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384), // max-w-sm
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(50), // rounded-full (for the pill)
            child: BackdropFilter(
              filter:
                  ImageFilter.blur(sigmaX: 24, sigmaY: 24), // backdrop-blur-xl
              child: Container(
                padding: const EdgeInsets.all(8), // px-2 py-2
                decoration: BoxDecoration(
                  color: const Color(0xFF171717)
                      .withOpacity(0.8), // bg-neutral-900/80
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 20,
                        offset: Offset(0, 10))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTab(context, TabType.ANIME, 'ANIME', Icons.live_tv),
                    _buildTab(context, TabType.LIBRARY, 'LIBRARY',
                        Icons.video_library),
                    _buildTab(context, TabType.MANGA, 'MANGA', Icons.menu_book),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(
      BuildContext context, TabType tab, String label, IconData icon) {
    final isActive = currentTab == tab;

    return GestureDetector(
      onTap: () => onTabChange(tab),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12), // px-4 py-3
        decoration: BoxDecoration(
          color: isActive
              ? Colors.indigoAccent.withOpacity(0.2)
              : Colors.transparent, // active pill bg
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Colors.white
                  : const Color(0xFFA3A3A3), // text-white : text-neutral-400
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600, // font-medium
                letterSpacing: 1.0, // tracking-wide
                color: isActive ? Colors.white : const Color(0xFFA3A3A3),
              ),
            )
          ],
        ),
      ),
    );
  }
}
