import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/library_provider.dart';
import 'widgets/top_bar.dart';
import 'widgets/floating_nav.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'screens/details_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimeHub Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'Inter', // Or any sans-serif built in
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  TabType _currentTab = TabType.ANIME;

  void _handleSelectMedia(BuildContext context, int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(
          mediaId: id,
          onBack: () => Navigator.pop(context),
          onSelectMedia: (newId) {
            Navigator.pop(context); // Pop current details
            _handleSelectMedia(context, newId); // Push new details
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Main Body
          Positioned.fill(
            child: _buildBody(),
          ),

          // Top Nav Overlays the body just like absolute top-0
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(
              title: _currentTab == TabType.LIBRARY
                  ? 'My Library'
                  : _currentTab == TabType.ANIME
                      ? 'AnimeHub'
                      : 'MangaHub',
              onSearchClick: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                      pageBuilder: (_, __, ___) => SearchScreen(
                            onBack: () => Navigator.pop(context),
                            onSelectMedia: (id) =>
                                _handleSelectMedia(context, id),
                            initialType: _currentTab == TabType.MANGA
                                ? 'MANGA'
                                : 'ANIME',
                          ),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(opacity: animation, child: child);
                      }),
                );
              },
            ),
          ),

          // Bottom Nav Overlay
          FloatingNav(
            currentTab: _currentTab,
            onTabChange: (tab) => setState(() => _currentTab = tab),
          )
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case TabType.ANIME:
        return HomeScreen(
            type: 'ANIME',
            onSelectMedia: (id) => _handleSelectMedia(context, id));
      case TabType.MANGA:
        return HomeScreen(
            type: 'MANGA',
            onSelectMedia: (id) => _handleSelectMedia(context, id));
      case TabType.LIBRARY:
        return LibraryScreen(
            onSelectMedia: (id) => _handleSelectMedia(context, id));
    }
  }
}
