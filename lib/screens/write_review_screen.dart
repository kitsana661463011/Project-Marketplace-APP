import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/shop.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  Shop _shop = Shop(shopName: 'ร้านค้า');
  double _rating = 0; // 0 means unrated
  final _commentController = TextEditingController();
  final List<Uint8List> _reviewImageBytes = [];
  final List<String> _reviewImageNames = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Shop) {
      _shop = args;
    } else if (args is Map && args['shop'] is Shop) {
      _shop = args['shop'] as Shop;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickReviewImages() async {
    if (_reviewImageBytes.length >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'คุณสามารถเพิ่มได้สูงสุด 3 รูปเท่านั้น',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final availableSlots = 3 - _reviewImageBytes.length;
        final files = result.files
            .where((file) => file.bytes != null)
            .take(availableSlots)
            .toList();

        if (files.isEmpty) return;

        setState(() {
          for (final file in files) {
            // ป้องกันรูปซ้ำ: ตรวจสอบชื่อไฟล์ที่มีอยู่แล้ว
            if (!_reviewImageNames.contains(file.name)) {
              _reviewImageBytes.add(file.bytes!);
              _reviewImageNames.add(file.name);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถเลือกภาพรีวิวได้: $e',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _removeReviewImage(int index) {
    setState(() {
      _reviewImageBytes.removeAt(index);
      _reviewImageNames.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null || currentUser.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเข้าสู่ระบบก่อนรีวิวร้านค้า',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Show a loader dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
      ),
    );

    final imageFiles = _reviewImageBytes
        .asMap()
        .entries
        .map(
          (entry) => {
            'key': 'images[]',
            'bytes': entry.value,
            'fileName': _reviewImageNames[entry.key],
          },
        )
        .toList();

    final result = await ReviewService.createReview(
      userId: currentUser.userId!,
      shopId: _shop.shopId ?? 0,
      rating: _rating,
      comment: _commentController.text.trim(),
      reviewImages: imageFiles.isNotEmpty ? imageFiles : null,
    );

    if (mounted) navigator.pop(); // Pop loading dialog

    if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'บันทึกการรีวิวของคุณเรียบร้อยแล้ว!',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true); // Return success to reload review list
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาดในการบันทึกรีวิว กรุณาลองใหม่อีกครั้ง',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatRating(double rating) {
    return rating % 1 == 0
        ? rating.toInt().toString()
        : rating.toStringAsFixed(1);
  }

  String _getRatingLabel(double rating) {
    if (rating >= 5.0) return 'ยอดเยี่ยมมากที่สุด (${_formatRating(rating)}/5)';
    if (rating >= 4.5) return 'ดีเยี่ยม (${_formatRating(rating)}/5)';
    if (rating >= 4.0) return 'ดีมาก (${_formatRating(rating)}/5)';
    if (rating >= 3.5) return 'ค่อนข้างดี (${_formatRating(rating)}/5)';
    if (rating >= 3.0) return 'ปานกลาง (${_formatRating(rating)}/5)';
    if (rating >= 2.5) return 'พอใช้ (${_formatRating(rating)}/5)';
    if (rating >= 2.0) return 'ควรปรับปรุง (${_formatRating(rating)}/5)';
    if (rating >= 1.5) return 'ไม่ประทับใจ (${_formatRating(rating)}/5)';
    if (rating >= 1.0) return 'แย่ (${_formatRating(rating)}/5)';
    if (rating >= 0.5) return 'แย่มาก (${_formatRating(rating)}/5)';
    return 'แตะหรือลากเพื่อเลือกคะแนน (เลือกครึ่งดาวได้)';
  }

  void _validateAndConfirm() {
    if (_rating <= 0) {
      // Show warning if user has not selected a rating yet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเลือกคะแนนความพึงพอใจอย่างน้อย 0.5 ดาวค่ะ',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Show confirmation popup dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'ยืนยันการส่งรีวิว',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'คุณต้องการส่งรีวิวจำนวน ${_formatRating(_rating)} ดาว ให้กับร้าน ${_shop.shopName} ใช่หรือไม่?',
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
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                _submitReview();
              },
              child: Text(
                'ส่งรีวิว',
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
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Header Info Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 52,
                        child:
                            _shop.shopImage != null &&
                                _shop.shopImage!.isNotEmpty
                            ? (_shop.shopImage!.startsWith('http')
                                  ? Image.network(
                                      _shop.shopImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      ApiService.getImagePath(_shop.shopImage),
                                      fit: BoxFit.cover,
                                    ))
                            : Container(
                                color: const Color(0xFFE2E8F0),
                                child: const Icon(
                                  Icons.storefront,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${_shop.shopName} (${_shop.shopName == 'สยาม ดีไลท์' ? 'Siam Delight' : 'Shop Detail'})',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Rating Stars Box
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'คะแนนความพึงพอใจ',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (_rating > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
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
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatRating(_rating)} / 5.0',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) {
                            final rowWidth = 5 * 52.0;
                            final startX = (constraints.maxWidth - rowWidth) / 2;
                            final relativeX = (details.localPosition.dx - startX)
                                .clamp(0.0, rowWidth);
                            final raw = (relativeX / rowWidth) * 5.0;
                            double snapped = (raw * 2).round() / 2.0;
                            if (snapped < 0.5) snapped = 0.5;
                            if (snapped > 5.0) snapped = 5.0;
                            if (_rating != snapped) {
                              setState(() {
                                _rating = snapped;
                              });
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => _buildSingleStar(index),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getRatingLabel(_rating),
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        color: _rating == 0
                            ? const Color(0xFF64748B)
                            : const Color(0xFF1E293B),
                        fontWeight:
                            _rating == 0 ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'แตะฝั่งซ้ายเพื่อเลือกครึ่งดาว (.5) หรือฝั่งขวาเพื่อเลือกเต็มดาว',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Photo Upload Row (Compact 76x76 size)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'เพิ่มรูปภาพประกอบ ( ไม่บังคับ )',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${_reviewImageBytes.length}/3 รูป',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _reviewImageBytes.isNotEmpty
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Render uploaded image thumbnails
                    for (int i = 0; i < _reviewImageBytes.length; i++) ...[
                      Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                _reviewImageBytes[i],
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => _removeReviewImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xCC000000),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Upload button (if < 3 images)
                    if (_reviewImageBytes.length < 3)
                      GestureDetector(
                        onTap: _pickReviewImages,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                color: Color(0xFF1E88E5),
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '+ เพิ่มรูป',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E88E5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Info Tip Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF0284C7),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'รีวิวที่มีรูปภาพช่วยให้ผู้อื่นตัดสินใจได้ง่ายขึ้น',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF0369A1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Comment Text Field
              Text(
                'ความคิดเห็นของคุณ',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 5,
                  minLines: 3,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'เขียนความรู้สึกของคุณที่นี่... (อย่างน้อย 10 ตัวอักษร)',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: _validateAndConfirm,
                  child: Text(
                    'ส่งรีวิวเลย',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleStar(int index) {
    final double starValue = index + 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildStarIcon(index),
            // Left Half Tap Target (starValue - 0.5)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 22,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _rating = starValue - 0.5;
                  });
                },
              ),
            ),
            // Right Half Tap Target (starValue)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 22,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _rating = starValue;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarIcon(int index) {
    final double starValue = index + 1.0;
    if (_rating >= starValue) {
      return const Icon(
        Icons.star_rounded,
        color: Color(0xFFF59E0B),
        size: 42,
      );
    } else if (_rating >= starValue - 0.5) {
      return Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.star_rounded,
            color: Color(0xFFE2E8F0),
            size: 42,
          ),
          ClipRect(
            clipper: _HalfStarClipper(),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFF59E0B),
              size: 42,
            ),
          ),
        ],
      );
    } else {
      return const Icon(
        Icons.star_rounded,
        color: Color(0xFFE2E8F0),
        size: 42,
      );
    }
  }
}

class _HalfStarClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

