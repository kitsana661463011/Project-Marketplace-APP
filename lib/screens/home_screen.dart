import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/shop_service.dart';
import '../services/review_service.dart';
import '../services/announcement_service.dart';
import '../models/shop.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_dialog.dart';
import 'market_map_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const _HomeTab(),
      const MarketMapScreen(isEmbedded: true),
      const _FollowedTab(),
      const _ProfileTab(),
    ];
  }

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF1E88E5).withValues(alpha: 0.12),
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(
                  Icons.home_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: const Icon(
                  Icons.home,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'หน้าหลัก',
              ),
              NavigationDestination(
                icon: const Icon(
                  Icons.explore_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: const Icon(
                  Icons.explore,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'แผนที่ตลาด',
              ),
              NavigationDestination(
                icon: const Icon(
                  Icons.favorite_outline,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: const Icon(
                  Icons.favorite,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'ติดตาม',
              ),
              NavigationDestination(
                icon: const Icon(
                  Icons.person_outline,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: const Icon(
                  Icons.person,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FuzzySearch {
  static String normalize(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[\u0E48-\u0E4C\u0E4D\u0E3A]'), '')
        .trim();
  }

  static int levenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  static double matchScore(String rawQuery, String rawTarget) {
    final q = normalize(rawQuery);
    final target = normalize(rawTarget);

    if (q.isEmpty || target.isEmpty) return 0.0;

    if (target.contains(q)) {
      return target.startsWith(q) ? 1.0 : 0.9;
    }

    double bestScore = 0.0;
    final qLen = q.length;

    final words = target.split(RegExp(r'[\s,\.\-\/\(\)]+'));
    for (final word in words) {
      if (word.isEmpty) continue;
      if (word.contains(q)) return 0.85;

      final dist = levenshtein(q, word);
      final maxLen = qLen > word.length ? qLen : word.length;
      final sim = 1.0 - (dist / maxLen);
      if (sim > bestScore) bestScore = sim;
    }

    final targetLen = target.length;
    for (int len = qLen - 1; len <= qLen + 2; len++) {
      if (len <= 0) continue;
      for (int i = 0; i <= targetLen - len; i++) {
        final sub = target.substring(i, i + len);
        final dist = levenshtein(q, sub);
        final sim = 1.0 - (dist / qLen);
        if (sim > bestScore) bestScore = sim;
      }
    }

    return bestScore;
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Shop> _shops = [];
  List<Shop> _followedShops = [];
  int _unreadNotificationCount = 0;
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _searchOverlayEntry;
  final LayerLink _searchLayerLink = LayerLink();
  String _searchQuery = '';
  String _selectedCategory = 'ทั้งหมด';
  List<String> _categories = ['ทั้งหมด'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _hideSearchOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchOverlay() {
    if (_searchQuery.trim().isEmpty) {
      _hideSearchOverlay();
      return;
    }
    if (_searchOverlayEntry != null) {
      _searchOverlayEntry!.markNeedsBuild();
    } else {
      _showSearchOverlay();
    }
  }

  void _showSearchOverlay() {
    _hideSearchOverlay();
    if (!mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final overlayWidth = size.width > 40
        ? size.width - 40
        : MediaQuery.of(context).size.width - 40;

    _searchOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: overlayWidth,
        child: CompositedTransformFollower(
          link: _searchLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            color: Colors.transparent,
            child: _buildSearchDropdown(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_searchOverlayEntry!);
  }

  void _hideSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      final shops = await ShopService.getShops();
      final followedShops = currentUser?.userId != null
          ? await ShopService.getFollowedShops(currentUser!.userId!)
          : <Shop>[];

      if (!mounted) return;

      final userInterests = currentUser?.interests ?? [];

      int calculateInterestScore(Shop shop) {
        if (userInterests.isEmpty) return 0;
        int score = 0;
        for (int i = 0; i < userInterests.length; i++) {
          final interest = userInterests[i];
          final cleanInterest = interest.trim().toLowerCase();
          if (cleanInterest.isEmpty) continue;

          // Rank 1 (Index 0) gets highest weight multiplier (5), decreasing down to Rank 5 (1)
          final int rankMultiplier = (5 - i).clamp(1, 5);

          // 1. Direct match with Shop Tags (Highest Priority: 5 pts * rankMultiplier -> Rank 1 = 25 pts, Rank 5 = 5 pts)
          if (shop.tags.any((tag) {
            final t = tag.trim().toLowerCase();
            return t == cleanInterest ||
                t.contains(cleanInterest) ||
                cleanInterest.contains(t);
          })) {
            score += 5 * rankMultiplier;
          }
          // 2. Match with Category Name (2 pts * rankMultiplier -> Rank 1 = 10 pts, Rank 5 = 2 pts)
          else if (shop.categoryName.toLowerCase().contains(cleanInterest)) {
            score += 2 * rankMultiplier;
          }
          // 3. Match with Description (1 pt * rankMultiplier -> Rank 1 = 5 pts, Rank 5 = 1 pt)
          else if ((shop.description ?? '')
              .toLowerCase()
              .contains(cleanInterest)) {
            score += 1 * rankMultiplier;
          }
        }
        return score;
      }

      shops.sort((a, b) {
        final aScore = calculateInterestScore(a);
        final bScore = calculateInterestScore(b);
        if (aScore != bScore) {
          return bScore.compareTo(aScore); // Higher match score first
        }
        // If equal score, sort by rating / follower popularity
        final aRating = a.avgRating ?? 0.0;
        final bRating = b.avgRating ?? 0.0;
        if (aRating != bRating) return bRating.compareTo(aRating);
        return b.followerCount.compareTo(a.followerCount);
      });

      final Set<String> catSet = {'ทั้งหมด'};
      try {
        final catRes = await ApiService.get('/v1/categories');
        if (catRes['status'] == true && catRes['data'] is List) {
          for (final c in catRes['data']) {
            if (c is Map && c['category_name'] != null) {
              final name = c['category_name'].toString().trim();
              if (name.isNotEmpty) catSet.add(name);
            }
          }
        }
      } catch (_) {}

      for (final s in shops) {
        if (s.categoryName.isNotEmpty && s.categoryName != 'ไม่ระบุหมวดหมู่') {
          catSet.add(s.categoryName.trim());
        }
      }

      int unreadCount = 0;
      try {
        unreadCount = await AnnouncementService.getUnreadCount();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _shops = shops;
          _followedShops = followedShops;
          _categories = catSet.toList();
          _unreadNotificationCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Shop> get _filteredShops {
    return _shops;
  }

  List<Shop> get _searchResultShops {
    final q = _searchQuery.trim();

    List<Shop> baseList = _shops;
    if (_selectedCategory != 'ทั้งหมด') {
      baseList = baseList
          .where((shop) => shop.categoryName.trim() == _selectedCategory.trim())
          .toList();
    }

    if (q.isEmpty) return baseList;

    final List<MapEntry<Shop, double>> scoredShops = [];

    for (final shop in baseList) {
      final nameScore = _FuzzySearch.matchScore(q, shop.shopName);
      final categoryScore = _FuzzySearch.matchScore(q, shop.categoryName);
      final descScore = shop.description != null
          ? _FuzzySearch.matchScore(q, shop.description!) * 0.7
          : 0.0;
      final stallScore = shop.stallNumber != null
          ? _FuzzySearch.matchScore(q, 'แผง ${shop.stallNumber}')
          : 0.0;

      final maxScore = [nameScore, categoryScore, descScore, stallScore]
          .reduce((a, b) => a > b ? a : b);

      if (maxScore >= 0.38) {
        scoredShops.add(MapEntry(shop, maxScore));
      }
    }

    scoredShops.sort((a, b) => b.value.compareTo(a.value));
    return scoredShops.map((e) => e.key).toList();
  }

  Future<void> _navigateToShopDetail(Shop shop) async {
    final result = await Navigator.pushNamed(
      context,
      '/shop_detail',
      arguments: {'shop': shop, 'tabIndex': 0},
    );
    if (mounted) {
      _loadShops();
    }
    if (result != null && result is int && mounted) {
      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeState != null) {
        homeState.setIndex(result);
      }
    }
  }

  void _openFollowedTab() {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeState != null && mounted) {
      homeState.setIndex(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadShops,
        color: const Color(0xFF1E88E5),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // App icon logo
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Image.asset(
                              'assets/home_logo.png',
                              color: Colors.white,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'MarketPlace',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  // Notification bell
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, '/announcements');
                      _loadShops();
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Color(0xFF475569),
                            size: 24,
                          ),
                        ),
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _unreadNotificationCount > 99
                                      ? '99+'
                                      : '$_unreadNotificationCount',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar with Floating Autocomplete Dropdown Overlay
              CompositedTransformTarget(
                link: _searchLayerLink,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _updateSearchOverlay();
                    },
                    style: GoogleFonts.outfit(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาร้าน หรือ ร้านค้า...',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                _hideSearchOverlay();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Category Filter Chips
              _buildCategoryFilterChips(),
              const SizedBox(height: 24),

              // Followed Shops Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ร้านค้าที่คุณติดตาม',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openFollowedTab,
                    child: Text(
                      'ดูทั้งหมด',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal list of followed shops
              _isLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    )
                  : _followedShops.isEmpty
                  ? SizedBox(
                      height: 64,
                      child: Center(
                        child: Text(
                          'คุณยังไม่ได้ติดตามร้านค้าใดๆ',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _followedShops.length,
                        itemBuilder: (context, index) {
                          final shop = _followedShops[index];
                          return GestureDetector(
                            onTap: () => _navigateToShopDetail(shop),
                            child: Container(
                              margin: const EdgeInsets.only(right: 18),
                              child: Column(
                                children: [
                                  ClipOval(
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      color: const Color(0xFFE2E8F0),
                                      child:
                                          shop.shopImage != null &&
                                              shop.shopImage!.isNotEmpty
                                          ? Image.network(
                                              ApiService.getImagePath(
                                                shop.shopImage,
                                              ),
                                              width: 68,
                                              height: 68,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.storefront,
                                                    color: Color(0xFF64748B),
                                                    size: 30,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.storefront,
                                              color: Color(0xFF64748B),
                                              size: 30,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    shop.shopName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 24),

              // Recommended Shops Section
              Text(
                'ร้านแนะนำสำหรับคุณ',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Vertical list/card of recommended shops
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    )
                  : _filteredShops.isEmpty
                  ? Center(
                      child: Text(
                        _selectedCategory == 'ทั้งหมด'
                            ? 'ยังไม่มีร้านแนะนำในขณะนี้'
                            : 'ไม่พบร้านค้าในหมวดหมู่ "$_selectedCategory"',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  : Column(
                      children: _filteredShops
                          .map((shop) => _buildRecommendedCard(shop))
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedCard(Shop shop) {
    final hasRating = shop.avgRating != null && shop.avgRating! > 0;
    final ratingText = hasRating ? shop.avgRating!.toStringAsFixed(1) : 'ใหม่';
    final reviewCountText = shop.reviewCount > 0 ? '(${shop.reviewCount})' : '';
    final stallLocation = shop.stallNumber != null && shop.stallNumber!.isNotEmpty
        ? 'แผง ${shop.stallNumber}'
        : 'โซนตลาด';
    final bool isFollowed = _followedShops.any((f) => f.shopId == shop.shopId);

    final authService = Provider.of<AuthService>(context, listen: false);
    final userInterests = authService.currentUser?.interests ?? [];
    final matchingTags = shop.tags.where((tag) {
      final t = tag.trim().toLowerCase();
      return userInterests.any((i) => i.trim().toLowerCase() == t);
    }).toList();

    final sortedShopTags = List<String>.from(shop.tags);
    sortedShopTags.sort((a, b) {
      final aMatch = userInterests.indexWhere(
        (i) => i.trim().toLowerCase() == a.trim().toLowerCase(),
      );
      final bMatch = userInterests.indexWhere(
        (i) => i.trim().toLowerCase() == b.trim().toLowerCase(),
      );
      if (aMatch != -1 && bMatch != -1) return aMatch.compareTo(bMatch);
      if (aMatch != -1) return -1;
      if (bMatch != -1) return 1;
      return 0;
    });

    return GestureDetector(
      onTap: () => _navigateToShopDetail(shop),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Stack with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.7,
                    child: shop.shopImage != null && shop.shopImage!.isNotEmpty
                        ? (shop.shopImage!.startsWith('http')
                            ? Image.network(shop.shopImage!, fit: BoxFit.cover)
                            : Image.network(
                                ApiService.getImagePath(shop.shopImage),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildCoverPlaceholder(),
                              ))
                        : _buildCoverPlaceholder(),
                  ),
                ),
                // Gradient Overlay at the bottom of image for contrast
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Top Bar Badges: Category (Left) + Rating & Followers (Right)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category Badge Pill (Left)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(shop.categoryName),
                                color: const Color(0xFF60A5FA),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  shop.categoryName,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rating & Follower Badges (Right)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Rating Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 15,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  ratingText,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                if (reviewCountText.isNotEmpty) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    reviewCountText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Follower Count Badge (Red when followed by user, Blue when not)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              color: isFollowed
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF1E88E5),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isFollowed
                                          ? const Color(0xFFE11D48)
                                          : const Color(0xFF1E88E5))
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${shop.followerCount}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bottom Left: Floating Stall Badge
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF1E88E5),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stallLocation,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (shop.zoneName != null && shop.zoneName!.isNotEmpty) ...[
                          Text(
                            ' (${shop.zoneName})',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Shop Name (Full width)
                  Text(
                    shop.shopName,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Row 2: Description (High contrast dark slate color)
                  Text(
                    shop.description ?? 'ร้านค้าคุณภาพ คัดสรรมาเพื่อคุณ',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: const Color(0xFF334155),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (sortedShopTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: sortedShopTags.map((tag) {
                        final isMatched = matchingTags.contains(tag);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isMatched
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isMatched
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMatched) ...[
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 11,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                '#$tag',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: isMatched
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isMatched
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Row 3: Action Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'พร้อมให้บริการ',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'เข้าชมร้านค้า',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Color(0xFF1E88E5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchDropdown() {
    final results = _searchResultShops;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 340),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ผลการค้นหาร้านค้า',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${results.length} รายการ',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 36,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ไม่พบร้านค้าที่ตรงกับ "$_searchQuery"',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: results.length > 6 ? 6 : results.length,
                  separatorBuilder: (ctx, i) => const Divider(
                    height: 1,
                    color: Color(0xFFF8FAFC),
                    indent: 68,
                  ),
                  itemBuilder: (context, index) {
                    final shop = results[index];
                    final hasRating =
                        shop.avgRating != null && shop.avgRating! > 0;
                    final ratingText =
                        hasRating ? shop.avgRating!.toStringAsFixed(1) : 'ใหม่';
                    final stallInfo =
                        shop.stallNumber != null && shop.stallNumber!.isNotEmpty
                            ? 'แผง ${shop.stallNumber}'
                            : 'โซนตลาด';

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _navigateToShopDetail(shop);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: const Color(0xFFF1F5F9),
                                child: shop.shopImage != null &&
                                        shop.shopImage!.isNotEmpty
                                    ? (shop.shopImage!.startsWith('http')
                                        ? Image.network(
                                            shop.shopImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            ApiService.getImagePath(
                                              shop.shopImage,
                                            ),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (ctx, err, stack) => const Icon(
                                                  Icons.storefront,
                                                  color: Color(0xFF64748B),
                                                  size: 24,
                                                ),
                                          ))
                                    : const Icon(
                                        Icons.storefront,
                                        color: Color(0xFF64748B),
                                        size: 24,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.shopName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${shop.categoryName} • $stallInfo',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFCD34D),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    ratingText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Color(0xFFCBD5E1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'เลือกหมวดหมู่ร้านค้า',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      final icon = _getCategoryIcon(cat);
                      final count = cat == 'ทั้งหมด'
                          ? _shops.length
                          : _shops
                              .where((s) => s.categoryName.trim() == cat.trim())
                              .length;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1E88E5)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1E88E5)
                                  : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1E88E5,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilterChips() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Main Category Selector Button (Opens Bottom Sheet)
          GestureDetector(
            onTap: _showCategoryBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _selectedCategory != 'ทั้งหมด'
                    ? const Color(0xFF1E88E5)
                    : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedCategory == 'ทั้งหมด'
                        ? 'หมวดหมู่ร้านค้า (${_categories.length - 1})'
                        : 'หมวดหมู่: $_selectedCategory',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Reset Filter Chip (If a specific category is selected)
          if (_selectedCategory != 'ทั้งหมด')
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = 'ทั้งหมด';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFCA5A5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ล้างตัวกรอง',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    if (cat == 'ทั้งหมด') return Icons.grid_view_rounded;
    if (cat.contains('อาหาร')) return Icons.restaurant_rounded;
    if (cat.contains('เครื่องดื่ม') ||
        cat.contains('กาแฟ') ||
        cat.contains('ชา')) {
      return Icons.local_cafe_rounded;
    }
    if (cat.contains('ขนม') || cat.contains('เบเกอรี่')) {
      return Icons.bakery_dining_rounded;
    }
    if (cat.contains('สตรีทฟู้ด') || cat.contains('ทานเล่น')) {
      return Icons.fastfood_rounded;
    }
    if (cat.contains('ของใช้') || cat.contains('เสื้อผ้า')) {
      return Icons.shopping_bag_rounded;
    }
    if (cat.contains('ผลไม้') || cat.contains('ผัก')) {
      return Icons.eco_rounded;
    }
    return Icons.storefront_rounded;
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.storefront, size: 60, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isEditing = false;
  String? _selectedProfileImage;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  final ImagePicker _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _unreadNotificationCount = 0;

  List<String> _dbInterests = [];
  bool _isLoadingInterests = true;
  final List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _fetchInterestsFromDb();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final unread = await AnnouncementService.getUnreadCount();
      if (mounted) setState(() => _unreadNotificationCount = unread);
    } catch (_) {}
  }

  Future<void> _fetchInterestsFromDb() async {
    try {
      final response = await ApiService.get('/v1/user-interests');
      if (response['status'] == true && response['data'] is List) {
        final List<dynamic> list = response['data'] as List<dynamic>;
        if (mounted) {
          setState(() {
            final List<String> items = list
                .where((e) => e != null)
                .map((e) {
                  if (e is Map && e.containsKey('interest_name')) {
                    return e['interest_name']?.toString() ?? '';
                  }
                  if (e is Map && e.containsKey('name')) {
                    return e['name']?.toString() ?? '';
                  }
                  return e.toString();
                })
                .where((e) => e.isNotEmpty)
                .toList();
            _sortInterestsWithOthersAtEnd(items);
            _isLoadingInterests = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load interests from DB: $e');
    }

    if (mounted) {
      setState(() {
        if (_dbInterests.isEmpty) {
          _sortInterestsWithOthersAtEnd([
            'อาหาร',
            'เครื่องดื่ม',
            'ขนม',
            'สตรีทฟู้ด',
            'อื่นๆ',
          ]);
        }
        _isLoadingInterests = false;
      });
    }
  }

  void _sortInterestsWithOthersAtEnd(List<String> list) {
    final others = list
        .where((e) => e == 'อื่นๆ' || e.contains('อื่นๆ'))
        .toList();
    final normal = list
        .where((e) => e != 'อื่นๆ' && !e.contains('อื่นๆ'))
        .toList();
    _dbInterests = [...normal, ...others];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initForm(UserModel? user) {
    _nameController.text = user?.username ?? 'สมชาย ใจดี';
    _phoneController.text = user?.phone ?? '081-999-99999';
    _selectedProfileImage = user?.profileImage;
    _pickedImageBytes = null;
    _pickedImageName = null;

    if (user?.interests != null) {
      final interestList = user!.interests;
      _selectedInterests.clear();
      _selectedInterests.addAll(interestList.where((e) => e.isNotEmpty));
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    // 1. Try FilePicker first (100% Web & Desktop compatible without MissingPluginException)
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _pickedImageBytes = file.bytes;
            _pickedImageName = file.name;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('FilePicker fallback: $e');
    }

    // 2. Fallback to ImagePicker
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถเลือกรูปภาพได้: $e',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showProfileImageOptions(UserModel? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'เปลี่ยน / อัปโหลดรูปโปรไฟล์',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  title: Text(
                    'เลือกไฟล์รูปภาพจากอุปกรณ์',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'อัปโหลดรูปภาพ JPG, PNG จากคลังภาพของคุณ',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfileImage(ImageSource.gallery);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF475569),
                    ),
                  ),
                  title: Text(
                    'ถ่ายภาพด้วยกล้อง',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfileImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultGreyAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFE4E6EB),
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.65,
          color: const Color(0xFF8A8D91),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // Use backend user details or fallback to mockup info
    final String displayName = user != null && user.username.isNotEmpty
        ? user.username
        : 'สมชาย ใจดี';
    final String displayRole = user != null && user.role == 'seller'
        ? 'เป็นสมาชิก และผู้ค้า'
        : 'เป็นสมาชิก';
    final String displayEmail = user?.email ?? 'Test@gmail.com';
    final String joinDate = 'เข้าร่วมเมื่อ มกราคม 2023';

    final String activeProfileImg =
        _selectedProfileImage ?? user?.profileImage ?? '';
    final String? avatarUrl = activeProfileImg.isNotEmpty
        ? (activeProfileImg.startsWith('http')
              ? activeProfileImg
              : ApiService.getImagePath(activeProfileImg))
        : null;

    if (_isEditing) {
      if (_nameController.text.isEmpty && _phoneController.text.isEmpty) {
        _initForm(user);
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top AppBar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.clear();
                          _phoneController.clear();
                        });
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF0F172A),
                          size: 18,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.pushNamed(context, '/announcements');
                        _loadNotificationCount();
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Color(0xFF475569),
                              size: 24,
                            ),
                          ),
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _unreadNotificationCount > 99
                                        ? '99+'
                                        : '$_unreadNotificationCount',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Avatar
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: ClipOval(
                            child: _pickedImageBytes != null
                                ? Image.memory(
                                    _pickedImageBytes!,
                                    width: 128,
                                    height: 128,
                                    fit: BoxFit.cover,
                                  )
                                : (avatarUrl != null
                                      ? Image.network(
                                          avatarUrl,
                                          width: 128,
                                          height: 128,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildDefaultGreyAvatar(128),
                                        )
                                      : _buildDefaultGreyAvatar(128)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'คุณ$displayName',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _showProfileImageOptions(user),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_a_photo_outlined,
                              size: 16,
                              color: Color(0xFF1E88E5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'อัปโหลดรูปโปรไฟล์',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E88E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        joinDate,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                Text(
                  'ชื่อ - นามสกุล',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.outfit(color: Colors.black),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'อีเมล (ไม่สามารถเปลี่ยนได้)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    enabled: false,
                    controller: TextEditingController(text: displayEmail),
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'เบอร์โทร',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    style: GoogleFonts.outfit(color: Colors.black),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'สิ่งที่สนใจ',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedInterests.length == 5
                            ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                            : const Color(0xFF1E88E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'เลือกแล้ว ${_selectedInterests.length}/5',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: _selectedInterests.length == 5
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF1E88E5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'แตะเพื่อเลือกตามลำดับความสนใจ (1 = สนใจมากที่สุด)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _isLoadingInterests
                    ? const SizedBox(
                        height: 30,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: _dbInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(
                            interest,
                          );
                          final int orderIndex = isSelected
                              ? _selectedInterests.indexOf(interest) + 1
                              : 0;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedInterests.remove(interest);
                                } else {
                                  if (_selectedInterests.length >= 5) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'เลือกความสนใจได้สูงสุด 5 อันดับ',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: const Color(
                                          0xFFDC2626,
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  _selectedInterests.add(interest);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFCBD5E1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF2563EB,
                                          ).withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Container(
                                      width: 18,
                                      height: 18,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$orderIndex',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Text(
                                    interest,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF1E40AF)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty) {
                        AppDialog.showError(
                          context,
                          title: 'ข้อผิดพลาด',
                          message: 'กรุณากรอกชื่อ-นามสกุล',
                        );
                        return;
                      }

                      AppDialog.showConfirm(
                        context,
                        title: 'ยืนยันการบันทึก',
                        message:
                            'คุณต้องการบันทึกการเปลี่ยนแปลงข้อมูลโปรไฟล์ใช่หรือไม่?',
                        onConfirm: () async {
                          if (user?.userId == null) return;

                          final Map<String, String> fields = {
                            'username': _nameController.text.trim(),
                            'phone': _phoneController.text.trim(),
                            'interests': _selectedInterests.join(','),
                          };

                          Map<String, dynamic> response;

                          if (_pickedImageBytes != null) {
                            response = await ApiService.postMultipart(
                              '/v1/users/${user!.userId}?_method=PUT',
                              fields,
                              fileKey: 'profile_image_file',
                              fileBytes: _pickedImageBytes,
                              fileName: _pickedImageName ?? 'profile.png',
                            );
                          } else {
                            final Map<String, dynamic> payload =
                                Map<String, dynamic>.from(fields);
                            if (_selectedProfileImage != null &&
                                _selectedProfileImage!.isNotEmpty) {
                              payload['profile_image'] = _selectedProfileImage;
                            }
                            response = await authService.updateProfile(payload);
                          }

                          if (response['status'] == true) {
                            if (response['data'] != null) {
                              await authService.updateUserData(
                                response['data'],
                              );
                            }
                            setState(() {
                              _isEditing = false;
                              _pickedImageBytes = null;
                              _pickedImageName = null;
                            });
                            if (context.mounted) {
                              AppDialog.showSuccess(
                                context,
                                title: 'สำเร็จ',
                                message:
                                    'บันทึกการเปลี่ยนแปลงโปรไฟล์เรียบร้อยแล้ว',
                              );
                            }
                          } else {
                            if (context.mounted) {
                              AppDialog.showError(
                                context,
                                title: 'เกิดข้อผิดพลาด',
                                message:
                                    response['message'] ??
                                    'ไม่สามารถบันทึกข้อมูลได้',
                              );
                            }
                          }
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'บันทึกการเปลี่ยนแปลง',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.pushNamed(context, '/announcements');
                    _loadNotificationCount();
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Color(0xFF475569),
                          size: 24,
                        ),
                      ),
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _unreadNotificationCount > 99
                                    ? '99+'
                                    : '$_unreadNotificationCount',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? Image.network(
                            avatarUrl,
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultGreyAvatar(128),
                          )
                        : _buildDefaultGreyAvatar(128),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                displayName,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayRole,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                joinDate,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              _buildMenuItem(
                icon: Icons.manage_accounts_outlined,
                title: 'แก้ไขโปรไฟล์',
                onTap: () {
                  _initForm(user);
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (user != null && user.role == 'seller') ...[
                _buildMenuItem(
                  icon: Icons.map_outlined,
                  title: 'จองแผง',
                  onTap: () {
                    final homeState = context
                        .findAncestorStateOfType<_HomeScreenState>();
                    if (homeState != null) {
                      homeState.setIndex(1);
                    } else {
                      Navigator.pushNamed(context, '/market_map');
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'ประวัติการจอง',
                  onTap: () {
                    Navigator.pushNamed(context, '/booking_history');
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.storefront_outlined,
                  title: 'จัดการหน้าร้านค้า',
                  onTap: () async {
                    final tabIndex = await Navigator.pushNamed(
                      context,
                      '/my_shops',
                    );
                    if (!context.mounted) return;
                    if (tabIndex != null && tabIndex is int) {
                      final homeState = context
                          .findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState.setIndex(tabIndex);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.report_problem_outlined,
                  title: 'แจ้งปัญหา',
                  onTap: () async {
                    final tabIndex = await Navigator.pushNamed(
                      context,
                      '/problem_history',
                    );
                    if (!context.mounted) return;
                    if (tabIndex != null && tabIndex is int) {
                      final homeState = context
                          .findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState.setIndex(tabIndex);
                      }
                    }
                  },
                ),
              ] else ...[
                _buildMenuItem(
                  icon: Icons.storefront_outlined,
                  title: 'สมัครเป็นผู้ค้า',
                  onTap: () {
                    Navigator.pushNamed(context, '/vendor_register');
                  },
                ),
              ],
              const SizedBox(height: 48),

              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'ยืนยันการออกจากระบบ',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        content: Text(
                          'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบบัญชีผู้ใช้งานนี้?',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        actionsAlignment: MainAxisAlignment.spaceEvenly,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'ยกเลิก',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogContext); // Close dialog
                              await authService.logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              }
                            },
                            child: Text(
                              'ออกจากระบบ',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'ออกจากระบบ',
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF1E88E5), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCBD5E1),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowedTab extends StatefulWidget {
  const _FollowedTab();

  @override
  State<_FollowedTab> createState() => _FollowedTabState();
}

class _FollowedTabState extends State<_FollowedTab> {
  List<Shop> _shops = [];
  Map<int, double> _shopRatings = {};
  bool _isLoading = true;
  String _searchQuery = '';
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadShops();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final unread = await AnnouncementService.getUnreadCount();
      if (mounted) setState(() => _unreadNotificationCount = unread);
    } catch (_) {}
  }

  Future<void> _loadShops() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.loadUser();
    final user = auth.currentUser;

    setState(() => _isLoading = true);
    try {
      List<Shop> data = [];
      if (user != null && user.userId != null) {
        data = await ShopService.getFollowedShops(user.userId!);
      }

      final ratings = <int, double>{};
      for (final shop in data) {
        if (shop.shopId == null) continue;

        final reviews = await ReviewService.getReviewsByShop(shop.shopId!);
        if (reviews.isNotEmpty) {
          final totalRating = reviews.fold<double>(
            0,
            (sum, review) =>
                sum + ((review['rating'] as num?)?.toDouble() ?? 0),
          );
          ratings[shop.shopId!] = totalRating / reviews.length;
        } else {
          ratings[shop.shopId!] = 0.0;
        }
      }

      if (mounted) {
        setState(() {
          _shops = data;
          _shopRatings = ratings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unfollowShop(Shop shop) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || user.userId == null || shop.shopId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ยกเลิกการติดตาม',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการยกเลิกการติดตามร้าน "${shop.shopName}" ใช่หรือไม่?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('ยืนยัน', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ShopService.toggleFollowShop(
        userId: user.userId!,
        shopId: shop.shopId!,
      );
      if (mounted && res['status'] == true) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'เลิกติดตามเรียบร้อยแล้ว'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadShops();
      }
    }
  }

  Future<void> _navigateToShopDetail(Shop shop) async {
    await Navigator.pushNamed(
      context,
      '/shop_detail',
      arguments: {'shop': shop, 'tabIndex': 2},
    );
    if (mounted) {
      _loadShops();
    }
  }

  List<Shop> get _filteredShops {
    if (_searchQuery.trim().isEmpty) return _shops;
    final q = _searchQuery.trim().toLowerCase();
    return _shops.where((s) {
      final nameMatches = s.shopName.toLowerCase().contains(q);
      final catMatches = s.categoryName.toLowerCase().contains(q);
      return nameMatches || catMatches;
    }).toList();
  }

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.4;

    for (int i = 1; i <= 5; i++) {
      if (i <= fullStars) {
        stars.add(const Icon(Icons.star, color: Colors.amber, size: 14));
      } else if (i == fullStars + 1 && hasHalfStar) {
        stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 14));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 14));
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredShops;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadShops,
          color: const Color(0xFF1E88E5),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Same as home)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Image.asset(
                                'assets/home_logo.png',
                                color: Colors.white,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'MarketPlace',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    // Notification bell
                    GestureDetector(
                      onTap: () async {
                        await Navigator.pushNamed(context, '/announcements');
                        _loadNotificationCount();
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Color(0xFF475569),
                              size: 24,
                            ),
                          ),
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _unreadNotificationCount > 99
                                        ? '99+'
                                        : '$_unreadNotificationCount',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.outfit(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาร้านค้าที่ติดตาม...',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Followed Shops Title & Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ร้านค้าที่คุณติดตาม',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_shops.length} ร้านค้า',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content Area
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      )
                    : displayList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_border,
                                  color: Color(0xFFEF4444),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'ไม่พบร้านค้าที่ตรงกับคำค้นหา'
                                    : 'คุณยังไม่ได้ติดตามร้านค้าใดๆ',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'กดติดตามร้านค้าที่คุณชอบเพื่อรับข่าวสารและเมนูแนะนำก่อนใคร',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final homeState = context
                                      .findAncestorStateOfType<
                                        _HomeScreenState
                                      >();
                                  if (homeState != null) {
                                    homeState.setIndex(0);
                                  }
                                },
                                icon: const Icon(Icons.storefront, size: 18),
                                label: Text(
                                  'สำรวจร้านค้าในตลาด',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E88E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final shop = displayList[index];
                          final rating = _shopRatings[shop.shopId] ?? 0.0;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => _navigateToShopDetail(shop),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Shop Image Avatar with Heart Icon
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: SizedBox(
                                            width: 68,
                                            height: 68,
                                            child:
                                                shop.shopImage != null &&
                                                    shop.shopImage!.isNotEmpty
                                                ? (shop.shopImage!.startsWith(
                                                        'http',
                                                      )
                                                      ? Image.network(
                                                          shop.shopImage!,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : Image.network(
                                                          ApiService.getImagePath(
                                                            shop.shopImage,
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ))
                                                : Container(
                                                    color: const Color(
                                                      0xFFF1F5F9,
                                                    ),
                                                    child: const Icon(
                                                      Icons.storefront,
                                                      color: Color(0xFF94A3B8),
                                                      size: 32,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 2,
                                          top: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    // Shop Details Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            shop.shopName,
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  shop.categoryName,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF475569,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildRatingStars(rating),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (shop.description != null &&
                                              shop.description!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              shop.description!,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Unfollow Button Action
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 22,
                                      ),
                                      tooltip: 'ยกเลิกการติดตาม',
                                      onPressed: () => _unfollowShop(shop),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
