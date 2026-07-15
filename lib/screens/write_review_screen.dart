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
  late Shop _shop;
  double _rating = 0; // 0 means unrated
  final _commentController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Shop) {
      _shop = args;
    } else if (args is Map) {
      _shop = args['shop'] as Shop;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null || currentUser.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนรีวิวร้านค้า', style: GoogleFonts.outfit()),
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
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5))),
    );

    final result = await ReviewService.createReview(
      userId: currentUser.userId!,
      shopId: _shop.shopId ?? 0,
      rating: _rating.toInt(),
      comment: _commentController.text.trim(),
    );

    if (mounted) navigator.pop(); // Pop loading dialog

    if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('บันทึกการรีวิวของคุณเรียบร้อยแล้ว!', style: GoogleFonts.outfit()),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true); // Return success to reload review list
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึกรีวิว กรุณาลองใหม่อีกครั้ง', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _validateAndConfirm() {
    if (_rating == 0) {
      // Show warning if user has not selected a rating yet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกคะแนนความพึงพอใจอย่างน้อย 1 ดาวค่ะ', style: GoogleFonts.outfit()),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'ยืนยันการส่งรีวิว',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'คุณต้องการส่งรีวิวจำนวน ${_rating.toInt()} ดาว ให้กับร้าน ${_shop.shopName} ใช่หรือไม่?',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.0,
          ),
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
                        child: _shop.shopImage != null && _shop.shopImage!.isNotEmpty
                            ? (_shop.shopImage!.startsWith('http')
                                ? Image.network(_shop.shopImage!, fit: BoxFit.cover)
                                : Image.network(ApiService.getImagePath(_shop.shopImage), fit: BoxFit.cover))
                            : Container(
                                color: const Color(0xFFE2E8F0),
                                child: const Icon(Icons.storefront, color: Color(0xFF94A3B8)),
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
              Text(
                'คะแนนความพึงพอใจ',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isSelected = starValue <= _rating;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = starValue.toDouble();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              isSelected ? Icons.star : Icons.star,
                              color: isSelected ? Colors.amber : const Color(0xFFE2E8F0),
                              size: 38,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _rating == 0 ? 'แตะเพื่อเลือกคะแนน' : 'แตะเพื่อเลือกคะแนน (${_rating.toInt()}/5)',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Photo Upload Row (Optional - Visual mockups matching the design)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'เพิ่มรูปภาพประกอบ ( ไม่บังคับ )',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'สูงสุด 3 รูป',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Box 1 (Upload Button)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF1E88E5), size: 28),
                            const SizedBox(height: 6),
                            Text(
                              'อัปโหลด',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF1E88E5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Box 2 (Placeholder)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1), size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Box 3 (Placeholder)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1), size: 28),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Info Tip Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 18),
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
                  style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'เขียนความรู้สึกของคุณที่นี่... (อย่างน้อย 10 ตัวอักษร)',
                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
}
