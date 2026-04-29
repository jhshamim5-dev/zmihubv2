import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/anilist_models.dart';
import '../providers/library_provider.dart';
import '../services/anilist_service.dart';
import '../widgets/media_row.dart';
import 'player_screen.dart';

class AiringCountdown extends StatefulWidget {
  final int airingAt;
  final int episode;
  const AiringCountdown(
      {Key? key, required this.airingAt, required this.episode})
      : super(key: key);

  @override
  State<AiringCountdown> createState() => _AiringCountdownState();
}

class _AiringCountdownState extends State<AiringCountdown> {
  late Timer _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _calculateTime());
  }

  void _calculateTime() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    setState(() {
      _timeLeft = widget.airingAt - now > 0 ? widget.airingAt - now : 0;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft <= 0) return const SizedBox.shrink();

    final days = _timeLeft ~/ 86400;
    final hours = (_timeLeft % 86400) ~/ 3600;
    final minutes = (_timeLeft % 3600) ~/ 60;
    final seconds = _timeLeft % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(8),
        // FIXED: removed `inset: true` (not supported in base Flutter BoxShadow without extra packages)
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeNode(days.toString(), 'D', false),
          _buildColon(),
          _buildTimeNode(hours.toString().padLeft(2, '0'), 'H', false),
          _buildColon(),
          _buildTimeNode(minutes.toString().padLeft(2, '0'), 'M', false),
          _buildColon(),
          _buildTimeNode(seconds.toString().padLeft(2, '0'), 'S', true),
        ],
      ),
    );
  }

  Widget _buildTimeNode(String val, String lbl, bool isSec) {
    return Column(
      children: [
        Text(val,
            style: TextStyle(
                color: isSec ? Colors.indigoAccent : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1)),
        Text(lbl,
            style: TextStyle(
                color: isSec
                    ? Colors.indigoAccent.withOpacity(0.5)
                    : const Color(0xFF737373),
                fontSize: 9,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildColon() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(':',
            style: TextStyle(
                color: Colors.indigoAccent.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      );
}

class DetailsScreen extends StatefulWidget {
  final int mediaId;
  final VoidCallback onBack;
  final ValueChanged<int>? onSelectMedia;

  const DetailsScreen(
      {Key? key,
      required this.mediaId,
      required this.onBack,
      this.onSelectMedia})
      : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  AniListMedia? _data;
  bool _loading = true;
  bool _showLoginPrompt = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(DetailsScreen oldWidget) {
    if (oldWidget.mediaId != widget.mediaId) _fetch();
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await AniListService.getMediaDetails(widget.mediaId);
      if (mounted)
        setState(() {
          _data = res;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _stripHtml(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r"<[^>]*>"), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'");
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _data == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
            child: CircularProgressIndicator(color: Colors.indigoAccent)),
      );
    }

    final data = _data!;
    final lib = Provider.of<LibraryProvider>(context);
    final favState = lib.isFavorite(data.id);
    final isAnime = data.type == 'ANIME';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                SizedBox(
                  height: 384, // h-96
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Container(color: const Color(0xFF171717)),
                      CachedNetworkImage(
                        imageUrl:
                            data.bannerImage ?? data.coverImage.extraLarge,
                        height: 384,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.dstIn,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                            const Color(0xFF0A0A0A),
                            const Color(0xFF0A0A0A).withOpacity(0.6),
                            Colors.transparent
                          ]))),
                    ],
                  ),
                ),

                // Main Content
                Transform.translate(
                  offset: const Offset(0, -128), // -mt-32
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Poster & Top Meta Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 144, // w-36
                              decoration: BoxDecoration(
                                color: const Color(0xFF171717),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black87,
                                      blurRadius: 40,
                                      offset: Offset(0, 10))
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                    imageUrl: data.coverImage.large,
                                    fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isAnime &&
                                        data.nextAiringEpisode != null)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                            Colors.indigoAccent
                                                .withOpacity(0.1),
                                            Colors.transparent
                                          ]),
                                          border: Border.all(
                                              color: Colors.indigoAccent
                                                  .withOpacity(0.2)),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                        color: Colors
                                                            .indigoAccent
                                                            .withOpacity(0.2),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                            color: Colors
                                                                .indigoAccent
                                                                .withOpacity(
                                                                    0.3))),
                                                    child: const Icon(
                                                        Icons.schedule,
                                                        color:
                                                            Colors.indigoAccent,
                                                        size: 20)),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text("NEXT EPISODE",
                                                        style: TextStyle(
                                                            color: Colors
                                                                .indigoAccent,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            letterSpacing: 1)),
                                                    Text(
                                                        "Episode ${data.nextAiringEpisode!.episode}",
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            height: 1.1)),
                                                  ],
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            AiringCountdown(
                                                airingAt: data
                                                    .nextAiringEpisode!
                                                    .airingAt,
                                                episode: data.nextAiringEpisode!
                                                    .episode),
                                          ],
                                        ),
                                      ),
                                    Text(data.title.display,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w900,
                                            height: 1.1,
                                            shadows: [
                                              Shadow(
                                                  blurRadius: 4,
                                                  color: Colors.black26)
                                            ])),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (data.averageScore != null)
                                          Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: Colors.greenAccent
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          50)),
                                              child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.star,
                                                        color:
                                                            Colors.greenAccent,
                                                        size: 14),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                        "${data.averageScore}%",
                                                        style: const TextStyle(
                                                            color: Colors
                                                                .greenAccent,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))
                                                  ])),
                                        if (data.studio.isNotEmpty)
                                          _buildPill(data.studio),
                                        _buildPill(
                                            data.status.replaceAll('_', ' ')),
                                        if (data.format.isNotEmpty)
                                          _buildPill(data.format),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (data.genres.isNotEmpty)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: data.genres
                                            .map((g) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF262626),
                                                    border: Border.all(
                                                        color: Colors.white
                                                            .withOpacity(0.05)),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6)),
                                                child: Text(g,
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFFA3A3A3),
                                                        fontSize: 12,
                                                        letterSpacing: 1))))
                                            .toList(),
                                      )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),

                        // Stats
                        const SizedBox(height: 32),
                        GridView(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16),
                          children: [
                            _buildStatBox(
                                Icons.layers,
                                "Episodes",
                                data.episodes?.toString() ?? '?',
                                Colors.indigoAccent),
                            _buildStatBox(
                                Icons.access_time,
                                "Chapters",
                                data.chapters?.toString() ?? '?',
                                Colors.pinkAccent),
                            _buildStatBox(Icons.videocam, "Format", data.format,
                                Colors.blueAccent),
                          ],
                        ),

                        // Trailer
                        if (data.trailer?.site == 'youtube') ...[
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse(
                                'https://www.youtube.com/watch?v=${data.trailer!.id}')),
                            child: AspectRatio(
                              aspectRatio: 21 / 9,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1)),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26, blurRadius: 10)
                                  ],
                                  image: DecorationImage(
                                      image: CachedNetworkImageProvider(
                                          data.trailer!.thumbnail),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.3),
                                          BlendMode.darken)),
                                ),
                                child: const Center(
                                    child: Icon(Icons.play_circle_fill,
                                        color: Colors.white, size: 64)),
                              ),
                            ),
                          )
                        ],

                        // Synopsis
                        const SizedBox(height: 40),
                        const Text("Synopsis",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(_stripHtml(data.description),
                            style: const TextStyle(
                                color: Color(0xFFA3A3A3),
                                fontSize: 14,
                                height: 1.6)),

                        // Characters
                        if (data.characters.isNotEmpty) ...[
                          const SizedBox(height: 40),
                          const Text("Characters",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.characters.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, i) {
                                final char = data.characters[i];
                                return SizedBox(
                                  width: 100,
                                  child: Column(
                                    children: [
                                      Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFF262626),
                                                  width: 2),
                                              image: DecorationImage(
                                                  image:
                                                      CachedNetworkImageProvider(
                                                          char.image),
                                                  fit: BoxFit.cover))),
                                      const SizedBox(height: 8),
                                      Text(char.name,
                                          style: const TextStyle(
                                              color: Color(0xFFE5E5E5),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center),
                                      Text(char.role.toUpperCase(),
                                          style: const TextStyle(
                                              color: Color(0xFF737373),
                                              fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        ],

                        // Recommendations
                        if (data.recommendations.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          MediaRow(
                              title: "Recommendations",
                              items: data.recommendations,
                              onSelect: widget.onSelectMedia),
                        ]
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),

          // Top Nav Buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _glassBtn(Icons.arrow_back, widget.onBack),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _glassBtn(favState ? Icons.favorite : Icons.favorite_border,
                () {
              if (!lib.isLoggedIn) {
                setState(() => _showLoginPrompt = true);
              } else {
                lib.toggleFavorite(data);
              }
            }, iconColor: favState ? Colors.redAccent : Colors.white),
          ),

          // Float Action
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 384),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                              media: data,
                              onBack: () => Navigator.pop(context)))),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: LinearGradient(
                          colors: isAnime
                              ? [Colors.indigo, Colors.indigoAccent]
                              : [Colors.pink, Colors.pinkAccent]),
                      boxShadow: [
                        BoxShadow(
                            color: (isAnime
                                    ? Colors.indigoAccent
                                    : Colors.pinkAccent)
                                .withOpacity(0.4),
                            blurRadius: 20)
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isAnime ? Icons.play_circle_fill : Icons.layers,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(isAnime ? 'WATCH NOW' : 'READ NOW',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Login Modal
          if (_showLoginPrompt)
            GestureDetector(
              onTap: () => setState(() => _showLoginPrompt = false),
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Colors.indigoAccent.withOpacity(0.2),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.favorite,
                                  color: Colors.indigoAccent, size: 32)),
                          const SizedBox(height: 24),
                          const Text("Login Required",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              "Connect your AniList account to sync your favorite ${isAnime ? 'anime' : 'manga'}!",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Color(0xFFA3A3A3), height: 1.5)),
                          const SizedBox(height: 32),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigoAccent,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              onPressed: () {
                                lib.login();
                                setState(() => _showLoginPrompt = false);
                                lib.toggleFavorite(data);
                              },
                              child: const Text("Login with AniList",
                                  style: TextStyle(color: Colors.white))),
                          const SizedBox(height: 12),
                          TextButton(
                              style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF262626),
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              onPressed: () =>
                                  setState(() => _showLoginPrompt = false),
                              child: const Text("Not Now",
                                  style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPill(String val) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(50)),
      child: Text(val,
          style: const TextStyle(
              color: Color(0xFFD4D4D4),
              fontSize: 12,
              fontWeight: FontWeight.bold)));

  Widget _buildStatBox(IconData i, String l, String v, Color c) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF171717).withOpacity(0.5),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: c.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(i, color: c, size: 20)),
        const SizedBox(width: 12),
        Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF737373),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              Text(v,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold))
            ])
      ]));

  Widget _glassBtn(IconData i, VoidCallback o,
          {Color iconColor = Colors.white}) =>
      ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: GestureDetector(
                  onTap: o,
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1))),
                      child: Icon(i, color: iconColor, size: 24)))));
}
