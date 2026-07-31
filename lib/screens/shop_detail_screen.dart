import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../services/item_service.dart';
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
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.currentUser != null &&
        auth.currentUser!.userId != null &&
        _shop.shopId != null) {
      _checkFollowStatus(auth.currentUser!.userId!, _shop.shopId!);
    }
  }

  Future<void> _checkFollowStatus(int userId, int shopId) async {
    final isFollowing =
        await ShopService.isShopFollowed(userId: userId, shopId: shopId);
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
        userId: user.userId!, shopId: _shop.shopId!);
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
              heightFactor: 0.7,
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

    // Generate dynamic categories from the items list
    final List<String> categories = ['ทั้งหมด'];
    for (var item in _items) {
      final catName = item.categoryName;
      if (!categories.contains(catName)) {
        categories.add(catName);
      }
    }

    // Filter items based on selected category
    final filteredItems = _selectedCategory == 'ทั้งหมด'
        ? _items
        : _items
              .where((item) => item.categoryName == _selectedCategory)
              .toList();

    // Deterministic mock values matching style of screen shot
    final stallNumber = 'แผง A${(shop.shopId ?? 0) % 8 + 1}';
    final rating = 4.5 + ((shop.shopId ?? 0) % 5) * 0.1;
    final reviewsCount = 50 + ((shop.shopId ?? 0) % 6) * 15;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ร้านค้า',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Header Card Container
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child:
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
                                        ))
                                : Container(
                                    color: const Color(0xFFE2E8F0),
                                    child: const Icon(
                                      Icons.storefront,
                                      color: Color(0xFF94A3B8),
                                      size: 40,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Shop Info Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.shopName,
                                style: GoogleFonts.outfit(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    shop.categoryName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '•',
                                    style: TextStyle(color: Color(0xFFCBD5E1)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    stallNumber,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E88E5),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${rating.toStringAsFixed(1)} ($reviewsCount+ รีวิว)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Favorite / Follow Button
                        GestureDetector(
                          onTap: _toggleFollow,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? Colors.red
                                  : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Menu Header with Title and Review badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เมนู',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      // Review Badge Button
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
                          if (result != null && result is int && mounted) {
                            navigator.pop(result);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'รีวิว',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Category Filter Tags (Horizontal list)
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE3F2FD)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1E88E5)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isSelected ? '✓ $category' : category,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF1E88E5)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Food Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return InkWell(
                        onTap: () => _showItemDetailDialog(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
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
                                    const SizedBox(height: 6),
                                    if (item.description != null &&
                                        item.description!.isNotEmpty)
                                      Text(
                                        item.description!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: const Color(0xFF64748B),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.price.toStringAsFixed(0)} บาท',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E88E5),
                                          ),
                                        ),
                                        if (item.allImages.length > 1) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.collections,
                                            size: 14,
                                            color: Color(0xFF10B981),
                                          ),
                                          const SizedBox(width: 2),
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
                              const SizedBox(width: 12),
                              // Food Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 85,
                                  height: 85,
                                  child:
                                      item.itemImage != null &&
                                          item.itemImage!.isNotEmpty
                                      ? (item.itemImage!.startsWith('http')
                                            ? Image.network(
                                                item.itemImage!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                ApiService.getImagePath(
                                                  item.itemImage,
                                                ),
                                                fit: BoxFit.cover,
                                              ))
                                      : Container(
                                          color: const Color(0xFFF1F5F9),
                                          child: const Icon(
                                            Icons.storefront,
                                            color: Color(0xFF94A3B8),
                                            size: 30,
                                          ),
                                        ),
                                ),
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
                  Icons.home,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'หน้าหลัก',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.explore_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.explore,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'แผนที่ตลาด',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.favorite_outline,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.favorite,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'ติดตาม',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
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
