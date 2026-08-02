import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../models/shop_category.dart';
import '../services/item_service.dart';
import '../services/shop_service.dart';
import '../services/api_service.dart';
import '../services/category_service.dart';
import '../widgets/app_dialog.dart';

class ManageShopScreen extends StatefulWidget {
  const ManageShopScreen({super.key});

  @override
  State<ManageShopScreen> createState() => _ManageShopScreenState();
}

class _ManageShopScreenState extends State<ManageShopScreen> {
  List<Item> _items = [];
  bool _isLoading = true;
  bool _isShopLoading = true;
  String _selectedCategory = 'ทั้งหมด';
  List<String> _categories = ['ทั้งหมด'];

  // Local category-to-items mapping (stored in memory for this session)
  final Map<String, Set<int>> _categoryItemIds = {};

  // Toggle states for items (item_id -> isAvailable)
  final Map<int, bool> _itemAvailability = {};

  late Shop _shop;
  // ignore: unused_field
  late String _stallNumber;
  bool _isRouteArgsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isRouteArgsLoaded) {
      final route = ModalRoute.of(context);
      final rawArgs = route?.settings.arguments;
      Map<String, dynamic>? args;

      if (rawArgs is Map<String, dynamic>) {
        args = rawArgs;
      } else if (rawArgs is Map) {
        args = Map<String, dynamic>.from(rawArgs);
      }

      if (args != null && args['shop'] is Shop) {
        _shop = args['shop'] as Shop;
        _stallNumber = args['stall_number']?.toString() ?? 'C2';
      } else {
        _shop = Shop(shopName: 'ร้านค้า', followerCount: 0);
        _stallNumber = 'C2';
      }
      _isRouteArgsLoaded = true;
    }

    if (_isLoading) {
      _loadItems();
    }
    if (_isShopLoading) {
      _loadShopDetail();
    }
  }

  Future<void> _loadShopDetail() async {
    if (_shop.shopId == null) {
      setState(() {
        _isShopLoading = false;
      });
      return;
    }

    try {
      final shop = await ShopService.getShop(_shop.shopId!);
      if (mounted) {
        setState(() {
          if (shop != null) {
            _shop = shop;
          }
          _isShopLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isShopLoading = false;
        });
      }
    }
  }

  Future<void> _loadItems() async {
    try {
      final items = await ItemService.getItemsByShop(_shop.shopId ?? 0);
      debugPrint(
        'ManageShopScreen: _loadItems fetched ${items.length} items for shopId=${_shop.shopId}',
      );
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
          // Initialize availability toggles
          for (final item in items) {
            _itemAvailability.putIfAbsent(
              item.itemId ?? 0,
              () => item.isAvailable,
            );
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
  }

  void _rebuildCategories() {
    final cats = <String>['ทั้งหมด'];

    for (final item in _items) {
      final categoryName = item.categoryName.trim();
      if (categoryName.isNotEmpty && !cats.contains(categoryName)) {
        cats.add(categoryName);
      }
    }

    for (final key in _categoryItemIds.keys) {
      if (!cats.contains(key)) {
        cats.add(key);
      }
    }

    _categories = cats;
  }

  List<Item> get _filteredItems {
    if (_selectedCategory == 'ทั้งหมด') return _items;

    final ids = _categoryItemIds[_selectedCategory];
    if (ids != null && ids.isNotEmpty) {
      return _items.where((item) => ids.contains(item.itemId)).toList();
    }

    return _items
        .where((item) => item.categoryName == _selectedCategory)
        .toList();
  }

  void _showEditShopProfileDialog() {
    final nameController = TextEditingController(text: _shop.shopName);
    final descController = TextEditingController(text: _shop.description ?? '');
    final phoneController = TextEditingController(text: _shop.shopPhone ?? '');
    Uint8List? pickedBytes;
    String? pickedName;
    bool isSaving = false;
    List<ShopCategory> categoryOptions = [];
    int? selectedCategoryId = _shop.categoryId;
    bool isLoadingCategories = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoadingCategories && categoryOptions.isEmpty) {
              Future.microtask(() async {
                final categories = await CategoryService.getShopCategories();
                if (!mounted) return;
                setModalState(() {
                  categoryOptions = categories;
                  isLoadingCategories = false;
                  if (selectedCategoryId == null && categories.isNotEmpty) {
                    selectedCategoryId = categories.first.categoryId;
                  }
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'แก้ไขโปรไฟล์ร้านค้า',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Shop Image / Avatar Picker
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              try {
                                final result = await FilePicker.platform
                                    .pickFiles(
                                      type: FileType.image,
                                      allowMultiple: false,
                                      withData: true,
                                    );
                                if (result != null && result.files.isNotEmpty) {
                                  final file = result.files.first;
                                  if (file.bytes != null) {
                                    setModalState(() {
                                      pickedBytes = file.bytes;
                                      pickedName = file.name;
                                    });
                                  }
                                }
                              } catch (e) {
                                debugPrint('Error picking shop image: $e');
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFEFF6FF),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: pickedBytes != null
                                        ? Image.memory(
                                            pickedBytes!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : (_shop.shopImage != null &&
                                                  _shop.shopImage!.isNotEmpty
                                              ? Image.network(
                                                  ApiService.getImagePath(
                                                    _shop.shopImage,
                                                  ),
                                                  key: ValueKey(
                                                    '${_shop.shopImage}_${_shop.shopId}',
                                                  ),
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
                                                        Icons.storefront,
                                                        size: 48,
                                                        color: Color(
                                                          0xFF2563EB,
                                                        ),
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.storefront,
                                                  size: 48,
                                                  color: Color(0xFF2563EB),
                                                )),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                final result = await FilePicker.platform
                                    .pickFiles(
                                      type: FileType.image,
                                      allowMultiple: false,
                                      withData: true,
                                    );
                                if (result != null && result.files.isNotEmpty) {
                                  final file = result.files.first;
                                  if (file.bytes != null) {
                                    setModalState(() {
                                      pickedBytes = file.bytes;
                                      pickedName = file.name;
                                    });
                                  }
                                }
                              } catch (e) {
                                debugPrint('Error picking shop image: $e');
                              }
                            },
                            icon: const Icon(
                              Icons.upload_file,
                              size: 18,
                              color: Color(0xFF2563EB),
                            ),
                            label: Text(
                              pickedName != null
                                  ? 'เลือกภาพ: $pickedName'
                                  : 'อัปโหลดรูปร้านค้าใหม่',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Shop Name Input
                    Text(
                      'ชื่อร้านค้า',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.outfit(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'ระบุชื่อร้านค้า',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shop Description Input
                    Text(
                      'รายละเอียด / สโลแกนร้านค้า',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      style: GoogleFonts.outfit(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'ระบุรายละเอียดหรือจุดเด่นของร้านค้า',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shop Phone Input
                    Text(
                      'เบอร์โทรศัพท์ติดต่อร้านค้า',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.outfit(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'ระบุเบอร์โทรศัพท์',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'หมวดหมู่ร้านค้า',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isLoadingCategories)
                      const SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      )
                    else if (categoryOptions.isEmpty)
                      Text(
                        'ไม่พบหมวดหมู่ร้านค้าในระบบ',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categoryOptions.map((category) {
                            final isSelected =
                                selectedCategoryId == category.categoryId;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedCategoryId = category.categoryId;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  category.categoryName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'กรุณาระบุชื่อร้านค้า',
                                        style: GoogleFonts.outfit(),
                                      ),
                                      backgroundColor: const Color(0xFFDC2626),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                final updatedShop =
                                    await ShopService.updateShop(
                                      shopId: _shop.shopId!,
                                      shopName: name,
                                      categoryId: selectedCategoryId,
                                      description: descController.text.trim(),
                                      shopPhone: phoneController.text.trim(),
                                      fileName: pickedName ?? _shop.shopImage,
                                      fileBytes: pickedBytes,
                                    );

                                setModalState(() => isSaving = false);

                                if (updatedShop != null) {
                                  setState(() {
                                    _shop = updatedShop;
                                  });
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    AppDialog.showSuccess(
                                      context,
                                      title: 'บันทึกสำเร็จ',
                                      message:
                                          'อัปเดตข้อมูลโปรไฟล์ร้านค้าเรียบร้อยแล้ว!',
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'ไม่สามารถอัปเดตร้านค้าได้ กรุณาลองใหม่อีกครั้ง',
                                          style: GoogleFonts.outfit(),
                                        ),
                                        backgroundColor: const Color(
                                          0xFFDC2626,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'บันทึกการเปลี่ยนแปลง',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
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
                            ClipOval(
                              child: Container(
                                width: 72,
                                height: 72,
                                color: const Color(0xFFEFF6FF),
                                child:
                                    _shop.shopImage != null &&
                                        _shop.shopImage!.isNotEmpty
                                    ? Image.network(
                                        ApiService.getImagePath(
                                          _shop.shopImage,
                                        ),
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.storefront,
                                                  color: Color(0xFF2563EB),
                                                  size: 32,
                                                ),
                                      )
                                    : const Icon(
                                        Icons.storefront,
                                        color: Color(0xFF2563EB),
                                        size: 32,
                                      ),
                              ),
                            ),
                            const Spacer(),
                            // Edit Profile button
                            OutlinedButton.icon(
                              onPressed: _showEditShopProfileDialog,
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: Text(
                                'แก้ไขโปรไฟล์',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(
                                  color: Color(0xFFBFDBFE),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
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
                              const Icon(
                                Icons.favorite,
                                color: Color(0xFF2563EB),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ผู้ติดตาม',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_shop.followerCount} คน',
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
                      itemCount:
                          _categories.length + 1, // +1 for the "+" button
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
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFF2563EB),
                                size: 20,
                              ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DEBUG: show loaded item count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'DEBUG: loaded ${_items.length} items',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),

                  // Items List
                  ..._filteredItems.map((item) => _buildItemCard(item)),

                  if (_filteredItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.restaurant_menu,
                              size: 48,
                              color: Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ยังไม่มีรายการอาหารในหมวดนี้',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF94A3B8),
                              ),
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
            selectedIndex: 3,
            onDestinationSelected: (index) {
              Navigator.pop(context, index);
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
                label: 'แผนที่',
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
                label: 'เมนู',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final isAvailable = _itemAvailability[item.itemId ?? 0] ?? true;

    return GestureDetector(
      onTap: () => _showItemDetailSheet(item),
      child: Container(
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
                ApiService.getImagePath(item.itemImage),
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
                        child: const Icon(
                          Icons.fastfood,
                          color: Color(0xFF2563EB),
                        ),
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

            // Edit button + Toggle + Label
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF2563EB)),
                  onPressed: () => _showEditItemDialog(item),
                  tooltip: 'แก้ไขเมนู',
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (val) {
                    setState(() {
                      _itemAvailability[item.itemId ?? 0] = val;
                    });
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF2563EB),
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  inactiveThumbColor: const Color(0xFF94A3B8),
                ),
                Text(
                  isAvailable ? 'เปิดขาย' : 'ปิดขาย',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAvailable
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(Item item) {
    final priceCtrl = TextEditingController(
      text: item.price.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('แก้ไขเมนู'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'ราคา (บาท)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final raw = priceCtrl.text.trim();
                          final parsed = double.tryParse(
                            raw.replaceAll(',', ''),
                          );
                          if (parsed == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('กรุณากรอกราคาที่ถูกต้อง'),
                              ),
                            );
                            return;
                          }
                          setState(() => isSaving = true);
                          final updated = await ItemService.updateItem(
                            item.itemId ?? 0,
                            {'price': parsed.toStringAsFixed(2)},
                          );
                          setState(() => isSaving = false);
                          if (updated != null) {
                            // replace local item
                            if (mounted) {
                              setState(() {
                                final idx = _items.indexWhere(
                                  (i) => i.itemId == updated.itemId,
                                );
                                if (idx != -1) {
                                  _items[idx] = updated;
                                  _itemAvailability[updated.itemId ?? 0] =
                                      updated.isAvailable;
                                }
                              });
                            }
                            Navigator.pop(context);
                            if (context.mounted) {
                              AppDialog.showSuccess(
                                context,
                                title: 'สำเร็จ',
                                message: 'อัปเดตราคาเรียบร้อย',
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'ไม่สามารถอัปเดตเมนูได้ กรุณาลองใหม่',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showItemDetailSheet(Item item) {
    final images = item.allImages;
    final controller = PageController();
    int pageIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 56,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 260,
                            child: PageView.builder(
                              controller: controller,
                              itemCount: images.isNotEmpty ? images.length : 1,
                              onPageChanged: (p) =>
                                  setState(() => pageIndex = p),
                              itemBuilder: (context, index) {
                                final img = images.isNotEmpty
                                    ? images[index]
                                    : item.itemImage;
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    ApiService.getImagePath(img),
                                    width: double.infinity,
                                    height: 260,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.fastfood,
                                                  size: 48,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (images.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (i) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: pageIndex == i ? 14 : 8,
                                  height: pageIndex == i ? 14 : 8,
                                  decoration: BoxDecoration(
                                    color: pageIndex == i
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFFCBD5E1),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.itemName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.isAvailable
                                            ? const Color(0xFFE0F2FE)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: item.isAvailable
                                              ? const Color(0xFF38BDF8)
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Text(
                                        item.isAvailable ? 'เปิดขาย' : 'ปิดขาย',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: item.isAvailable
                                              ? const Color(0xFF0369A1)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.description ?? 'ไม่มีคำอธิบาย',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      'ราคา',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '฿${item.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2563EB),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditItemDialog(item);
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('แก้ไข'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('ยืนยันการลบ'),
                                    content: const Text(
                                      'คุณต้องการลบเมนูนี้หรือไม่?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('ยกเลิก'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('ลบ'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  final success = await ItemService.deleteItem(
                                    item.itemId ?? 0,
                                  );
                                  if (success) {
                                    if (mounted) {
                                      setState(() {
                                        _items.removeWhere(
                                          (i) => i.itemId == item.itemId,
                                        );
                                      });
                                    }
                                    Navigator.pop(context);
                                    if (context.mounted)
                                      AppDialog.showSuccess(
                                        context,
                                        title: 'ลบแล้ว',
                                        message: 'เมนูถูกลบเรียบร้อย',
                                      );
                                  } else {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('ไม่สามารถลบได้'),
                                        ),
                                      );
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              label: const Text(
                                'ลบ',
                                style: TextStyle(color: Color(0xFFDC2626)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFDC2626),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
