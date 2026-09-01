import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item.dart';
import '../models/item_category.dart';
import '../models/shop.dart';
import '../services/api_service.dart';
import '../services/category_service.dart';
import '../services/item_service.dart';

class ManageMenuCategoryScreen extends StatefulWidget {
  const ManageMenuCategoryScreen({super.key});

  @override
  State<ManageMenuCategoryScreen> createState() =>
      _ManageMenuCategoryScreenState();
}

class _ManageMenuCategoryScreenState extends State<ManageMenuCategoryScreen> {
  Shop? _shop;
  List<ItemCategory> _categories = [];
  List<Item> _allItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final Set<int> _expandedCategoryIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && _shop == null) {
      _shop = args['shop'] as Shop?;
      _allItems = (args['items'] as List<Item>?) ?? [];
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cats = await CategoryService.getItemCategories(
        shopId: _shop?.shopId,
      );

      List<Item> items = _allItems;
      if (_shop != null && _shop!.shopId != null) {
        items = await ItemService.getItemsByShop(_shop!.shopId!);
      } else {
        items = await ItemService.getItems();
      }

      if (mounted) {
        setState(() {
          _categories = cats;
          _allItems = items;
          for (final c in cats) {
            if (c.categoryId != null) {
              _expandedCategoryIds.add(c.categoryId!);
            }
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Item> _getItemsForCategory(ItemCategory cat) {
    return _allItems.where((item) {
      if (item.categoryId != null && cat.categoryId != null) {
        return item.categoryId == cat.categoryId;
      }
      return item.categoryName.trim().toLowerCase() ==
          cat.categoryName.trim().toLowerCase();
    }).toList();
  }

  List<ItemCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    final q = _searchQuery.toLowerCase();
    return _categories.where((cat) {
      final matchCat = cat.categoryName.toLowerCase().contains(q);
      final items = _getItemsForCategory(cat);
      final matchItem = items.any((i) => i.itemName.toLowerCase().contains(q));
      return matchCat || matchItem;
    }).toList();
  }

  // 1. Create New Category Dialog
  Future<void> _showCreateCategoryDialog() async {
    final controller = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.create_new_folder_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'สร้างหมวดหมู่ใหม่',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบุชื่อหมวดหมู่ที่ต้องการสร้าง',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'เช่น อาหารทานเล่น, เมนูแนะนำ, เครื่องดื่ม',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'บันทึก',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (created != null && created.isNotEmpty && mounted) {
      final res = await CategoryService.createItemCategory(
        categoryName: created,
        shopId: _shop?.shopId,
      );
      if (mounted) {
        if (res['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'สร้างหมวดหมู่ "$created" สำเร็จ',
                style: GoogleFonts.outfit(),
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['message']?.toString() ?? 'เกิดข้อผิดพลาดในการสร้างหมวดหมู่',
                style: GoogleFonts.outfit(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // 2. Edit Category Name Dialog
  Future<void> _showEditCategoryDialog(ItemCategory cat) async {
    final controller = TextEditingController(text: cat.categoryName);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'แก้ไขชื่อหมวดหมู่',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เปลี่ยนชื่อหมวดหมู่ "${cat.categoryName}"',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'ชื่อหมวดหมู่',
                hintStyle: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && text != cat.categoryName) {
                Navigator.pop(ctx, text);
              } else {
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'บันทึก',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty && cat.categoryId != null && mounted) {
      final res = await CategoryService.updateItemCategory(
        cat.categoryId!,
        updated,
        shopId: _shop?.shopId,
      );
      if (mounted) {
        if (res['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เปลี่ยนชื่อหมวดหมู่สำเร็จ', style: GoogleFonts.outfit()),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['message']?.toString() ?? 'เกิดข้อผิดพลาดในการแก้ไข',
                style: GoogleFonts.outfit(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // 3. Delete Category Dialog
  Future<void> _showDeleteCategoryDialog(ItemCategory cat) async {
    final itemsCount = _getItemsForCategory(cat).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ลบหมวดหมู่',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          itemsCount > 0
              ? 'คุณต้องการลบหมวดหมู่ "${cat.categoryName}" หรือไม่?\n\n(สินค้า $itemsCount รายการในหมวดนี้จะไม่ถูกลบ แต่จะถูกย้ายไปหมวดหมู่ทั่วไป)'
              : 'คุณต้องการลบหมวดหมู่ "${cat.categoryName}" หรือไม่?',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF475569),
            height: 1.4,
          ),
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
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'ลบหมวดหมู่',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && cat.categoryId != null && mounted) {
      final ok = await CategoryService.deleteItemCategory(
        cat.categoryId!,
        shopId: _shop?.shopId,
      );
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบหมวดหมู่สำเร็จ', style: GoogleFonts.outfit()),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ไม่สามารถลบหมวดหมู่นี้ได้',
                style: GoogleFonts.outfit(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // 4. Add Items to Category Sheet
  Future<void> _showAddItemsToCategorySheet(ItemCategory cat) async {
    final currentCatItemIds = _getItemsForCategory(cat)
        .map((i) => i.itemId)
        .whereType<int>()
        .toSet();

    final candidateItems = _allItems
        .where((i) => i.itemId != null && !currentCatItemIds.contains(i.itemId))
        .toList();

    if (candidateItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'สินค้าทั้งหมดในร้านอยู่ในหมวดนี้แล้ว หรือยังไม่มีสินค้าอื่น',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    final selectedToAdd = <int>{};
    String sheetSearch = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filteredCandidates = candidateItems.where((i) {
              if (sheetSearch.isEmpty) return true;
              return i.itemName.toLowerCase().contains(
                    sheetSearch.toLowerCase(),
                  );
            }).toList();

            return FractionallySizedBox(
              heightFactor: 0.8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เพิ่มสินค้าเข้าหมวดหมู่',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'หมวดหมู่: ${cat.categoryName}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  color: const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      onChanged: (val) {
                        setSheetState(() => sheetSearch = val);
                      },
                      style: GoogleFonts.outfit(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาเมนู/สินค้า...',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              for (final i in filteredCandidates) {
                                if (i.itemId != null) selectedToAdd.add(i.itemId!);
                              }
                            });
                          },
                          child: Text(
                            'เลือกทั้งหมด',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedToAdd.clear();
                            });
                          },
                          child: Text(
                            'ล้างทั้งหมด',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'เลือกแล้ว ${selectedToAdd.length} รายการ',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredCandidates.isEmpty
                          ? Center(
                              child: Text(
                                'ไม่พบสินค้า',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredCandidates.length,
                              itemBuilder: (ctx, idx) {
                                final item = filteredCandidates[idx];
                                final isSelected =
                                    selectedToAdd.contains(item.itemId);

                                return GestureDetector(
                                  onTap: () {
                                    setSheetState(() {
                                      if (isSelected) {
                                        selectedToAdd.remove(item.itemId);
                                      } else {
                                        if (item.itemId != null) {
                                          selectedToAdd.add(item.itemId!);
                                        }
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFF0F7FF)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            color: const Color(0xFFEFF6FF),
                                            child: item.itemImage != null &&
                                                    item.itemImage!.isNotEmpty
                                                ? Image.network(
                                                    ApiService.getImagePath(
                                                      item.itemImage,
                                                    ),
                                                    width: 44,
                                                    height: 44,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (c, e, s) =>
                                                            const Icon(
                                                      Icons.fastfood_rounded,
                                                      size: 20,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.fastfood_rounded,
                                                    size: 20,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.itemName,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                              Text(
                                                'ปัจจุบัน: ${item.categoryName} • ฿${item.price.toStringAsFixed(0)}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF2563EB)
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF2563EB)
                                                  : const Color(0xFFCBD5E1),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 14,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: selectedToAdd.isEmpty
                            ? null
                            : () async {
                                Navigator.pop(sheetCtx);
                                if (cat.categoryId != null) {
                                  final res =
                                      await CategoryService.assignItemsToCategory(
                                    cat.categoryId!,
                                    selectedToAdd.toList(),
                                    shopId: _shop?.shopId,
                                  );
                                  if (mounted && res['status'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'เพิ่ม ${selectedToAdd.length} รายการเข้า "${cat.categoryName}" สำเร็จ',
                                          style: GoogleFonts.outfit(),
                                        ),
                                        backgroundColor:
                                            const Color(0xFF10B981),
                                      ),
                                    );
                                    _loadData();
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'ยืนยันเพิ่ม ${selectedToAdd.length} รายการ',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
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
      },
    );
  }

  // 5. Remove Item from Category
  Future<void> _removeItemFromCategory(Item item, ItemCategory cat) async {
    if (item.itemId == null || cat.categoryId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'นำสินค้าออก',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'คุณต้องการนำ "${item.itemName}" ออกจากหมวดหมู่ "${cat.categoryName}" หรือไม่?',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('นำออก'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final res = await CategoryService.removeItemsFromCategory(
        cat.categoryId!,
        [item.itemId!],
        shopId: _shop?.shopId,
      );
      if (mounted && res['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('นำสินค้าออกจากหมวดหมู่แล้ว', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadData();
      }
    }
  }

  // 6. Change Item's Category Dialog
  Future<void> _showChangeItemCategoryDialog(Item item) async {
    int? selectedCatId = item.categoryId;

    final updated = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'ย้ายหมวดหมู่สินค้า',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เลือกหมวดหมู่ใหม่สำหรับ "${item.itemName}"',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _categories.any((c) => c.categoryId == selectedCatId)
                      ? selectedCatId
                      : (_categories.isNotEmpty ? _categories.first.categoryId : null),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  items: _categories.map((c) {
                    return DropdownMenuItem<int>(
                      value: c.categoryId,
                      child: Text(
                        c.categoryName,
                        style: GoogleFonts.outfit(fontSize: 13.5),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDlgState(() => selectedCatId = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('ยกเลิก', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selectedCatId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );

    if (updated != null && item.itemId != null && mounted) {
      final res = await CategoryService.assignItemsToCategory(
        updated,
        [item.itemId!],
        shopId: _shop?.shopId,
      );
      if (mounted && res['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ย้ายหมวดหมู่สินค้าสำเร็จ', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCats = _filteredCategories;

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
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'จัดการประเภทสินค้าและเมนู',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF2563EB),
              size: 24,
            ),
            tooltip: 'สร้างหมวดหมู่ใหม่',
            onPressed: _showCreateCategoryDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFF1F5F9), height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF2563EB),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Column(
                          children: [
                            // 1. Overview Header Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.025),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFFDBEAFE),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.restaurant_menu_rounded,
                                          color: Color(0xFF2563EB),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'หมวดหมู่สินค้าในร้าน',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 15.5,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: const Color(
                                                      0xFF0F172A,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFEFF6FF,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFBFDBFE,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${_categories.length} หมวด',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFF2563EB,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'จัดระเบียบเมนูและสร้างหมวดหมู่สินค้า',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: const Color(
                                                  0xFF64748B,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 42,
                                    child: ElevatedButton.icon(
                                      onPressed: _showCreateCategoryDialog,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 18,
                                      ),
                                      label: Text(
                                        'สร้างหมวดหมู่ใหม่',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2563EB,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              onChanged: (val) {
                                setState(() => _searchQuery = val);
                              },
                              style: GoogleFonts.outfit(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'ค้นหาหมวดหมู่หรือเมนูสินค้า...',
                                hintStyle: GoogleFonts.outfit(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (filteredCats.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.folder_open,
                                size: 52,
                                color: Color(0xFFCBD5E1),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'ไม่พบหมวดหมู่หรือเมนูที่ค้นหา'
                                    : 'ยังไม่มีหมวดหมู่สินค้าในระบบ',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showCreateCategoryDialog,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('สร้างหมวดหมู่แรก'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cat = filteredCats[index];
                              final catItems = _getItemsForCategory(cat);
                              final isExpanded = cat.categoryId != null &&
                                  _expandedCategoryIds.contains(cat.categoryId);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (cat.categoryId != null) {
                                            if (isExpanded) {
                                              _expandedCategoryIds
                                                  .remove(cat.categoryId);
                                            } else {
                                              _expandedCategoryIds
                                                  .add(cat.categoryId!);
                                            }
                                          }
                                        });
                                      },
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    const Color(0xFFEFF6FF),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.folder_outlined,
                                                    size: 16,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${catItems.length}',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFF2563EB,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cat.categoryName,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFF0F172A),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${catItems.length} รายการในหมวดนี้',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11.5,
                                                      color: const Color(
                                                        0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: Color(0xFF2563EB),
                                                size: 18,
                                              ),
                                              tooltip: 'แก้ไขชื่อหมวดหมู่',
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: const EdgeInsets.all(6),
                                              onPressed: () =>
                                                  _showEditCategoryDialog(cat),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              tooltip: 'ลบหมวดหมู่',
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: const EdgeInsets.all(6),
                                              onPressed: () =>
                                                  _showDeleteCategoryDialog(
                                                    cat,
                                                  ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isExpanded) ...[
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'รายการสินค้าในหมวดนี้ (${catItems.length})',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: const Color(
                                                      0xFF475569),
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _showAddItemsToCategorySheet(
                                                        cat,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.add,
                                                    size: 15,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                  label: Text(
                                                    'เพิ่มเมนูเข้าหมวดนี้',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFF2563EB),
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            if (catItems.isEmpty)
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF8FAFC),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFFF1F5F9),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .restaurant_menu_outlined,
                                                      size: 28,
                                                      color: Color(0xFFCBD5E1),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'ยังไม่มีสินค้าในหมวดนี้',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 12.5,
                                                        color: const Color(
                                                          0xFF94A3B8),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _showAddItemsToCategorySheet(
                                                            cat,
                                                          ),
                                                      child: Text(
                                                        '+ กดเพื่อเลือกเมนูเข้าหมวดนี้',
                                                        style:
                                                            GoogleFonts.outfit(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: const Color(
                                                            0xFF2563EB),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              ...catItems.map((item) {
                                                return Container(
                                                  margin:
                                                      const EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF8FAFC),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFF1F5F9),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: Container(
                                                          width: 42,
                                                          height: 42,
                                                          color: const Color(
                                                            0xFFEFF6FF),
                                                          child: item.itemImage !=
                                                                      null &&
                                                                  item.itemImage!
                                                                      .isNotEmpty
                                                              ? Image.network(
                                                                  ApiService
                                                                      .getImagePath(
                                                                    item
                                                                        .itemImage),
                                                                  width: 42,
                                                                  height: 42,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (
                                                                    c,
                                                                    e,
                                                                    s,
                                                                  ) =>
                                                                      const Icon(
                                                                    Icons
                                                                        .fastfood_rounded,
                                                                    color: Color(
                                                                      0xFF2563EB),
                                                                    size: 20,
                                                                  ),
                                                                )
                                                              : const Icon(
                                                                  Icons
                                                                      .fastfood_rounded,
                                                                  color: Color(
                                                                    0xFF2563EB),
                                                                  size: 20,
                                                                ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              item.itemName,
                                                              style: GoogleFonts
                                                                  .outfit(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    const Color(
                                                                  0xFF0F172A),
                                                              ),
                                                            ),
                                                            Text(
                                                              '฿${item.price.toStringAsFixed(0)} • ${item.isAvailable ? "เปิดขาย" : "หมด"}',
                                                              style: GoogleFonts
                                                                  .outfit(
                                                                fontSize: 11,
                                                                color:
                                                                    const Color(
                                                                  0xFF64748B),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.swap_horiz,
                                                          size: 18,
                                                          color: Color(
                                                            0xFF2563EB),
                                                        ),
                                                        tooltip:
                                                            'ย้ายหมวดหมู่อื่น',
                                                        constraints:
                                                            const BoxConstraints(),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        onPressed: () =>
                                                            _showChangeItemCategoryDialog(
                                                              item,
                                                            ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          size: 16,
                                                          color: Color(
                                                            0xFF94A3B8),
                                                        ),
                                                        tooltip:
                                                            'นำออกจากหมวดหมู่นี้',
                                                        constraints:
                                                            const BoxConstraints(),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        onPressed: () =>
                                                            _removeItemFromCategory(
                                                              item,
                                                              cat,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                            childCount: filteredCats.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
