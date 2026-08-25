import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'shop_reviews_screen.dart'; // To reference ReviewItem
import '../services/review_service.dart';
import '../services/auth_service.dart';

class ReportCommentScreen extends StatefulWidget {
  const ReportCommentScreen({super.key});

  @override
  State<ReportCommentScreen> createState() => _ReportCommentScreenState();
}

class _ReportCommentScreenState extends State<ReportCommentScreen> {
  ReviewItem _review = ReviewItem(
    reviewId: 0,
    userName: 'ผู้ใช้ทั่วไป',
    userAvatar: '',
    rating: 5.0,
    timeAgo: 'เมื่อสักครู่',
    reviewText: '',
  );
  final _reasonController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<String> _reportTags = [
    'ใช้คำหยาบ',
    'บอท',
    'สแปม',
    'จงใจก่อกวน',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ReviewItem) {
      _review = args;
    } else if (args is Map && args['review'] is ReviewItem) {
      _review = args['review'] as ReviewItem;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitReport() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null || currentUser.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนรายงานความคิดเห็น', style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String customReason = _reasonController.text.trim();
    if (customReason.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกเหตุผลรายละเอียดอย่างน้อย 10 ตัวอักษร', style: GoogleFonts.outfit()),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกประเภทการกระทำอย่างน้อย 1 อย่าง', style: GoogleFonts.outfit()),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Show a loading overlay dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5))),
    );

    // Build the final combined report string
    final String tagsString = _selectedTags.join(', ');
    final String fullReportReason = '[$tagsString] $customReason';

    final result = await ReviewService.createReviewReport(
      reviewId: _review.reviewId,
      userId: currentUser.userId!,
      reportReason: fullReportReason,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading indicator
    }

    setState(() => _isSubmitting = false);

    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('รายงานความคิดเห็นเรียบร้อยแล้ว ทางทีมงานจะรีบทำการตรวจสอบค่ะ', style: GoogleFonts.outfit()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Go back and indicate success
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถส่งรายงานได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง', style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
        title: Text(
          'รายงานความคิดเห็น',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
              // Target Review Card Preview (matching design)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: _review.userAvatar.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _review.userAvatar,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person,
                                              color: Color(0xFF94A3B8),
                                              size: 22,
                                            ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Color(0xFF94A3B8),
                                  size: 22,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _review.userName,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _review.timeAgo,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _review.rating % 1 == 0
                                    ? '${_review.rating.toInt()}.0'
                                    : _review.rating.toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (starIndex) {
                                  final starVal = starIndex + 1;
                                  if (starVal <= _review.rating.floor()) {
                                    return const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 15,
                                    );
                                  } else if (starVal - 0.5 <= _review.rating) {
                                    return const Icon(
                                      Icons.star_half_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 15,
                                    );
                                  } else {
                                    return const Icon(
                                      Icons.star_border_rounded,
                                      color: Color(0xFFCBD5E1),
                                      size: 15,
                                    );
                                  }
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _review.reviewText,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Reason Label
              Text(
                'เหตุผล',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              // Reason Text Area
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _reasonController,
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
              const SizedBox(height: 28),

              // Action Label
              Text(
                'การกระทำ',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),

              // Wrapped Select Chips Row (matching the blue design)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _reportTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () => _toggleTag(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check, color: Color(0xFF1E88E5), size: 14),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            tag,
                            style: GoogleFonts.outfit(
                              color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

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
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: Text(
                    'ส่งรายงาน',
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
