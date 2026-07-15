import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/problem_service.dart';

class ProblemHistoryScreen extends StatefulWidget {
  const ProblemHistoryScreen({super.key});

  @override
  State<ProblemHistoryScreen> createState() => _ProblemHistoryScreenState();
}

class _ProblemHistoryScreenState extends State<ProblemHistoryScreen> {
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = true;
  String _activeTab = 'ทั้งหมด'; // 'ทั้งหมด', 'เสร็จสิ้น', 'กำลังแก้ไข', 'รอดำเนินการ'
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null || currentUser.userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final reports = await ProblemService.getUserProblemReports(currentUser.userId!);
    setState(() {
      _allReports = reports;
      _isLoading = false;
      _filterReports();
    });
  }

  void _filterReports() {
    List<Map<String, dynamic>> temp = [];
    if (_activeTab == 'ทั้งหมด') {
      temp = _allReports;
    } else if (_activeTab == 'เสร็จสิ้น') {
      temp = _allReports.where((r) => r['status'] == 'resolved').toList();
    } else if (_activeTab == 'กำลังแก้ไข') {
      temp = _allReports.where((r) => r['status'] == 'progress').toList();
    } else if (_activeTab == 'รอดำเนินการ') {
      temp = _allReports.where((r) => r['status'] == 'pending' || r['status'] == null).toList();
    }

    if (_selectedDateRange != null) {
      temp = temp.where((r) {
        if (r['report_date'] == null) return false;
        final reportDate = DateTime.tryParse(r['report_date'].toString());
        if (reportDate == null) return false;
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        return reportDate.isAfter(start) && reportDate.isBefore(end);
      }).toList();
    }

    _filteredReports = temp;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF2563EB),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            scaffoldBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterReports();
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFF10B981); // Green
      case 'progress':
        return const Color(0xFF2563EB); // Blue
      case 'pending':
      default:
        return const Color(0xFFD97706); // Orange/Brown
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFFD1FAE5); // Light Green
      case 'progress':
        return const Color(0xFFDBEAFE); // Light Blue
      case 'pending':
      default:
        return const Color(0xFFFEF3C7); // Light Yellow
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'resolved':
        return 'แก้ไขเสร็จสิ้น';
      case 'progress':
        return 'กำลังแก้ไข';
      case 'pending':
      default:
        return 'รอดำเนินการ';
    }
  }

  IconData _getCategoryIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('ไฟฟ้า') || desc.contains('electricity')) {
      return Icons.bolt_outlined;
    } else if (desc.contains('ประปา') || desc.contains('plumbing') || desc.contains('น้ำ')) {
      return Icons.water_drop_outlined;
    } else if (desc.contains('โครงสร้าง') || desc.contains('structure')) {
      return Icons.corporate_fare_outlined;
    } else if (desc.contains('ความสะอาด') || desc.contains('cleanliness') || desc.contains('ขยะ')) {
      return Icons.cleaning_services_outlined;
    }
    return Icons.report_problem_outlined;
  }

  String _cleanDescription(String description) {
    final clean = description.replaceAll(RegExp(r'\[หมวดหมู่:.*?\]\s*'), '');
    return clean.isNotEmpty ? clean : description;
  }

  String _getCategoryName(String description) {
    final match = RegExp(r'\[หมวดหมู่:\s*(.*?)\s*\]').firstMatch(description);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    final desc = description.toLowerCase();
    if (desc.contains('ไฟฟ้า')) return 'ไฟฟ้าดับ/ชำรุด';
    if (desc.contains('ประปา') || desc.contains('น้ำ')) return 'ท่อน้ำชำรุด';
    if (desc.contains('โครงสร้าง')) return 'โครงสร้างอาคาร';
    if (desc.contains('ความสะอาด')) return 'ความสะอาด/ขยะ';
    return 'ทั่วไป';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
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
          child: Container(color: const Color(0xFFF1F5F9), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Tabs Filter (Horizontal Scrollable Selection Header)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    _buildTabItem('ทั้งหมด'),
                    _buildTabItem('เสร็จสิ้น'),
                    _buildTabItem('กำลังแก้ไข'),
                    _buildTabItem('รอดำเนินการ'),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            // Date Filter Row Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
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
                      Icons.calendar_today_outlined,
                      color: Color(0xFF2563EB),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'กรองตามวันที่แจ้ง',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedDateRange == null
                              ? 'ทั้งหมด'
                              : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedDateRange != null) ...[
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                          _filterReports();
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: _selectDateRange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'เลือกวัน',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main List Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
                  : _filteredReports.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'ไม่พบประวัติการแจ้งปัญหา',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ในหมวดหมู่นี้ยังไม่มีรายการประวัติการรายงานค่ะ',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          color: const Color(0xFF3B82F6),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredReports.length + 1, // +1 for "แสดงรายการทั้งหมดแล้ว" text
                            itemBuilder: (context, index) {
                              if (index == _filteredReports.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: Text(
                                      'แสดงรายการทั้งหมดแล้ว',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final report = _filteredReports[index];
                              final String descRaw = report['description'] ?? '';
                              final String cleanDesc = _cleanDescription(descRaw);
                              final String categoryTitle = _getCategoryName(descRaw);
                              final IconData categoryIcon = _getCategoryIcon(descRaw);
                              final String status = report['status'] ?? 'pending';
                              final String dateStr = report['report_date'] != null
                                  ? report['report_date'].toString().split(' ')[0]
                                  : '-';
                              final String? stallNumber = report['stall_number'];

                              // Parse time if possible
                              String timeStr = '12:00 น.';
                              if (report['report_date'] != null) {
                                final parts = report['report_date'].toString().split(' ');
                                if (parts.length > 1) {
                                  timeStr = parts[1].substring(0, 5) + ' น.';
                                }
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/problem_detail',
                                    arguments: report,
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left circle icon
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEFF6FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          categoryIcon,
                                          color: const Color(0xFF2563EB),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Right content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cleanDesc.isNotEmpty ? cleanDesc : categoryTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'แจ้งเมื่อ: $dateStr | $timeStr',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12.5,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                // Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusBgColor(status),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(status),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: _getStatusColor(status),
                                                    ),
                                                  ),
                                                ),

                                                // Stall Badge if present
                                                if (stallNumber != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEEF2F6),
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    child: Text(
                                                      'แผง: $stallNumber',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: const Color(0xFF475569),
                                                      ),
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
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFF1F5F9), width: 1.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'หน้าหลัก', false, 0),
            _buildNavItem(Icons.explore_outlined, 'แผนที่', false, 1),
            _buildNavItem(Icons.favorite_outline, 'ติดตาม', false, 2),
            _buildNavItem(Icons.person, 'เมนู', true, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String tabName) {
    final isActive = _activeTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabName;
          _filterReports();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          tabName,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
