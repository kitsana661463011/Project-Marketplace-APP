import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../services/item_service.dart';

class ManageShopScreen extends StatefulWidget {
  const ManageShopScreen({super.key});

  @override
  State<ManageShopScreen> createState() => _ManageShopScreenState();
}

class _ManageShopScreenState extends State<ManageShopScreen> {
  List<Item> _items = [];
  bool _isLoading = true;
  String _selectedCategory = 'ทั้งหมด';
  List<String> _categories = ['ทั้งหมด'];

  // Local category-to-items mapping (stored in memory for this session)
  final Map<String, Set<int>> _categoryItemIds = {};

  // Toggle states for items (item_id -> isAvailable)
  final Map<int, bool> _itemAvailability = {};

  late Shop _shop;
  // ignore: unused_field
  late String _stallNumber;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _shop = args['shop'] as Shop;
    _stallNumber = args['stall_number'] as String? ?? 'C2';
    if (_isLoading) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    try {
      final items = await ItemService.getItemsByShop(_shop.shopId ?? 0);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
          // Initialize availability toggles
          for (final item in items) {
            _itemAvailability.putIfAbsent(item.itemId ?? 0, () => true);
          }
          _rebuildCategories();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // If no items loaded from DB, show mock data
    if (_items.isEmpty) {
      setState(() {
        _items = [
          Item(itemId: 1, shopId: _shop.shopId, itemName: 'กะเพรา', price: 50, description: 'ผัดกะเพราหมูสับ', itemImage: 'kaprao_chicken.png', categoryId: 1),
          Item(itemId: 2, shopId: _shop.shopId, itemName: 'กะเพราไก่ไข่ดาว', price: 60, description: 'ผัดกะเพราไก่ใส่ไข่ดาว', itemImage: 'kaprao_chicken.png', categoryId: 1),
        ];
        for (final item in _items) {
          _itemAvailability.putIfAbsent(item.itemId ?? 0, () => true);
        }
        // Mock default categories
        _categoryItemIds['เมนูแนะนำ'] = {1, 2};
        _categoryItemIds['อาหารจานเดียว'] = {1};
        _rebuildCategories();
      });
    }
  }

  void _rebuildCategories() {
    final cats = <String>['ทั้งหมด'];
    cats.addAll(_categoryItemIds.keys);
    _categories = cats;
  }

  List<Item> get _filteredItems {
    if (_selectedCategory == 'ทั้งหมด') return _items;
    final ids = _categoryItemIds[_selectedCategory] ?? {};
    return _items.where((item) => ids.contains(item.itemId)).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          'หน้าจัดการร้านค้า',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Shop Profile Banner
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Shop Avatar
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFFEFF6FF),
                              backgroundImage: _shop.shopImage != null
                                  ? NetworkImage('http://10.0.2.2:8000/storage/custom_images/${_shop.shopImage}')
                                  : null,
                              child: _shop.shopImage == null
                                  ? const Icon(Icons.storefront, color: Color(0xFF2563EB), size: 32)
                                  : null,
                            ),
                            const Spacer(),
                            // Edit Profile button
                            OutlinedButton.icon(
                              onPressed: () {
                                // Future: navigate to edit profile
                              },
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: Text(
                                'แก้ไขโปรไฟล์',
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _shop.shopName,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Follower Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.favorite, color: Color(0xFF2563EB), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ผู้ติดตาม',
                                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '1,250 คน',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
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

                  const SizedBox(height: 12),

                  // 2. จัดการรายการอาหาร Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'จัดการรายการอาหาร',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category filter row
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _categories.length + 1, // +1 for the "+" button
                      itemBuilder: (context, index) {
                        if (index == _categories.length) {
                          // "+" button to manage categories
                          return GestureDetector(
                            onTap: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/manage_menu_category',
                                arguments: {
                                  'shop': _shop,
                                  'items': _items,
                                  'category_item_ids': _categoryItemIds,
                                },
                              );
                              if (result is Map<String, Set<int>>) {
                                setState(() {
                                  _categoryItemIds.clear();
                                  _categoryItemIds.addAll(result);
                                  _rebuildCategories();
                                });
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Icon(Icons.add, color: Color(0xFF2563EB), size: 20),
                            ),
                          );
                        }

                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items List
                  ..._filteredItems.map((item) => _buildItemCard(item)),

                  if (_filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.restaurant_menu, size: 48, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            Text(
                              'ยังไม่มีรายการอาหารในหมวดนี้',
                              style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/add_menu',
            arguments: {'shop': _shop},
          );
          if (result == true) {
            _loadItems();
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFF1F5F9), width: 1.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_outlined, 'หน้าหลัก', false, 0),
            _buildNavItem(context, Icons.explore_outlined, 'แผนที่', false, 1),
            _buildNavItem(context, Icons.favorite_outline, 'ติดตาม', false, 2),
            _buildNavItem(context, Icons.person, 'เมนู', true, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final isAvailable = _itemAvailability[item.itemId ?? 0] ?? true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              'http://10.0.2.2:8000/storage/custom_images/${item.itemImage}',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/${item.itemImage}',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.fastfood, color: Color(0xFF2563EB)),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 14),

          // Item Name + Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '฿${item.price.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),

          // Toggle + Label
          Column(
            children: [
              Switch(
                value: isAvailable,
                onChanged: (val) {
                  setState(() {
                    _itemAvailability[item.itemId ?? 0] = val;
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF2563EB),
                inactiveTrackColor: const Color(0xFFE2E8F0),
                inactiveThumbColor: const Color(0xFF94A3B8),
              ),
              Text(
                isAvailable ? 'เปิดขาย' : 'ปิดขาย',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
