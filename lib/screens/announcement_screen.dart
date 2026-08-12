import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/announcement_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/announcement.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Announcement> _announcements = [];
  Set<String> _readIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final data = await AnnouncementService.getActiveAnnouncements();
      final readIds = await AnnouncementService.getReadAnnouncementIds();
      if (mounted) {
        data.sort((a, b) {
          int priority(String? type) =>
              type == 'urgent' ? 0 : (type == 'activity' ? 1 : 2);
          return priority(
            a.announcementType,
          ).compareTo(priority(b.announcementType));
        });
        setState(() {
          _announcements = data;
          _readIds = readIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _announcements = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showDetailDialog(Announcement item) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'details',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        // Map backend announcementType to visual Badge
        Color badgeBgColor;
        String badgeText;
        IconData badgeIcon;

        if (item.announcementType == 'urgent') {
          badgeBgColor = const Color(0xFFD32F2F);
          badgeText = 'ประกาศด่วน';
          badgeIcon = Icons.error_outline;
        } else if (item.announcementType == 'activity') {
          badgeBgColor = const Color(0xFFFF9800);
          badgeText = 'กิจกรรม';
          badgeIcon = Icons.celebration_outlined;
        } else {
          badgeBgColor = const Color(0xFF1E88E5);
          badgeText = 'ประกาศทั่วไป';
          badgeIcon = Icons.campaign_outlined;
        }

        // Custom details mapping based on whether it is a mock item or db item
        final bool isMock1 =
            item.announcementId == 1 || item.title.contains('น้ำประปา');
        final bool isMock2 =
            item.announcementId == 2 || item.title.contains('ค่าเช่า');
        final bool isMockItem = isMock1 || isMock2;

        final String bodyText = isMock1
            ? 'เรียน ผู้เช่าพื้นที่และผู้ใช้บริการตลาดทุกท่าน,\n\nขอแจ้งกำหนดการปิดปรับปรุงระบบท่อส่งน้ำหลัก เพื่อทำการซ่อมบำรุงและล้างถังเก็บน้ำประจำปีเพื่อความสะอาดและสุขอนามัยที่ดีของผู้ใช้บริการทุกท่าน โดยมีรายละเอียดดังนี้:'
            : (isMock2
                  ? 'เรียน ผู้เช่าพื้นที่แผงค้า A8,\n\nระบบขอส่งหนังสือแจ้งเตือนการต่ออายุสัญญาเช่าและชำระค่าเช่าประจำงวดเดือนกรกฎาคม เพื่อเป็นข้อมูลประกอบการพิจารณาตัดสินใจ และรักษาสิทธิในการค้าขายของท่าน โดยมีรายละเอียดดังนี้:'
                  : (item.description ??
                        'เรียน ผู้เช่าและผู้ใช้บริการตลาดทุกท่าน,\n\nมีประกาศแจ้งข่าวสารจากโครงการตลาด'));

        final String dateText = isMock1
            ? 'วันพุธที่ 19 กุมภาพันธ์ 2569'
            : (isMock2
                  ? 'วันอาทิตย์ที่ 30 มิถุนายน 2569'
                  : (item.publishDate?.split('T')[0] ?? '-'));

        final String timeText = isMock1
            ? '22:00 น. ถึง 04:00 น. ของวันรุ่งขึ้น'
            : (isMock2 ? '09:00 น. ถึง 18:00 น.' : '09:00 น. เป็นต้นไป');

        final String areaText = isMock1
            ? 'โซน (A), โซน (B), และห้องน้ำสาธารณะทุกจุด'
            : (isMock2
                  ? 'แผงค้าเลขที่ A8 (โซนพลาซ่า)'
                  : 'โครงการตลาดนัดทั้งหมด');

        final String bannerUrl = (item.image != null && item.image!.isNotEmpty)
            ? ApiService.getImagePath(item.image)
            : (isMock1
                  ? 'https://images.unsplash.com/photo-1548826873-e8298697a1f6?w=600&auto=format&fit=crop'
                  : 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=600&auto=format&fit=crop');

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E88E5),
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'ประกาศ',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Image
                  AspectRatio(
                    aspectRatio: 1.6,
                    child: Image.network(
                      bannerUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(
                          Icons.image,
                          size: 60,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                badgeText,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Publish Date
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'เผยแพร่เมื่อ: ${item.publishDate?.contains('T') == true ? item.publishDate!.split('T')[0] : (item.publishDate ?? "17 ก.พ. 2569")}',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'หมวดหมู่: $badgeText',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Main Content Body Text
                        Text(
                          bodyText,
                          style: GoogleFonts.outfit(
                            fontSize: 15.5,
                            color: const Color(0xFF334155),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Summary box containing date/time/area
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F8FF),
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                              left: BorderSide(
                                color: Color(0xFF1E88E5),
                                width: 4.0,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('วันที่ดำเนินการ:', dateText),
                              const SizedBox(height: 12),
                              _buildInfoRow('เวลา:', timeText),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'พื้นที่ที่ได้รับผลกระทบ:',
                                areaText,
                                isStacked: true,
                              ),
                              if (!isMockItem && item.userName != null) ...[
                                const SizedBox(height: 12),
                                _buildInfoRow('ผู้ประกาศ:', item.userName!),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String val, {bool isStacked = false}) {
    if (isStacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1E88E5),
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1E88E5),
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            val,
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final bool isVendor = user != null &&
        (user.role == 'seller' || user.role == 'vendor' || user.role == 'admin');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ประกาศ',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: isVendor
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicator: const UnderlineTabIndicator(
                        borderSide:
                            BorderSide(color: Color(0xFF1E88E5), width: 4.0),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                      labelColor: const Color(0xFF1E88E5),
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      tabs: const [
                        Tab(text: 'ทั้งหมด'),
                        Tab(text: 'ประกาศ'),
                        Tab(text: 'ประกาศด่วน'),
                        Tab(text: 'กิจกรรม'),
                      ],
                    ),
                    Container(color: const Color(0xFFE2E8F0), height: 1.0),
                  ],
                ),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
              ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
            )
          : isVendor
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnnouncementList(_announcements), // ทั้งหมด
                    _buildAnnouncementList(
                      _announcements
                          .where((a) => a.announcementType == 'general')
                          .toList(),
                    ), // ประกาศ (general)
                    _buildAnnouncementList(
                      _announcements
                          .where((a) => a.announcementType == 'urgent')
                          .toList(),
                    ), // ประกาศด่วน (urgent)
                    _buildAnnouncementList(
                      _announcements
                          .where((a) => a.announcementType == 'activity')
                          .toList(),
                    ), // กิจกรรม (activity)
                  ],
                )
              : _buildAnnouncementList(_announcements),
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
            selectedIndex: 0, // Stay visually on home index or match parent
            onDestinationSelected: (index) {
              // Return to home screen and set selected tab index
              Navigator.pop(context);
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
                label: 'แผนที่ตลาด',
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
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementList(List<Announcement> list) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'ไม่มีรายการประกาศในขณะนี้',
          style: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      separatorBuilder: (context, index) =>
          Container(color: const Color(0xFFF1F5F9), height: 1.0),
      itemBuilder: (context, index) {
        final item = list[index];
        final isUrgent = item.announcementType == 'urgent';
        final isActivity = item.announcementType == 'activity';
        final itemKey = AnnouncementService.getAnnouncementKey(item);
        final isUnread = !_readIds.contains(itemKey);

        // Set list circle icon color based on backend type
        Color circleColor = const Color(0xFFE8EAF6);
        Color iconColor = const Color(0xFF3F51B5);
        if (isUrgent) {
          circleColor = const Color(0xFFFE5757);
          iconColor = Colors.white;
        } else if (isActivity) {
          circleColor = const Color(0xFFFFF3E0);
          iconColor = const Color(0xFFFF9800);
        }

        return InkWell(
          onTap: () async {
            if (isUnread) {
              await AnnouncementService.markAsRead(item);
              if (mounted) {
                setState(() {
                  _readIds.add(itemKey);
                });
              }
            }
            _showDetailDialog(item);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Megaphone Icon with unread badge dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: circleColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.campaign, color: iconColor, size: 26),
                    ),
                    if (isUnread)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (isUnread) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'ใหม่',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: isUnread
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.publishDate?.contains('T') == true
                                ? item.publishDate!.split('T')[0]
                                : (item.publishDate ?? 'เมื่อวาน'),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
