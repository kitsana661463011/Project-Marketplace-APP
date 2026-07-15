import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../services/item_service.dart';
import '../services/api_service.dart';

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

  // Mock menu items matching the screenshot in case the API has no data
  List<Item> _getMockItems(int? shopId) {
    return [
      Item(
        itemId: 1,
        shopId: shopId,
        itemName: 'ต้มยำกุ้งน้ำข้น',
        description: 'ต้มยำรสแซ่บเครื่องสมุนไพรครบเครื่อง พร้อมกุ้งสดเด้ง',
        price: 60.0,
        itemImage: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400',
        categoryId: 1,
        category: {'category_name': 'ต้มยำ'},
      ),
      Item(
        itemId: 2,
        shopId: shopId,
        itemName: 'กระเพราหมูสับ',
        description: 'กะเพราหมูสับสูตรแซ่บซี้ด',
        price: 75.0,
        itemImage: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
        categoryId: 2,
        category: {'category_name': 'อาหารจานเดียว'},
      ),
      Item(
        itemId: 3,
        shopId: shopId,
        itemName: 'ไข่เจียวทรงเครื่อง',
        description: 'ไข่เจียวฟูๆ ใส่เครื่องแน่นๆ รสชาติกลมกล่อม',
        price: 40.0,
        itemImage: 'https://images.unsplash.com/photo-1518492104633-130d0cc84637?w=400',
        categoryId: 3,
        category: {'category_name': 'อาหารจานเดียว'},
      ),
    ];
  }

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
  }

  Future<void> _loadItems(int? shopId) async {
    if (shopId == null) {
      setState(() {
        _items = _getMockItems(shopId);
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final items = await ItemService.getItemsByShop(shopId);
      if (mounted) {
        setState(() {
          _items = items.isNotEmpty ? items : _getMockItems(shopId);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = _getMockItems(shopId);
          _isLoading = false;
        });
      }
    }
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
        : _items.where((item) => item.categoryName == _selectedCategory).toList();

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
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
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
                            child: shop.shopImage != null && shop.shopImage!.isNotEmpty
                                ? (shop.shopImage!.startsWith('http')
                                    ? Image.network(shop.shopImage!, fit: BoxFit.cover)
                                    : Image.network(ApiService.getImagePath(shop.shopImage), fit: BoxFit.cover))
                                : Container(
                                    color: const Color(0xFFE2E8F0),
                                    child: const Icon(Icons.storefront, color: Color(0xFF94A3B8), size: 40),
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
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
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
                        // Favorite Button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFavorite = !_isFavorite;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : const Color(0xFF94A3B8),
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
                            arguments: {'shop': _shop, 'tabIndex': _originTabIndex},
                          );
                          if (result != null && result is int && mounted) {
                            navigator.pop(result);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 15),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isSelected ? '✓ $category' : category,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
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
                      return Container(
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
                                  if (item.description != null && item.description!.isNotEmpty)
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
                                  Text(
                                    '${item.price.toStringAsFixed(0)} บาท',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E88E5),
                                    ),
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
                                child: item.itemImage != null && item.itemImage!.isNotEmpty
                                    ? (item.itemImage!.startsWith('http')
                                        ? Image.network(item.itemImage!, fit: BoxFit.cover)
                                        : Image.network(ApiService.getImagePath(item.itemImage), fit: BoxFit.cover))
                                    : Container(
                                        color: const Color(0xFFF1F5F9),
                                        child: const Icon(Icons.storefront, color: Color(0xFF94A3B8), size: 30),
                                      ),
                              ),
                            ),
                          ],
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
              color: Colors.black.withOpacity(0.06),
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
            indicatorColor: const Color(0xFF1E88E5).withOpacity(0.12),
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: 24, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.home, size: 24, color: Color(0xFF1E88E5)),
                label: 'หน้าหลัก',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined, size: 24, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.explore, size: 24, color: Color(0xFF1E88E5)),
                label: 'แผนที่ตลาด',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline, size: 24, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.favorite, size: 24, color: Color(0xFF1E88E5)),
                label: 'ติดตาม',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, size: 24, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.person, size: 24, color: Color(0xFF1E88E5)),
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
