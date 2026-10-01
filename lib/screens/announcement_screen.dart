import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/announcement_service.dart';
import '../services/api_service.dart';
import '../models/announcement.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Announcement> _activeAnnouncements = [];
  List<Announcement> _historyAnnouncements = [];
  bool _showingHistory = false;
  Set<String> _readIds = {};
  bool _isLoading = true;

  List<Announcement> get _announcements =>
      _showingHistory ? _historyAnnouncements : _activeAnnouncements;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
      final active = await AnnouncementService.getActiveAnnouncements();
      final history = await AnnouncementService.getHistoryAnnouncements();
      final readIds = await AnnouncementService.getReadAnnouncementIds();

      if (mounted) {
        int priority(String? type) =>
            type == 'urgent' ? 0 : (type == 'activity' ? 1 : 2);
        active.sort((a, b) =>
            priority(a.announcementType).compareTo(priority(b.announcementType)));
        history.sort((a, b) =>
            priority(a.announcementType).compareTo(priority(b.announcementType)));
        setState(() {
          _activeAnnouncements = active;
          _historyAnnouncements = history;
          _readIds = readIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeAnnouncements = [];
          _historyAnnouncements = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showDetailDialog(Announcement item) async {
    await AnnouncementService.markAsRead(item);
    if (mounted) {
      setState(() {
        _readIds.add(AnnouncementService.getAnnouncementKey(item));
      });
    }

    if (!mounted) return;
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

        final String bodyText = (item.description != null && item.description!.trim().isNotEmpty)
            ? item.description!
            : 'ไม่มีรายละเอียดเพิ่มเติมสำหรับประกาศนี้';

        final String dateText = item.dateRangeText.isNotEmpty
            ? item.dateRangeText
            : (item.publishDate?.split('T')[0] ?? '-');

        final String timeText = item.publishDate != null && item.publishDate!.contains('T')
            ? '${item.publishDate!.split('T')[1].substring(0, 5)} น.'
            : 'ตลอดทั้งวัน';

        final String areaText = 'พื้นที่โครงการตลาด';

        final String bannerUrl = (item.image != null && item.image!.isNotEmpty)
            ? ApiService.getImagePath(item.image)
            : '';

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

                        if (item.isExpired) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECDD3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history_toggle_off, color: Color(0xFFE11D48), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ประกาศนี้สิ้นสุดระยะเวลาแล้ว และถูกย้ายมาแสดงในประวัติ',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFBE123C),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

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

                        // Publish Date & Date Range
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'เผยแพร่เมื่อ: ${item.publishDate?.contains('T') == true ? item.publishDate!.split('T')[0] : (item.publishDate ?? "17 ก.พ. 2569")}',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF64748B),
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.dateRangeText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.date_range_outlined,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ระยะเวลาประกาศ: ${item.dateRangeText}',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF64748B),
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                              if (item.userName != null && item.userName!.isNotEmpty) ...[
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.done_all_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
            tooltip: 'อ่านแล้วทั้งหมด',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await AnnouncementService.markAllAsRead();
              final readIds = await AnnouncementService.getReadAnnouncementIds();

              if (mounted) {
                setState(() {
                  _readIds = readIds;
                });
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('ทำเครื่องหมายอ่านแล้วทั้งหมด', style: GoogleFonts.outfit()),
                    backgroundColor: const Color(0xFF10B981),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: const UnderlineTabIndicator(
                  borderSide:
                      BorderSide(color: Color(0xFF1E88E5), width: 3.5),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
                labelColor: const Color(0xFF1E88E5),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
                unselectedLabelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                ),
                tabs: const [
                  Tab(text: 'ทั้งหมด'),
                  Tab(text: 'ประกาศด่วน'),
                  Tab(text: 'ประกาศทั่วไป'),
                  Tab(text: 'กิจกรรม'),
                ],
              ),
              Container(color: const Color(0xFFE2E8F0), height: 1.0),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
            )
          : Column(
              children: [
                _buildSegmentSwitcher(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAnnouncementList(_announcements), // ทั้งหมด
                      _buildAnnouncementList(
                        _announcements
                            .where((a) => a.announcementType == 'urgent')
                            .toList(),
                      ), // ประกาศด่วน (urgent)
                      _buildAnnouncementList(
                        _announcements
                            .where((a) => a.announcementType == 'general')
                            .toList(),
                      ), // ประกาศทั่วไป (general)
                      _buildAnnouncementList(
                        _announcements
                            .where((a) => a.announcementType == 'activity')
                            .toList(),
                      ), // กิจกรรม (activity)
                    ],
                  ),
                ),
              ],
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
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showingHistory) {
                  setState(() => _showingHistory = false);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !_showingHistory ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_showingHistory
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign_rounded,
                      size: 18,
                      color: !_showingHistory ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ประกาศปัจจุบัน (${_activeAnnouncements.length})',
                        style: GoogleFonts.outfit(
                          fontWeight: !_showingHistory ? FontWeight.bold : FontWeight.w500,
                          color: !_showingHistory ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_showingHistory) {
                  setState(() => _showingHistory = true);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _showingHistory ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _showingHistory
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: _showingHistory ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ประวัติประกาศ (${_historyAnnouncements.length})',
                        style: GoogleFonts.outfit(
                          fontWeight: _showingHistory ? FontWeight.bold : FontWeight.w500,
                          color: _showingHistory ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList(List<Announcement> list) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          _showingHistory
              ? 'ไม่มีประวัติประกาศที่สิ้นสุดแล้ว'
              : 'ไม่มีรายการประกาศในขณะนี้',
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
                                        fontSize: 11,
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
                                      fontSize: 17,
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
                                : (item.publishDate ?? ''),
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          color: const Color(0xFF334155),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Date range row
                      if (item.dateRangeText.isNotEmpty || _showingHistory) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (item.dateRangeText.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.dateRangeText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            if (_showingHistory)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFECDD3),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.history_toggle_off,
                                      size: 13,
                                      color: Color(0xFFE11D48),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'หมดเวลาประกาศแล้ว',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFFBE123C),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
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

