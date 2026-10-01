import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../services/auth_service.dart';
import '../services/notification_api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, booking, seller, refund, problem

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final userId = auth.currentUser?.userId;
      if (userId != null) {
        final list = await NotificationApiService.getNotifications(userId: userId);
        if (mounted) {
          setState(() {
            _notifications = list;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.userId;
    if (userId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await NotificationApiService.markAllAsRead(userId);
    if (success && mounted) {
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'ทำเครื่องหมายอ่านแล้วทั้งหมดเรียบร้อย',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleTapNotification(AppNotification notif) async {
    if (!notif.isRead) {
      await NotificationApiService.markAsRead(notif.notificationId);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.notificationId == notif.notificationId);
          if (idx != -1) {
            _notifications[idx] = _notifications[idx].copyWith(isRead: true);
          }
        });
      }
    }
    if (!mounted) return;
    _showDetailDialog(notif);
  }

  String _cleanMessage(String raw) {
    // Strip leading emojis from messages
    return raw.replaceFirst(RegExp(r'^[^\w\s\u0E00-\u0E7F]+'), '').trim();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.isNegative || diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays == 1) return 'เมื่อวานนี้';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    const thaiMonths = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    final buddhistYear = dt.year + 543;
    return '${dt.day} ${thaiMonths[dt.month - 1]} $buddhistYear';
  }

  void _showDetailDialog(AppNotification notif) {
    final cleanMsg = _cleanMessage(notif.message);
    final hasAction = notif.type == 'booking' ||
        notif.type == 'refund' ||
        notif.type == 'problem' ||
        notif.type == 'announcement';

    IconData actionIcon = Icons.arrow_forward_rounded;
    String actionText = 'ดูรายละเอียด';
    if (notif.type == 'booking' || notif.type == 'refund') {
      actionIcon = Icons.receipt_long_rounded;
      actionText = 'ดูการจอง';
    } else if (notif.type == 'problem') {
      actionIcon = Icons.help_outline_rounded;
      actionText = 'ดูรายการปัญหา';
    } else if (notif.type == 'announcement') {
      actionIcon = Icons.campaign_rounded;
      actionText = 'ดูประกาศตลาด';
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Color Accent Bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        notif.categoryColor,
                        notif.categoryColor.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Category Icon + Badge + Timestamp + Close 'X'
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  notif.categoryColor.withValues(alpha: 0.16),
                                  notif.categoryColor.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: notif.categoryColor.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              notif.iconData,
                              color: notif.categoryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: notif.categoryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    notif.typeTitle,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: notif.categoryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (notif.notifyDate != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(notif.notifyDate),
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
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Title
                      Text(
                        notif.displayTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Message Body Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          cleanMsg,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            height: 1.6,
                            color: const Color(0xFF334155),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Bottom Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: hasAction ? 1 : 2,
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                foregroundColor: const Color(0xFF475569),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'ปิด',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ),
                          if (hasAction) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  if (notif.type == 'booking' || notif.type == 'refund') {
                                    Navigator.pushNamed(context, '/booking_history');
                                  } else if (notif.type == 'problem') {
                                    Navigator.pushNamed(context, '/problem_history');
                                  } else if (notif.type == 'announcement') {
                                    Navigator.pushNamed(context, '/announcements');
                                  }
                                },
                                icon: Icon(actionIcon, size: 18),
                                label: Text(
                                  actionText,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: notif.categoryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  shadowColor: notif.categoryColor.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<AppNotification> get _filteredNotifications {
    if (_selectedFilter == 'all') return _notifications;
    return _notifications.where((n) => n.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'การแจ้งเตือน',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (unreadCount >= 2)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF2563EB)),
              label: Text(
                'อ่านทั้งหมด',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('all', 'ทั้งหมด', Icons.all_inbox_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('booking', 'การจองแผงค้า', Icons.store_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('seller', 'ผลสมัครผู้ค้า', Icons.storefront_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('refund', 'การโอนเงินคืน', Icons.account_balance_wallet_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('problem', 'การแจ้งปัญหา', Icons.report_problem_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('announcement', 'ประกาศตลาด', Icons.campaign_rounded),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  )
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: const Color(0xFF2563EB),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _filteredNotifications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notif = _filteredNotifications[index];
                            return _buildNotificationCard(notif);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notif) {
    final cleanMsg = _cleanMessage(notif.message);
    final isUnread = !notif.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTapNotification(notif),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF0F7FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
              width: isUnread ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: isUnread ? 0.05 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon with subtle gradient
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      notif.categoryColor.withValues(alpha: 0.16),
                      notif.categoryColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: notif.categoryColor.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Icon(
                  notif.iconData,
                  color: notif.categoryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (notif.notifyDate != null)
                          Text(
                            _formatDate(notif.notifyDate),
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      cleanMsg,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        height: 1.4,
                        color: isUnread ? const Color(0xFF1E293B) : const Color(0xFF475569),
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread Indicator Dot
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDBEAFE), width: 2),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 38,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ไม่มีการแจ้งเตือนใหม่',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'การแจ้งเตือนส่วนตัว เช่น ผลสมัครผู้ค้า การจองแผง หรือการตอบกลับปัญหา จะแสดงที่นี่',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
