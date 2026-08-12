import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../services/item_service.dart';
import '../services/review_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/shop_service.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({super.key});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  bool _isFavorite = false;
  String _selectedCategory = 'ทั้งหมด';
  List<Item> _items = [];
  bool _isLoading = true;
  int _originTabIndex = 0;
  late Shop _shop;
  int _reviewCount = 0;
  double _averageRating = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Shop) {
      _shop = args;
      _originTabIndex = 0;
    } else if (args is Map) {
      _shop = args['shop'] as Shop;
      _originTabIndex = args['tabIndex'] as int? ?? 0;
    }
    _loadItems(_shop.shopId);
    _loadReviewSummary(_shop.shopId);
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null &&
        auth.currentUser!.userId != null &&
        _shop.shopId != null) {
      _checkFollowStatus(auth.currentUser!.userId!, _shop.shopId!);
    }
  }

  Future<void> _checkFollowStatus(int userId, int shopId) async {
    final isFollowing = await ShopService.isShopFollowed(
      userId: userId,
      shopId: shopId,
    );
    if (mounted) {
      setState(() => _isFavorite = isFollowing);
    }
  }

  Future<void> _toggleFollow() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || user.userId == null || _shop.shopId == null) return;

    setState(() => _isFavorite = !_isFavorite);
    final res = await ShopService.toggleFollowShop(
      userId: user.userId!,
      shopId: _shop.shopId!,
    );
    if (mounted && res['status'] == true) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'อัปเดตการติดตามเรียบร้อยแล้ว'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadItems(int? shopId) async {
    if (shopId == null) {
      setState(() {
        _items = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final items = await ItemService.getItemsByShop(shopId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReviewSummary(int? shopId) async {
    if (shopId == null) {
      if (mounted) {
        setState(() {
          _reviewCount = 0;
          _averageRating = 0.0;
        });
      }
      return;
    }

    try {
      final reviews = await ReviewService.getReviewsByShop(shopId);
      if (!mounted) return;

      final int count = reviews.length;
      double totalRating = 0.0;
      for (final json in reviews) {
        final ratingValue = json['rating'];
        final rating = ratingValue is num
            ? ratingValue.toDouble()
            : double.tryParse(ratingValue?.toString() ?? '0') ?? 0.0;
        totalRating += rating;
      }

      setState(() {
        _reviewCount = count;
        _averageRating = count > 0 ? totalRating / count : 0.0;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _reviewCount = 0;
          _averageRating = 0.0;
        });
      }
    }
  }

  String _formatSocialLinks(String? socialRaw) {
    if (socialRaw == null || socialRaw.trim().isEmpty) {
      return 'ไม่มีข้อมูลช่องทางออนไลน์';
    }
    final text = socialRaw.trim();
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final Map<String, dynamic> map = jsonDecode(text);
        final List<String> parts = [];
        map.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            final k = key.toLowerCase();
            String prefix = key.toUpperCase();
            if (k == 'line') prefix = 'LINE';
            if (k == 'facebook' || k == 'fb') prefix = 'Facebook';
            if (k == 'instagram' || k == 'ig') prefix = 'IG';
            if (k == 'tiktok') prefix = 'TikTok';
            parts.add('$prefix: ${value.toString()}');
          }
        });
        if (parts.isNotEmpty) return parts.join('\n');
      } catch (_) {}
    }
    return text;
  }

  void _showContactDialog() {
    final phone = _shop.shopPhone ?? '081-234-5678';
    final socialFormatted = _formatSocialLinks(_shop.socialLinks);
    final stallLocation =
        _shop.stallNumber != null && _shop.stallNumber!.isNotEmpty
            ? 'แผง ${_shop.stallNumber}'
            : 'แผง B03';
    final zoneInfo = _shop.zoneName != null && _shop.zoneName!.isNotEmpty
        ? _shop.zoneName!
        : 'โซนตลาดใต้ตึกรายเดือน';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag indicator line
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.contact_support_rounded,
                            color: Color(0xFF1E88E5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ข้อมูลติดต่อร้านค้า',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              _shop.shopName,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Card 1: Phone Number
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.phone_in_talk_rounded,
                          color: Color(0xFF1E88E5),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เบอร์โทรศัพท์',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: phone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('คัดลอกเบอร์โทรศัพท์เรียบร้อยแล้ว'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: Text(
                          'คัดลอก',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card 2: Social Media
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ช่องทางโซเชียลมีเดีย',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              socialFormatted,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card 3: Stall Location Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFFF59E0B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ตำแหน่งแผงค้าในตลาด',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$stallLocation ($zoneInfo)',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Primary Close Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'ตกลง',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showItemDetailDialog(Item item) {
    final images = item.allImages;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int activePage = 0;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: images.isNotEmpty
                            ? PageView.builder(
                                itemCount: images.length,
                                onPageChanged: (index) {
                                  setModalState(() => activePage = index);
                                },
                                itemBuilder: (context, index) {
                                  final img = images[index];
                                  return ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                    child: img.startsWith('http')
                                        ? Image.network(img, fit: BoxFit.cover)
                                        : Image.asset(
                                            'assets/$img',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                Image.network(
                                                  ApiService.getImagePath(img),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      Container(
                                                        color: const Color(
                                                          0xFFF1F5F9,
                                                        ),
                                                        child: const Icon(
                                                          Icons.fastfood,
                                                          size: 50,
                                                          color: Color(
                                                            0xFF94A3B8,
                                                          ),
                                                        ),
                                                      ),
                                                ),
                                          ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: Icon(
                                    Icons.fastfood,
                                    size: 60,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (idx) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: activePage == idx ? 16 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: activePage == idx
                                      ? Colors.white
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.itemName,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              '${item.price.toStringAsFixed(0)} บาท',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E88E5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                            item.categoryName,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        if (images.length > 1) ...[
                          const SizedBox(height: 8),
                          Text(
                            '📸 รูปภาพหลายมุม (${images.length} รูป - สไลด์เพื่อดูมุมอื่นๆ)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          item.description ?? 'ไม่มีคำอธิบายเพิ่มเติม',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = _shop;

    // Dynamic category list from menu items
    final List<String> categories = ['ทั้งหมด'];
    for (var item in _items) {
      final catName = item.categoryName;
      if (!categories.contains(catName)) {
        categories.add(catName);
      }
    }

    final filteredItems = _selectedCategory == 'ทั้งหมด'
        ? _items
        : _items
              .where((item) => item.categoryName == _selectedCategory)
              .toList();

    final stallLocation =
        shop.stallNumber != null && shop.stallNumber!.isNotEmpty
            ? 'แผง ${shop.stallNumber}'
            : 'แผง A${(shop.shopId ?? 0) % 8 + 1}';
    final zoneInfo = shop.zoneName != null && shop.zoneName!.isNotEmpty
        ? shop.zoneName!
        : 'โซนตลาดใต้ตึก';
    final rating = _reviewCount > 0 ? _averageRating : (shop.avgRating ?? 4.5);
    final reviewsCount = _reviewCount > 0 ? _reviewCount : shop.reviewCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
            )
          : CustomScrollView(
              slivers: [
                // 1. Hero Cover Image SliverAppBar with Floating Profile Card
                SliverAppBar(
                  expandedHeight: 245,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF0F172A),
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isFavorite
                              ? Colors.red
                              : const Color(0xFF475569),
                          size: 20,
                        ),
                        onPressed: _toggleFollow,
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Cover Photo Banner (Top Portion)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 165,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              shop.shopImage != null &&
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
                                              (_, _, _) =>
                                                  _buildCoverBannerPlaceholder(),
                                        ))
                                  : _buildCoverBannerPlaceholder(),

                              // Gradient Overlay for contrast
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.4),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.3),
                                    ],
                                    stops: const [0.0, 0.4, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // GrabFood Style Floating Header Card (Z-Layer ON TOP of cover photo)
                        Positioned(
                          top: 110,
                          left: 16,
                          right: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Shop Avatar Image (GrabFood style)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    color: const Color(0xFFEFF6FF),
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
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.storefront,
                                                      color: Color(
                                                        0xFF2563EB,
                                                      ),
                                                      size: 32,
                                                    ),
                                              ))
                                        : const Icon(
                                            Icons.storefront,
                                            color: Color(0xFF2563EB),
                                            size: 32,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Right side: Shop Name, Stall Location, Badges
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        shop.shopName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.place_rounded,
                                            color: Color(0xFF2563EB),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              '$stallLocation ($zoneInfo)',
                                              style: GoogleFonts.outfit(
                                                color: const Color(
                                                  0xFF1E40AF,
                                                ),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          // Shop Status Badge (Dynamic)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                            decoration: BoxDecoration(
                                              color:
                                                  shop.isOpen
                                                      ? const Color(0xFFECFDF5)
                                                      : const Color(
                                                        0xFFFEF2F2,
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    shop.isOpen
                                                        ? const Color(
                                                          0xFFA7F3D0,
                                                        )
                                                        : const Color(
                                                          0xFFFECACA,
                                                        ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color:
                                                      shop.isOpen
                                                          ? const Color(
                                                            0xFF10B981,
                                                          )
                                                          : const Color(
                                                            0xFFEF4444,
                                                          ),
                                                  size: 7,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  shop.isOpen
                                                      ? 'เปิดบริการอยู่'
                                                      : 'ปิดบริการชั่วคราว',
                                                  style: GoogleFonts.outfit(
                                                    color:
                                                        shop.isOpen
                                                            ? const Color(
                                                              0xFF047857,
                                                            )
                                                            : const Color(
                                                              0xFFB91C1C,
                                                            ),
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Category Pill
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0F172A),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              shop.categoryName,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Shop Details Body (Badges, Quick Actions, Description, Menu Title & Category Chips)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating & Followers Badges
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Rating Badge (Clickable to reviews)
                              GestureDetector(
                                onTap: () async {
                                  final navigator = Navigator.of(context);
                                  final result = await navigator.pushNamed(
                                    '/shop_reviews',
                                    arguments: {
                                      'shop': _shop,
                                      'tabIndex': _originTabIndex,
                                    },
                                  );
                                  if (result != null &&
                                      result is int &&
                                      mounted) {
                                    navigator.pop(result);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFCD34D),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFF59E0B),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${rating.toStringAsFixed(1)} ($reviewsCount รีวิว)',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFB45309),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: Color(0xFFB45309),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Followers Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.redAccent,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${shop.followerCount} ผู้ติดตาม',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF475569),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick Action Buttons Row (โทร, แผนที่, รีวิว)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.phone_outlined,
                                  label: 'ติดต่อร้าน',
                                  color: const Color(0xFF2563EB),
                                  bgColor: const Color(0xFFEFF6FF),
                                  onTap: _showContactDialog,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.map_outlined,
                                  label: 'ตำแหน่งแผง',
                                  color: const Color(0xFF059669),
                                  bgColor: const Color(0xFFECFDF5),
                                  onTap: () {
                                    final String stallLocation =
                                        _shop.stallNumber ?? 'C02';
                                    Navigator.pushNamed(
                                      context,
                                      '/market_map',
                                      arguments: {
                                        'shop': _shop,
                                        'stall_number': stallLocation,
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.rate_review_outlined,
                                  label: 'เขียนรีวิว',
                                  color: const Color(0xFFD97706),
                                  bgColor: const Color(0xFFFFFBEB),
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    final result = await navigator.pushNamed(
                                      '/write_review',
                                      arguments: _shop,
                                    );
                                    if (result == true && mounted) {
                                      _loadItems(_shop.shopId);
                                      _loadReviewSummary(_shop.shopId);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Description text (only if description is NOT identical to shop name)
                        if (shop.description != null &&
                            shop.description!.trim().isNotEmpty &&
                            shop.description!.trim().toLowerCase() !=
                                shop.shopName.trim().toLowerCase()) ...[
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              shop.description!,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),

                        // Section Title: Menu & Filter
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'รายการเมนู (${filteredItems.length})',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category Filter Chips (Horizontal list)
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected = _selectedCategory == category;
                              final count = category == 'ทั้งหมด'
                                  ? _items.length
                                  : _items
                                        .where(
                                          (i) => i.categoryName == category,
                                        )
                                        .length;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1E88E5)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1E88E5)
                                          : const Color(0xFFCBD5E1),
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF1E88E5)
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    '$category ($count)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 3. Menu Item Cards List
                filteredItems.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Text(
                            'ยังไม่มีรายการเมนูในหมวดหมู่นี้',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = filteredItems[index];
                              return _buildMenuItemCard(item);
                            },
                            childCount: filteredItems.length,
                          ),
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
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
            selectedIndex: _originTabIndex,
            onDestinationSelected: (index) {
              Navigator.pop(context, index);
            },
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF1E88E5).withValues(alpha: 0.12),
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'หน้าแรก',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.explore_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.explore_rounded,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'แผนที่ตลาด',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.favorite_outline_rounded,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.favorite_rounded,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'ติดตามแล้ว',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline_rounded,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.person_rounded,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: () => _showItemDetailDialog(item),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description ?? 'รสชาติอร่อย เข้มข้น คัดสรรอย่างดี',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.price.toStringAsFixed(0)} บาท',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                        ),
                        if (item.allImages.length > 1) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.collections_outlined,
                            size: 14,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${item.allImages.length} รูป',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Item Image Container
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: item.itemImage != null && item.itemImage!.isNotEmpty
                      ? (item.itemImage!.startsWith('http')
                          ? Image.network(item.itemImage!, fit: BoxFit.cover)
                          : Image.network(
                              ApiService.getImagePath(item.itemImage),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildItemPlaceholder(),
                            ))
                      : _buildItemPlaceholder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverBannerPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.storefront_rounded, size: 70, color: Colors.white24),
      ),
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: Color(0xFF94A3B8),
          size: 32,
        ),
      ),
    );
  }
}
