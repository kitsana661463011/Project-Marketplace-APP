import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProblemDetailScreen extends StatelessWidget {
  const ProblemDetailScreen({super.key});

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
    final report =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final String descRaw = report['description'] ?? '';
    final String cleanDesc = _cleanDescription(descRaw);
    final String categoryWithEmoji = _getCategoryEmojiAndName(descRaw);
    final String dateStr = report['report_date'] != null
        ? report['report_date'].toString().split(' ')[0]
        : '-';
    final String? imageName = report['image'];
    final String? adminComment =
        report['admin_comment'] ?? report['admin_note'];
    final String stallNumber = report['stall_number'] ?? 'ทั่วไป';
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
          'ประวัติการแจ้งปัญหา',
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
              // 1. Image Section (Formatted in a premium frame)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Column(
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
                                'http://10.0.2.2:8000/storage/custom_images/$imageName',
                                width: double.infinity,
                                height: 230,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to local asset image
                                  return Image.asset(
                                    'assets/$imageName',
                                    width: double.infinity,
                                    height: 230,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Secondary network fallback (placeholder image)
                                      return Container(
                                        width: double.infinity,
                                        height: 230,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFE2E8F0),
                                              Color(0xFFCBD5E1),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image_outlined,
                                                size: 48,
                                                color: Color(0xFF64748B),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'ไม่สามารถโหลดภาพประกอบจริงได้',
                                                style: TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
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
                        fontSize: 12.5,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Info Cards (Grid of category type & stall place)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
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
                          children: [
                            Text(
                              'ประเภทปัญหา',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              categoryWithEmoji,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Stall Marker Box Card
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
                          children: [
                            Text(
                              'สถานที่',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  color: Color(0xFF2563EB),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  stallNumber,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  reporterName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(ผู้ค้าในตลาด)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
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

              // 4. Problem Description Card (Styled quote container)
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
                            'รายละเอียดที่แจ้งซ่อม',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Icon(
                            Icons.rate_review_outlined,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
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
                            fontSize: 14,
                            color: const Color(0xFF334155),
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFF94A3B8),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'วันทีแจ้ง: $dateStr | เวลา: $timeStr',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
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
}
