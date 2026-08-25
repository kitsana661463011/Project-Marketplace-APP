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
  String _activeTab =
      'ทั้งหมด'; // 'ทั้งหมด', 'เสร็จสิ้น', 'กำลังแก้ไข', 'รอดำเนินการ'
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    List<Map<String, dynamic>> allReports =
        await ProblemService.getAllProblemReports();
    List<Map<String, dynamic>> userReports = [];
    if (currentUser?.userId != null) {
      userReports = await ProblemService.getUserProblemReports(
        currentUser!.userId!,
      );
    }

    // Combine user reports and all reports, avoiding duplicates
    final Map<int, Map<String, dynamic>> reportMap = {};

    for (var r in userReports) {
      final id = r['problem_id'] ?? r['id'];
      if (id != null) {
        final key = id is int ? id : int.tryParse(id.toString()) ?? 0;
        reportMap[key] = r;
      }
    }

    for (var r in allReports) {
      final id = r['problem_id'] ?? r['id'];
      if (id != null) {
        final key = id is int ? id : int.tryParse(id.toString()) ?? 0;
        if (!reportMap.containsKey(key)) {
          reportMap[key] = r;
        }
      }
    }

    final combined = reportMap.values.toList();
    combined.sort((a, b) {
      final dateA =
          DateTime.tryParse(a['report_date']?.toString() ?? '') ??
          DateTime(2000);
      final dateB =
          DateTime.tryParse(b['report_date']?.toString() ?? '') ??
          DateTime(2000);
      return dateB.compareTo(dateA);
    });

    if (mounted) {
      setState(() {
        _allReports = combined;
        _isLoading = false;
        _filterReports();
      });
    }
  }

  void _filterReports() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    List<Map<String, dynamic>> temp = [];
    if (_activeTab == 'ทั้งหมด') {
      temp = _allReports;
    } else if (_activeTab == 'รอดำเนินการ') {
      temp = _allReports
          .where((r) => r['status'] == 'pending' || r['status'] == null)
          .toList();
    } else if (_activeTab == 'กำลังแก้ไข') {
      temp = _allReports.where((r) => r['status'] == 'progress').toList();
    } else if (_activeTab == 'เสร็จสิ้น') {
      temp = _allReports.where((r) => r['status'] == 'resolved').toList();
    } else if (_activeTab == 'ปัญหาที่คุณแจ้ง') {
      temp = _allReports.where((r) {
        if (currentUser?.userId == null) return false;
        return r['user_id']?.toString() == currentUser!.userId!.toString();
      }).toList();
    }

    if (_selectedDateRange != null) {
      temp = temp.where((r) {
        if (r['report_date'] == null) return false;
        final reportDate = DateTime.tryParse(r['report_date'].toString());
        if (reportDate == null) return false;
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
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
        return const Color(0xFF047857); // Deep Emerald Green
      case 'progress':
        return const Color(0xFF1D4ED8); // Bold Royal Blue
      case 'pending':
      default:
        return const Color(0xFFB45309); // Bold Amber Brown
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

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFFA7F3D0);
      case 'progress':
        return const Color(0xFF93C5FD);
      case 'pending':
      default:
        return const Color(0xFFFDE68A);
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
    } else if (desc.contains('ประปา') ||
        desc.contains('plumbing') ||
        desc.contains('น้ำ')) {
      return Icons.water_drop_outlined;
    } else if (desc.contains('โครงสร้าง') || desc.contains('structure')) {
      return Icons.corporate_fare_outlined;
    } else if (desc.contains('ความสะอาด') ||
        desc.contains('cleanliness') ||
        desc.contains('ขยะ')) {
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
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

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
          'แจ้งปัญหา',
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
            // Status Tabs Filter
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
                    _buildTabItem('รอดำเนินการ'),
                    _buildTabItem('กำลังแก้ไข'),
                    _buildTabItem('เสร็จสิ้น'),
                    _buildTabItem('ปัญหาที่คุณแจ้ง'),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            // Date Filter Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDateRange,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _selectedDateRange == null
                                  ? 'เลือกช่วงวันที่รายงาน'
                                  : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedDateRange != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDateRange = null;
                          _filterReports();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Main List Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E88E5),
                      ),
                    )
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
                              'ยังไม่มีรายการประวัติการรายงานปัญหา หรือปัญหาที่คุณเคยแจ้งไว้ค่ะ',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/report_problem',
                                );
                                if (result == true) {
                                  _loadHistory();
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                'แจ้งปัญหาใหม่',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _filteredReports.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _filteredReports.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24.0,
                              ),
                              child: Center(
                                child: Text(
                                  'แสดงรายการทั้งหมดแล้ว',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF475569),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }

                          final report = _filteredReports[index];
                          final String descRaw = report['description'] ?? '';
                          final String cleanDesc = _cleanDescription(descRaw);
                          final String categoryTitle = _getCategoryName(
                            descRaw,
                          );
                          final IconData categoryIcon = _getCategoryIcon(
                            descRaw,
                          );
                          final String status = report['status'] ?? 'pending';
                          final String dateStr = report['report_date'] != null
                              ? report['report_date'].toString().split(' ')[0]
                              : '-';
                          final String? stallNumber = report['stall_number'];

                          final bool isMyReport =
                              currentUser != null &&
                              (report['user_id']?.toString() ==
                                  currentUser.userId?.toString());

                          String timeStr = '12:00 น.';
                          if (report['report_date'] != null) {
                            final parts = report['report_date']
                                .toString()
                                .split(' ');
                            if (parts.length > 1) {
                              timeStr = '${parts[1].substring(0, 5)} น.';
                            }
                          }

                          final String reporterName =
                              report['user_name'] ??
                              (report['user'] != null
                                  ? report['user']['username']
                                  : null) ??
                              (isMyReport
                                  ? currentUser.username
                                  : 'ผู้ใช้ในตลาด');

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
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isMyReport
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isMyReport
                                            ? const Color(0xFF93C5FD)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Icon(
                                      categoryIcon,
                                      color: const Color(0xFF2563EB),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                cleanDesc.isNotEmpty
                                                    ? cleanDesc
                                                    : categoryTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isMyReport) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFEFF6FF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFBFDBFE,
                                                    ),
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Text(
                                                  'ปัญหาที่คุณแจ้ง',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF1D4ED8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'ผู้แจ้ง: คุณ$reporterName | $dateStr $timeStr',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getStatusBgColor(
                                                  status,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: _getStatusBorderColor(
                                                    status,
                                                  ),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Text(
                                                _getStatusText(status),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(
                                                    status,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (stallNumber != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFCBD5E1,
                                                    ),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Text(
                                                  'แผง: $stallNumber',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF0F172A,
                                                    ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/report_problem');
          if (result == true) {
            _loadHistory();
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'แจ้งปัญหาใหม่',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
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

  Widget _buildTabItem(String tabName) {
    final isActive = _activeTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabName;
          _filterReports();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          tabName,
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }
}
