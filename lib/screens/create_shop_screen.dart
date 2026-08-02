import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/shop_category.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/shop_service.dart';

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

  List<ShopCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
                else if (_categories.isEmpty)
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
                      children: _categories.map((category) {
                        final isSelected =
                            _selectedCategoryId == category.categoryId;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = category.categoryId;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
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
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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
