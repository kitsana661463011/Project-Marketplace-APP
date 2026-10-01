import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shop.dart';
import '../services/api_service.dart';
import '../services/shop_service.dart';

class ProblemDetailScreen extends StatelessWidget {
  const ProblemDetailScreen({super.key});

  Future<void> _openShopReview(
    BuildContext context, {
    int? shopId,
    required String shopName,
    int? reviewId,
    required String commentText,
  }) async {
    int? targetShopId = shopId;

    if (targetShopId == null && shopName.isNotEmpty) {
      try {
        final shops = await ShopService.getShops();
        final found = shops.firstWhere(
          (s) => s.shopName.toLowerCase().trim() == shopName.toLowerCase().trim(),
          orElse: () => Shop(shopName: shopName),
        );
        targetShopId = found.shopId;
      } catch (_) {}
    }

    if (!context.mounted) return;

    if (targetShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shopName.isNotEmpty
                ? 'ไม่พบข้อมูลร้านค้า $shopName ในระบบ'
                : 'ไม่พบข้อมูลร้านค้าของรีวิวนี้',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/shop_reviews',
      arguments: {
        'shop': Shop(
          shopId: targetShopId,
          shopName: shopName,
        ),
        'tabIndex': 0,
        'highlightReviewId': reviewId,
        'highlightCommentText': commentText,
      },
    );
  }

  String _getCategoryEmojiAndName(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('ไฟฟ้า') || desc.contains('electricity')) {
      return '⚡ ไฟฟ้า';
    } else if (desc.contains('ประปา') ||
        desc.contains('plumbing') ||
        desc.contains('น้ำ')) {
      return '💧 ประปา';
    } else if (desc.contains('โครงสร้าง') || desc.contains('structure')) {
      return '🏢 โครงสร้าง';
    } else if (desc.contains('ความสะอาด') ||
        desc.contains('cleanliness') ||
        desc.contains('ขยะ')) {
      return '🧹 ความสะอาด';
    }
    return '⚠️ อื่นๆ';
  }

  String _cleanDescription(String description) {
    return description.replaceAll(RegExp(r'\[หมวดหมู่:.*?\]\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs == null || rawArgs is! Map) {
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
            'รายละเอียดการแจ้งปัญหา',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'ไม่พบข้อมูล หรือหน้ารายการถูกรีเฟรช',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('ย้อนกลับ'),
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
      );
    }

    final Map<String, dynamic> report = Map<String, dynamic>.from(rawArgs);

    final String descRaw = report['description'] ?? '';
    final String cleanDesc = _cleanDescription(descRaw);
    final bool isReviewReport = report['is_review_report'] == true ||
        report['report_type'] == 'feedback' ||
        descRaw.contains('รายงานความคิดเห็น');

    Map<String, dynamic>? reviewDetails;
    if (report['review_details'] is Map) {
      reviewDetails = Map<String, dynamic>.from(report['review_details']);
    }

    String commentText = reviewDetails?['comment']?.toString() ?? '';
    String shopName = reviewDetails?['shop_name']?.toString() ?? '';
    String reviewerName = reviewDetails?['reviewer_name']?.toString() ?? '';
    double rating = double.tryParse(reviewDetails?['rating']?.toString() ?? '5') ?? 5.0;
    String reportReason = reviewDetails?['report_reason']?.toString() ?? '';
    List<dynamic> reviewImages = reviewDetails?['review_images'] is List ? reviewDetails!['review_images'] : [];
    int? reviewId = int.tryParse(reviewDetails?['review_id']?.toString() ?? '') ??
        int.tryParse(report['review_id']?.toString() ?? '');
    int? shopId = int.tryParse(reviewDetails?['shop_id']?.toString() ?? '') ??
        int.tryParse(report['shop_id']?.toString() ?? '');

    // Fallback parser if review_details is not provided directly
    if (commentText.isEmpty && descRaw.contains('ข้อความ: "')) {
      final match = RegExp(r'\| ข้อความ:\s*"(.*?)"').firstMatch(descRaw);
      if (match != null) {
        commentText = match.group(1) ?? '';
      }
    }
    if (reportReason.isEmpty && descRaw.contains('] ')) {
      final parts = descRaw.split('| ข้อความ:');
      if (parts.isNotEmpty) {
        final reasonPart = parts[0];
        final match = RegExp(r'\[รายงานความคิดเห็น:[^\]]*\]\s*(.*)').firstMatch(reasonPart);
        if (match != null) {
          reportReason = match.group(1)?.trim() ?? '';
        }
      }
    }
    if (shopName.isEmpty && descRaw.contains('[รายงานความคิดเห็น:')) {
      final match = RegExp(r'\[รายงานความคิดเห็น:\s*([^\]]+)\]').firstMatch(descRaw);
      if (match != null) {
        shopName = match.group(1)?.trim() ?? '';
      }
    }

    final String categoryWithEmoji = isReviewReport
        ? '💬 รายงานความคิดเห็น'
        : _getCategoryEmojiAndName(descRaw);
    final String dateStr = report['report_date'] != null
        ? report['report_date'].toString().split(' ')[0]
        : '-';
    final String? imageName = report['image'];
    final String? adminComment =
        report['admin_comment'] ?? report['admin_note'];
    final String stallNumber = report['stall_number'] ?? (shopName.isNotEmpty ? 'ร้าน $shopName' : 'ทั่วไป');
    final String reporterName = report['user_name'] ?? 'นายมั่งมี ศรีสุข';

    String timeStr = '12:00 น.';
    if (report['report_date'] != null) {
      final parts = report['report_date'].toString().split(' ');
      if (parts.length > 1) {
        timeStr = '${parts[1].substring(0, 5)} น.';
      }
    }

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
          isReviewReport ? 'รายละเอียดการรายงาน' : 'ประวัติการแจ้งปัญหา',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Reported Comment Card OR Image Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: isReviewReport
                    ? Column(
                        children: [
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            elevation: 0,
                            child: InkWell(
                              onTap: () => _openShopReview(
                                context,
                                shopId: shopId,
                                shopName: shopName,
                                reviewId: reviewId,
                                commentText: commentText,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.rate_review_rounded,
                                                size: 16,
                                                color: Color(0xFF2563EB),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'ความคิดเห็นที่ถูกรายงาน',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF2563EB),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFF59E0B),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: const Border(
                                          left: BorderSide(
                                            color: Color(0xFF2563EB),
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '"${commentText.isNotEmpty ? commentText : '-'}"',
                                            style: GoogleFonts.outfit(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF0F172A),
                                              height: 1.45,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          if (reviewerName.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.person_outline,
                                                  size: 15,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'ผู้เขียนรีวิว: คุณ$reviewerName',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    color: const Color(0xFF1E293B),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (reviewImages.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 64,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: reviewImages.length,
                                          separatorBuilder: (c, i) => const SizedBox(width: 8),
                                          itemBuilder: (context, i) {
                                            final img = reviewImages[i].toString();
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                ApiService.getImagePath(img),
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, stack) => Container(
                                                  width: 64,
                                                  height: 64,
                                                  color: const Color(0xFFE2E8F0),
                                                  child: const Icon(Icons.broken_image, size: 20, color: Color(0xFF94A3B8)),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.touch_app_outlined,
                                                size: 16,
                                                color: Color(0xFF2563EB),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'แตะเพื่อไปยังความคิดเห็นนี้ในหน้าร้านค้า',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF2563EB),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 12,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'ข้อความรีวิวและความคิดเห็นของผู้ใช้ที่ถูกส่งรายงานมายังระบบ',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: imageName != null && imageName.isNotEmpty
                                  ? Image.network(
                                      ApiService.getImagePath(imageName),
                                      width: double.infinity,
                                      height: 230,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: double.infinity,
                                          height: 200,
                                          color: const Color(0xFFEFF6FF),
                                          child: const Center(
                                            child: Icon(Icons.broken_image, size: 48, color: Color(0xFF94A3B8)),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFEFF6FF),
                                            Color(0xFFDBEAFE),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_not_supported_outlined,
                                              size: 48,
                                              color: Color(0xFF3B82F6),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'ไม่ได้แนบรูปภาพประกอบการแจ้งปัญหา',
                                              style: TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'รูปแนบจากการแจ้งเหตุหลักฐานชำรุด',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),

              // 2. Info Cards (Grid of category type & stall/shop place)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Category Box Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isReviewReport ? 'ประเภทการรายงาน' : 'ประเภทปัญหา',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    isReviewReport
                                        ? Icons.chat_bubble_outline_rounded
                                        : Icons.warning_amber_rounded,
                                    color: const Color(0xFF2563EB),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isReviewReport
                                          ? 'รายงานความคิดเห็น'
                                          : categoryWithEmoji.replaceAll(RegExp(r'^[^\w\s\u0E00-\u0E7F]+\s*'), ''),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Stall / Shop Marker Box Card
                      Expanded(
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: isReviewReport
                                ? () => _openShopReview(
                                      context,
                                      shopId: shopId,
                                      shopName: shopName,
                                      reviewId: reviewId,
                                      commentText: commentText,
                                    )
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isReviewReport ? 'ร้านค้าที่ถูกรีวิว' : 'สถานที่',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: const Color(0xFF1E293B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isReviewReport)
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 14,
                                          color: Color(0xFF2563EB),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        isReviewReport
                                            ? Icons.storefront_outlined
                                            : Icons.place_outlined,
                                        color: const Color(0xFF2563EB),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          stallNumber,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. User Reporter Details Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ผู้แจ้งเรื่อง',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  reporterName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(ผู้ค้าในตลาด)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    color: const Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
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
              ),

              // 4. Problem / Report Description Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isReviewReport ? 'เหตุผลการรายงานความคิดเห็น' : 'รายละเอียดการแจ้งปัญหา',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Icon(
                            isReviewReport ? Icons.report_problem_outlined : Icons.rate_review_outlined,
                            color: const Color(0xFF2563EB),
                            size: 18,
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      if (isReviewReport) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reportReason.isNotEmpty ? reportReason : cleanDesc,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF991B1B),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(left: 14),
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Color(0xFF2563EB),
                                width: 3.5,
                              ),
                            ),
                          ),
                          child: Text(
                            cleanDesc,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              color: const Color(0xFF0F172A),
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFF2563EB),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'วันทีแจ้ง: $dateStr | เวลา: $timeStr',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Admin Comment Response Box
              if (adminComment != null && adminComment.trim().isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'หมายเหตุและบันทึกจากแอดมิน',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          adminComment,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF1E3A8A),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
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
                  Icons.bookmark_border_rounded,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: const Icon(
                  Icons.bookmark_rounded,
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
}
