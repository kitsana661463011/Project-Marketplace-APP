import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/shop_category.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/shop_service.dart';

import '../services/api_service.dart';

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedCategoryId;
  Uint8List? _pickedShopImageBytes;
  String? _pickedShopImageName;
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;
  bool _isLoadingTags = true;

  List<ShopCategory> _categories = [];
  List<String> _availableTags = [];
  final List<String> _selectedTags = [];
  final _tagSearchController = TextEditingController();
  String _tagSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final response = await ApiService.get('/v1/user-interests');
      if (response['status'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        final List<String> tags = [];
        for (var item in data) {
          if (item is Map && item.containsKey('interest_name')) {
            tags.add(item['interest_name'].toString());
          }
        }
        if (mounted) {
          setState(() {
            _availableTags = tags;
            _isLoadingTags = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _availableTags = [
          'อาหาร',
          'เครื่องดื่ม',
          'ขนม/ของหวาน',
          'เสื้อผ้า',
          'เครื่องประดับ',
          'เครื่องสำอาง',
          'ของใช้ในบ้าน',
          'ผักผลไม้',
          'เนื้อสด',
          'ต้นไม้',
          'ของสะสม',
          'งานแฮนด์เมด',
        ];
        _isLoadingTags = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    final categories = await CategoryService.getShopCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _selectedCategoryId = categories.isNotEmpty
          ? categories.first.categoryId
          : null;
      _isLoadingCategories = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickShopImageFromFilePicker() async {
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
            _pickedShopImageBytes = file.bytes;
            _pickedShopImageName = file.name;
          });
        }
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

  Future<void> _handleSubmit(String stallNum, int? stallId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null || currentUser.userId == null) {
      return;
    }

    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาระบุชื่อร้านค้าของคุณก่อนค่ะ',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
      ),
    );

    // Create the shop using ShopService
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเลือกหมวดหมู่ร้านค้าก่อนทำการสร้างค่ะ',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final result = await ShopService.createShop(
      shopName: name,
      categoryId: _selectedCategoryId!,
      description: _descriptionController.text.trim(),
      shopPhone: currentUser.phone ?? '0812345678',
      userId: currentUser.userId!,
      fileName: _pickedShopImageName ?? 'shop1.png',
      fileBytes: _pickedShopImageBytes,
      tags: _selectedTags.toList(),
    );

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    setState(() => _isSubmitting = false);

    if (result != null) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF10B981),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'สร้างร้านค้าสำเร็จ',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ระบบทำการเปิดร้านค้าและสร้างโปรไฟล์ให้แก่คุณเรียบร้อยแล้ว เริ่มจัดการอาหารของคุณได้เลยค่ะ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, true); // Return back to shop list
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'ตกลง',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถสร้างร้านค้าได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String stallNum = args['stall_number'] ?? 'A3';
    final int? stallId = args['stall_id'];

    return Scaffold(
      backgroundColor: Colors.white,
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
          'สร้างร้านค้าใหม่',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFF1F5F9), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Avatar Uploader
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickShopImageFromFilePicker,
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFFFFB74D,
                                ).withValues(alpha: 0.2),
                                border: Border.all(
                                  color: const Color(0xFFFFB74D),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: _pickedShopImageBytes != null
                                    ? Image.memory(
                                        _pickedShopImageBytes!,
                                        fit: BoxFit.cover,
                                        width: 110,
                                        height: 110,
                                      )
                                    : const Icon(
                                        Icons.storefront,
                                        size: 52,
                                        color: Color(0xFFFFB74D),
                                      ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickShopImageFromFilePicker,
                        icon: const Icon(
                          Icons.upload_file,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        label: Text(
                          _pickedShopImageName != null
                              ? 'เลือกแล้ว: $_pickedShopImageName'
                              : 'คลิกเพื่อเลือกรูปภาพร้านค้าจากอุปกรณ์',
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
                const SizedBox(height: 28),

                // 2. ชื่อร้านค้า Input
                Row(
                  children: [
                    Text(
                      'ชื่อร้านค้า',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'ระบุชื่อร้านค้าของคุณ',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    suffixIcon: const Icon(
                      Icons.storefront,
                      color: Color(0xFF94A3B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. หมวดหมู่ร้านค้า Selector Tags Row
                Text(
                  'หมวดหมู่ร้านค้า',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingCategories)
                  const SizedBox(
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  )
                else
                  Builder(
                    builder: (context) {
                      final selectedCat = _categories
                          .cast<ShopCategory?>()
                          .firstWhere(
                            (c) => c?.categoryId == _selectedCategoryId,
                            orElse: () => _categories.isNotEmpty
                                ? _categories.first
                                : null,
                          );

                      return InkWell(
                        onTap: _categories.isEmpty
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (ctx) {
                                    String catSearch = '';
                                    return StatefulBuilder(
                                      builder: (ctx, setCatState) {
                                        final filteredCats = _categories
                                            .where(
                                              (c) => c.categoryName
                                                  .toLowerCase()
                                                  .contains(
                                                    catSearch
                                                        .toLowerCase()
                                                        .trim(),
                                                  ),
                                            )
                                            .toList();

                                        return SafeArea(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 18,
                                            ),
                                            constraints: BoxConstraints(
                                              maxHeight:
                                                  MediaQuery.of(
                                                    ctx,
                                                  ).size.height *
                                                  0.7,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'เลือกหมวดหมู่ร้านค้า',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: const Color(
                                                          0xFF0F172A,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                      ),
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            ctx,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF1F5F9,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  child: TextField(
                                                    onChanged:
                                                        (val) => setCatState(
                                                          () =>
                                                              catSearch = val,
                                                        ),
                                                    decoration:
                                                        const InputDecoration(
                                                          icon: Icon(
                                                            Icons.search,
                                                            color: Color(
                                                              0xFF64748B,
                                                            ),
                                                            size: 20,
                                                          ),
                                                          hintText:
                                                              'ค้นหาหมวดหมู่...',
                                                          border:
                                                              InputBorder.none,
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                vertical: 10,
                                                              ),
                                                        ),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                const Divider(
                                                  height: 1,
                                                  color: Color(0xFFE2E8F0),
                                                ),
                                                const SizedBox(height: 8),
                                                Expanded(
                                                  child:
                                                      filteredCats.isEmpty
                                                          ? Center(
                                                            child: Text(
                                                              'ไม่พบหมวดหมู่ที่ค้นหา',
                                                              style: GoogleFonts.outfit(
                                                                color:
                                                                    const Color(
                                                                      0xFF94A3B8,
                                                                    ),
                                                              ),
                                                            ),
                                                          )
                                                          : ListView.separated(
                                                            itemCount:
                                                                filteredCats
                                                                    .length,
                                                            separatorBuilder:
                                                                (
                                                                  _,
                                                                  index,
                                                                ) => const Divider(
                                                                  height: 1,
                                                                  color: Color(
                                                                    0xFFF1F5F9,
                                                                  ),
                                                                ),
                                                            itemBuilder: (
                                                              ctx,
                                                              index,
                                                            ) {
                                                              final cat =
                                                                  filteredCats[index];
                                                              final isSelected =
                                                                  cat.categoryId ==
                                                                  _selectedCategoryId;
                                                              return ListTile(
                                                                contentPadding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          2,
                                                                    ),
                                                                leading:
                                                                    Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            isSelected
                                                                                ? const Color(0xFF2563EB)
                                                                                : const Color(0xFFEFF6FF),
                                                                        borderRadius:
                                                                            BorderRadius.circular(10),
                                                                      ),
                                                                      child:
                                                                          Icon(
                                                                            Icons
                                                                                .storefront_rounded,
                                                                            size:
                                                                                18,
                                                                            color:
                                                                                isSelected
                                                                                    ? Colors.white
                                                                                    : const Color(0xFF2563EB),
                                                                          ),
                                                                    ),
                                                                title: Text(
                                                                  cat.categoryName,
                                                                  style: GoogleFonts.outfit(
                                                                    fontSize:
                                                                        14.5,
                                                                    fontWeight:
                                                                        isSelected
                                                                            ? FontWeight.bold
                                                                            : FontWeight.w500,
                                                                    color:
                                                                        isSelected
                                                                            ? const Color(0xFF2563EB)
                                                                            : const Color(0xFF0F172A),
                                                                  ),
                                                                ),
                                                                trailing:
                                                                    isSelected
                                                                        ? const Icon(
                                                                          Icons
                                                                              .check_circle_rounded,
                                                                          color: Color(
                                                                            0xFF2563EB,
                                                                          ),
                                                                          size:
                                                                              22,
                                                                        )
                                                                        : null,
                                                                onTap: () {
                                                                  setState(() {
                                                                    _selectedCategoryId =
                                                                        cat.categoryId;
                                                                  });
                                                                  Navigator.pop(
                                                                    ctx,
                                                                  );
                                                                },
                                                              );
                                                            },
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
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.category_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedCat?.categoryName ??
                                      'กรุณาเลือกหมวดหมู่ร้านค้า',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: selectedCat != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selectedCat != null
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF64748B),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 28),

                // 3.1 แท็กความสนใจของร้านค้า (Shop Tags)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'แท็กความสนใจของร้านค้า',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedTags.length == 5
                            ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                            : const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'เลือกแล้ว ${_selectedTags.length}/5',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedTags.length == 5
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // คำเตือนเกี่ยวกับแท็กให้เข้ากับประเภทร้าน
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'คำเตือน: โปรดเลือกแท็กที่สอดคล้องกับประเภทร้านค้าและสินค้าจริงของคุณ เพื่อให้ระบบนำส่งร้านของคุณไปยังกลุ่มลูกค้าที่สนใจได้อย่างถูกต้องและมีประสิทธิภาพ',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 10),

                // คำแนะนำการเลือกลำดับ
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
                        size: 15,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'แตะเพื่อเลือกตามลำดับความสำคัญ (1 = สำคัญมากที่สุด)',
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
                const SizedBox(height: 10),

                // Searchable Available Tags Container Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Input Header
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            controller: _tagSearchController,
                            onChanged: (val) {
                              setState(() {
                                _tagSearchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              icon: const Icon(
                                Icons.search,
                                color: Color(0xFF94A3B8),
                                size: 18,
                              ),
                              hintText:
                                  'ค้นหาแท็ก (เช่น อาหาร, เครื่องดื่ม, เสื้อผ้า)...',
                              hintStyle: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              suffixIcon: _tagSearchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _tagSearchController.clear();
                                        setState(() => _tagSearchQuery = '');
                                      },
                                      child: const Icon(
                                        Icons.clear,
                                        size: 16,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    )
                                  : null,
                            ),
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Scrollable Tag Box
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: _isLoadingTags
                            ? const SizedBox(
                                height: 60,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2563EB),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Builder(
                                builder: (_) {
                                  final filteredTags = _availableTags
                                      .where(
                                        (t) => t.toLowerCase().contains(
                                          _tagSearchQuery.toLowerCase().trim(),
                                        ),
                                      )
                                      .toList();

                                  if (filteredTags.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Center(
                                        child: Text(
                                          'ไม่พบแท็ก "$_tagSearchQuery"',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12.5,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.all(12),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 10,
                                      children: filteredTags.map((tag) {
                                        final isSelected = _selectedTags
                                            .contains(tag);
                                        final int orderIndex = isSelected
                                            ? _selectedTags.indexOf(tag) + 1
                                            : 0;

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedTags.remove(tag);
                                              } else {
                                                if (_selectedTags.length >= 5) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'สามารถเลือกแท็กได้สูงสุด 5 แท็กค่ะ',
                                                        style:
                                                            GoogleFonts.outfit(),
                                                      ),
                                                      backgroundColor:
                                                          Colors.orange,
                                                    ),
                                                  );
                                                  return;
                                                }
                                                _selectedTags.add(tag);
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFFEFF6FF)
                                                  : const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(18),
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
                                                        ).withValues(
                                                          alpha: 0.12,
                                                        ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
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
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 6,
                                                        ),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFF2563EB,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      '$orderIndex',
                                                      style: GoogleFonts.outfit(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        height: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                Text(
                                                  '#$tag',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12.5,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF1E40AF,
                                                          )
                                                        : const Color(
                                                            0xFF475569,
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 4. แผงที่เลือก Panel
                Text(
                  'แผงที่เลือก',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFEFF6FF,
                    ), // Light blue tint matching Screenshot 2
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'แผงที่เลือก: $stallNum',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 5. คำอธิบายร้านค้า Text Input
                Text(
                  'คำอธิบายร้านค้า (เพิ่มเติม)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'ระบุข้อมูลอธิบายรายละเอียดจุดเด่นของร้านค้าคุณ...',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13.5,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 36),

                // 6. Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleSubmit(stallNum, stallId),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'ยืนยันการสร้างร้านค้า',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
