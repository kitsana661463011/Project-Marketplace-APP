import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  // 0 = ข้อมูลการจอง (Active / กำลังดำเนินการ), 1 = ประวัติการจอง (History Archive)
  int _selectedTab = 0;

  // Search & Filter for History Tab
  final TextEditingController _historySearchController = TextEditingController();
  String _historySearchQuery = '';
  String _selectedHistoryFilter = 'ทั้งหมด';

  final List<String> _historyFilterOptions = [
    'ทั้งหมด',
    'หมดสัญญา',
    'คืนเงินแล้ว',
    'ขอคืนเงิน',
    'ไม่อนุมัติ',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _historySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.userId;

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _error = 'กรุณาเข้าสู่ระบบก่อนดูข้อมูลการจอง';
        });
        return;
      }

      final bookings = await BookingService.getMyBookings(userId);
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
        });
      }
    }
  }

  // --- Classification Logic ---
  bool _isBookingActive(Booking b) {
    if (b.isRejected || b.isRefunded || b.isRefundRequested) return false;
    if (b.isPending || b.isRenewalPending) return true;
    if (b.isApproved) {
      if (b.endDate != null && b.endDate!.isNotEmpty) {
        final end = DateTime.tryParse(b.endDate!);
        if (end != null && end.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
          return false; // Contract period has ended -> Archive/History
        }
      }
      return true; // Still active/selling
    }
    return false;
  }

  List<Booking> get _activeBookings =>
      _bookings.where(_isBookingActive).toList();

  List<Booking> get _rawHistoryBookings =>
      _bookings.where((b) => !_isBookingActive(b)).toList();

  List<Booking> get _filteredHistoryBookings {
    var list = _rawHistoryBookings;

    // 1. Filter by status chip
    if (_selectedHistoryFilter == 'หมดสัญญา') {
      list = list.where((b) => b.isApproved).toList();
    } else if (_selectedHistoryFilter == 'ขอคืนเงิน') {
      list = list.where((b) => b.isRefundRequested).toList();
    } else if (_selectedHistoryFilter == 'คืนเงินแล้ว') {
      list = list.where((b) => b.isRefunded).toList();
    } else if (_selectedHistoryFilter == 'ไม่อนุมัติ') {
      list = list.where((b) => b.isRejected).toList();
    }

    // 2. Filter by search query
    final q = _historySearchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((b) {
        final billNo = _formatBillNumber(b.bookingId).toLowerCase();
        final stall = (b.stallNumber ?? '').toLowerCase();
        final zone = (b.zoneName ?? '').toLowerCase();
        return billNo.contains(q) || stall.contains(q) || zone.contains(q);
      }).toList();
    }

    return list;
  }

  String _formatBillNumber(int? id) {
    if (id == null) return '000001';
    return id.toString().padLeft(6, '0');
  }

  String _formatThaiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'ไม่ระบุ';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
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
      return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusBgColor(Booking b) {
    if (b.isApproved) {
      if (!_isBookingActive(b)) return const Color(0xFFF1F5F9); // Light Gray for expired
      return const Color(0xFFE6F4EA); // Light Green
    }
    if (b.isPending) return const Color(0xFFE0F2FE); // Light Blue
    if (b.isRejected) return const Color(0xFFFEE2E2); // Light Red
    if (b.isRefundRequested) return const Color(0xFFFEF3C7); // Light Amber
    if (b.isRefunded) return const Color(0xFFF3E8FF); // Light Purple
    return const Color(0xFFFEF3C7);
  }

  Color _getStatusTextColor(Booking b) {
    if (b.isApproved) {
      if (!_isBookingActive(b)) return const Color(0xFF475569); // Slate Gray for expired
      return const Color(0xFF137333); // Dark Green
    }
    if (b.isPending) return const Color(0xFF0284C7); // Dark Blue
    if (b.isRejected) return const Color(0xFFDC2626); // Dark Red
    if (b.isRefundRequested) return const Color(0xFFD97706); // Dark Amber
    if (b.isRefunded) return const Color(0xFF7E22CE); // Dark Purple
    return const Color(0xFFD97706);
  }

  String _getStatusLabel(Booking b) {
    if (b.isApproved) {
      if (!_isBookingActive(b)) return 'หมดสัญญา';
      return 'อนุมัติ / ใช้งานอยู่';
    }
    if (b.isPending) return 'รออนุมัติ';
    if (b.isRejected) return 'ไม่อนุมัติ';
    if (b.isRefundRequested) return 'ขอคืนเงิน';
    if (b.isRefunded) return 'คืนเงินแล้ว';
    return b.status;
  }

  String _getImageUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    return ApiService.getImagePath(filename);
  }

  // --- Modals & Sheets ---
  void _showRefundModal(Booking b) {
    final bankController = TextEditingController(
      text: b.refundBankName ?? 'กสิกรไทย',
    );
    final accountNumController = TextEditingController(
      text: b.refundAccountNumber ?? '',
    );
    final accountNameController = TextEditingController(
      text: b.refundAccountName ?? (b.userName ?? ''),
    );
    final reasonController = TextEditingController(text: b.refundReason ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.currency_exchange,
                          color: Color(0xFFDC2626),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ขอคืนเงิน (Request Refund)',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'แผง ${b.stallNumber ?? "A01"} • เลขที่บิล ${_formatBillNumber(b.bookingId)}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalContext),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Form Fields
                  Text(
                    'ชื่อธนาคาร',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: bankController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'กรุณาระบุชื่อธนาคาร'
                        : null,
                    decoration: InputDecoration(
                      hintText: 'เช่น กสิกรไทย, ไทยพาณิชย์, กรุงเทพ',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    style: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'เลขที่บัญชี',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: accountNumController,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'กรุณากรอกเลขที่บัญชี'
                        : null,
                    decoration: InputDecoration(
                      hintText: 'เช่น 123-4-56789-0',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    style: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'ชื่อบัญชีผู้รับเงิน',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: accountNameController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'กรุณากรอกชื่อบัญชีผู้รับเงิน'
                        : null,
                    decoration: InputDecoration(
                      hintText: 'ชื่อ-นามสกุล เจ้าของบัญชี',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    style: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'เหตุผลในการขอคืนเงิน',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'กรุณาระบุเหตุผลการขอคืนเงิน'
                        : null,
                    decoration: InputDecoration(
                      hintText:
                          'ระบุเหตุผล เช่น ติดภารกิจส่วนตัว / ขอยกเลิกการจอง',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    style: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              if (b.bookingId == null) return;

                              setModalState(() => isSubmitting = true);

                              final res = await BookingService.requestRefund(
                                bookingId: b.bookingId!,
                                refundReason: reasonController.text.trim(),
                                bankName: bankController.text.trim(),
                                accountNumber: accountNumController.text.trim(),
                                accountName: accountNameController.text.trim(),
                              );

                              if (context.mounted) {
                                Navigator.pop(modalContext);
                                if (res['status'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ส่งคำขอคืนเงินเรียบร้อยแล้ว',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  _loadBookings();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'ขอคืนเงินไม่สำเร็จ: ${res['message'] ?? 'เกิดข้อผิดพลาด'}',
                                        style: GoogleFonts.outfit(),
                                      ),
                                      backgroundColor: const Color(0xFFDC2626),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'ยื่นคำขอคืนเงิน',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBillDetailsSheet(Booking b) {
    final bool isMonthly = b.isMonthly;
    final double price = isMonthly
        ? (b.monthlyPrice ?? b.amount ?? 5000)
        : (b.dailyPrice ?? b.amount ?? 500);
    final String paymentSlipUrl = _getImageUrl(b.paymentSlip);
    final String refundSlipUrl = _getImageUrl(b.refundSlip);
    final bool hasRefundInfo = b.isRefunded ||
        b.isRefundRequested ||
        (b.refundBankName != null && b.refundBankName!.isNotEmpty);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ใบเสร็จ / รายละเอียดการจอง',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'เลขที่บิล ${_formatBillNumber(b.bookingId)}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Status Tracking Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(b).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _getStatusTextColor(b).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'สถานะการอนุมัติแผง',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusBgColor(b),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusLabel(b),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusTextColor(b),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Status Tracker Steps
                          _buildTrackerStep(
                            step: 1,
                            title: 'ส่งคำขอจองแผงค้า',
                            subtitle:
                                'วันที่จอง ${_formatThaiDate(b.bookingDate)}',
                            isDone: true,
                          ),
                          _buildTrackerStep(
                            step: 2,
                            title: 'ชำระเงินและแนบหลักฐาน',
                            subtitle: b.paymentStatus == 'paid'
                                ? 'ชำระเงินเรียบร้อยแล้ว'
                                : 'ส่งหลักฐานการชำระเงินแล้ว',
                            isDone: true,
                          ),
                          _buildTrackerStep(
                            step: 3,
                            title: b.isApproved
                                ? (_isBookingActive(b)
                                    ? 'ได้รับอนุมัติแผงค้าเรียบร้อย'
                                    : 'สัญญาการเช่าแผงสิ้นสุดแล้ว')
                                : b.isRejected
                                ? 'คำขอได้รับการปฏิเสธ'
                                : b.isRefundRequested
                                ? 'อยู่ระหว่างดำเนินการคืนเงิน'
                                : b.isRefunded
                                ? 'ดำเนินการคืนเงินเรียบร้อย'
                                : 'รอแอดมินตรวจสอบและอนุมัติ',
                            subtitle: b.isApproved
                                ? (_isBookingActive(b)
                                    ? 'สามารถเข้าใช้งานแผงได้ตามกำหนดสัญญา'
                                    : 'หมดอายุสัญญาเช่าตามกำหนดเวลา')
                                : b.isRejected
                                ? (b.rejectReason ?? 'ไม่ผ่านการอนุมัติ')
                                : b.isRefundRequested
                                ? 'ยื่นเรื่องขอคืนเงินแล้ว'
                                : 'เจ้าหน้าที่กำลังตรวจสอบข้อมูล',
                            isDone:
                                b.isApproved ||
                                b.isRejected ||
                                b.isRefundRequested ||
                                b.isRefunded,
                            isLast: true,
                            isError: b.isRejected,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Stall Info Details
                    Text(
                      'ข้อมูลแผงค้า & สัญญาเช่า',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _detailItemRow('รหัสแผงค้า', b.stallNumber ?? 'A01'),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _detailItemRow(
                            'โซนพื้นที่',
                            b.zoneName ?? 'โซนทั่วไป',
                          ),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _detailItemRow('ขนาดแผง', b.stallSize ?? '3x3 เมตร'),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _detailItemRow(
                            'รูปแบบการเช่า',
                            isMonthly ? '📆 เช่ารายเดือน' : '📅 เช่ารายวัน',
                          ),
                          const Divider(height: 16, color: Color(0xFFE2E8F0)),
                          _detailItemRow(
                            'ระยะเวลาสัญญา',
                            '${_formatThaiDate(b.startDate)} - ${_formatThaiDate(b.endDate)}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Price Breakdown Section
                    Text(
                      'สรุปค่าใช้จ่าย',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _detailItemRow(
                            isMonthly
                                ? '🏬 ค่าเช่า (รายเดือน)'
                                : '📅 ค่าเช่า (รายวัน)',
                            '฿${price.toStringAsFixed(0)}',
                          ),
                          if (isMonthly && (b.entryFee ?? 0) > 0) ...[
                            const SizedBox(height: 10),
                            _detailItemRow(
                              '🔑 ค่าแรกเข้า',
                              '฿${b.entryFee!.toStringAsFixed(0)}',
                            ),
                          ],
                          if (isMonthly && (b.securityDeposit ?? 0) > 0) ...[
                            const SizedBox(height: 10),
                            _detailItemRow(
                              '🛡️ เงินประกัน',
                              '฿${b.securityDeposit!.toStringAsFixed(0)}',
                            ),
                          ],
                          const SizedBox(height: 14),
                          const Divider(color: Color(0xFFCBD5E1), height: 1),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ยอดรวม',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                () {
                                  final double computedTotal =
                                      price +
                                      (isMonthly ? (b.entryFee ?? 0) : 0) +
                                      (isMonthly
                                          ? (b.securityDeposit ?? 0)
                                          : 0);
                                  return '฿${computedTotal.toStringAsFixed(0)}';
                                }(),
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Refund Section (ถ้ามีการขอคืนเงิน หรือ คืนเงินสำเร็จแล้ว)
                    if (hasRefundInfo) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.currency_exchange,
                            color: Color(0xFF7E22CE),
                            size: 19,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ข้อมูลการคืนเงิน',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (b.refundBankName != null && b.refundBankName!.isNotEmpty) ...[
                              _detailItemRow('ธนาคารผู้รับเงิน', b.refundBankName!),
                              const Divider(height: 16, color: Color(0xFFE9D5FF)),
                            ],
                            if (b.refundAccountNumber != null && b.refundAccountNumber!.isNotEmpty) ...[
                              _detailItemRow('เลขที่บัญชี', b.refundAccountNumber!),
                              const Divider(height: 16, color: Color(0xFFE9D5FF)),
                            ],
                            if (b.refundAccountName != null && b.refundAccountName!.isNotEmpty) ...[
                              _detailItemRow('ชื่อบัญชีผู้รับเงิน', b.refundAccountName!),
                              const Divider(height: 16, color: Color(0xFFE9D5FF)),
                            ],
                            if (b.refundReason != null && b.refundReason!.isNotEmpty) ...[
                              _detailItemRow('เหตุผลขอคืนเงิน', b.refundReason!),
                              const Divider(height: 16, color: Color(0xFFE9D5FF)),
                            ],
                            if (b.refundedAt != null && b.refundedAt!.isNotEmpty) ...[
                              _detailItemRow('วันที่คืนเงินสำเร็จ', _formatThaiDate(b.refundedAt)),
                              const Divider(height: 16, color: Color(0xFFE9D5FF)),
                            ],
                            _detailItemRow('สถานะการคืนเงิน', _getStatusLabel(b)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Refund Slip Image
                      Text(
                        'หลักฐานการโอนเงินคืน (จากผู้ดูแลตลาด)',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (refundSlipUrl.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => _showFullImageDialog(refundSlipUrl),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 240),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF5FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE9D5FF)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                refundSlipUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    height: 160,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF7E22CE),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 48,
                                        color: Color(0xFF7E22CE),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'แนบหลักฐานการโอนเงินคืนเรียบร้อยแล้ว',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: const Color(0xFF6B21A8),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'ชื่อไฟล์: ${b.refundSlip}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: const Color(0xFF9333EA),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF7E22CE),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  b.isRefunded
                                      ? 'ดำเนินการคืนเงินเรียบร้อยแล้ว (ไม่มีไฟล์สลิปแนบ)'
                                      : 'อยู่ระหว่างเจ้าหน้าที่ตรวจสอบและดำเนินการโอนเงินคืน',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF6B21A8),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],

                    // 5. Payment Slip Image Section (หลักฐานการชำระเงินตอนจอง)
                    if (paymentSlipUrl.isNotEmpty || !hasRefundInfo) ...[
                      Text(
                        'หลักฐานการชำระเงิน (ตอนจอง)',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (paymentSlipUrl.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => _showFullImageDialog(paymentSlipUrl),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 240),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                paymentSlipUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    height: 160,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF2563EB),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 48,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'แนบหลักฐานการชำระเงินเรียบร้อยแล้ว',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        'ชื่อไฟล์: ${b.paymentSlip}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.receipt_outlined,
                                color: Color(0xFF94A3B8),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ยังไม่มีหลักฐานการชำระเงิน',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF64748B),
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),

                    // Actions Row: Request Refund & Close
                    Row(
                      children: [
                        if (_isBookingActive(b) && !b.isRefundRequested && !b.isRefunded) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showRefundModal(b);
                              },
                              icon: const Icon(
                                Icons.currency_exchange,
                                size: 18,
                              ),
                              label: Text(
                                'ขอเงินคืน',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(
                                  color: Color(0xFFDC2626),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'ปิดใบเสร็จ',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.white,
                    child: Text(
                      'ไม่สามารถโหลดภาพได้',
                      style: GoogleFonts.outfit(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerStep({
    required int step,
    required String title,
    required String subtitle,
    required bool isDone,
    bool isLast = false,
    bool isError = false,
  }) {
    final Color stepColor = isError
        ? const Color(0xFFDC2626)
        : (isDone ? const Color(0xFF2563EB) : const Color(0xFF94A3B8));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isError
                    ? const Icon(Icons.close, size: 14, color: Colors.white)
                    : (isDone
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '$step',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: stepColor.withValues(alpha: 0.4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailItemRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // --- Segmented Switcher Tab Bar ---
  Widget _buildSegmentedTabBar() {
    final activeCount = _activeBookings.length;
    final historyCount = _rawHistoryBookings.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Tab 0: ข้อมูลการจอง
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 17,
                      color: _selectedTab == 0
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ข้อมูลการจอง',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: _selectedTab == 0
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _selectedTab == 0
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    if (activeCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeCount',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Tab 1: ประวัติการจอง
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 17,
                      color: _selectedTab == 1
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ประวัติการจอง',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: _selectedTab == 1
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _selectedTab == 1
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    if (historyCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$historyCount',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Active Booking Card (Tab 0) ---
  Widget _buildActiveBookingCard(Booking b) {
    final String billNo = _formatBillNumber(b.bookingId);
    final String stallCode = b.stallNumber ?? 'A01';
    final String stallSize = b.stallSize ?? '3x3 เมตร';
    final double totalAmount =
        b.totalAmount ??
        b.amount ??
        (b.isMonthly ? (b.monthlyPrice ?? 5000) : (b.dailyPrice ?? 500));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: b.isApproved
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFE2E8F0),
          width: b.isApproved ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: b.isApproved
                ? const Color(0xFF16A34A).withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Bill Number & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _getStatusTextColor(b),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'เลขที่บิล #$billNo',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(b),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(b),
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: _getStatusTextColor(b),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Stall Name & Zone
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'แผง $stallCode',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      b.zoneName != null && b.zoneName!.isNotEmpty
                          ? '${b.zoneName} • ${b.isMonthly ? "เช่ารายเดือน" : "เช่ารายวัน"}'
                          : (b.isMonthly ? "เช่ารายเดือน" : "เช่ารายวัน"),
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Contract Period Ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ระยะเวลาสัญญา: ${_formatThaiDate(b.startDate)} - ${_formatThaiDate(b.endDate)}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row 4: Grid (Area & Total Payment)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.square_foot_outlined,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'พื้นที่รวม',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              stallSize,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ยอดชำระรวม',
                              style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '฿${totalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF2563EB),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 5: Actions (เปิดบิล & ขอคืนเงิน)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showBillDetailsSheet(b),
                  icon: const Icon(Icons.receipt_long_rounded, size: 17),
                  label: Text(
                    'เปิดบิล / รายละเอียด',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              if (!b.isRefundRequested && !b.isRefunded) ...[
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _showRefundModal(b),
                  icon: const Icon(Icons.currency_exchange, size: 16),
                  label: Text(
                    'ขอคืนเงิน',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- History Record Card (Tab 1) ---
  Widget _buildHistoryRecordCard(Booking b) {
    final String billNo = _formatBillNumber(b.bookingId);
    final String stallCode = b.stallNumber ?? 'A01';
    final double totalAmount =
        b.totalAmount ??
        b.amount ??
        (b.isMonthly ? (b.monthlyPrice ?? 5000) : (b.dailyPrice ?? 500));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Bill & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เลขที่บิล #$billNo',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(b),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getStatusLabel(b),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusTextColor(b),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Stall & Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.store_outlined,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'แผง $stallCode',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (b.zoneName != null && b.zoneName!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(${b.zoneName})',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '฿${totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 3: Date & Details Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'สัญญา: ${_formatThaiDate(b.startDate)} - ${_formatThaiDate(b.endDate)}',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              GestureDetector(
                onTap: () => _showBillDetailsSheet(b),
                child: Row(
                  children: [
                    Text(
                      'ดูใบเสร็จ',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Active Tab Content (Tab 0) ---
  Widget _buildActiveTabContent() {
    final activeList = _activeBookings;

    if (activeList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 46,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'ยังไม่มีข้อมูลการจองปัจจุบัน',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'คุณสามารถเลือกดูผังตลาดและจองแผงค้าที่ว่างได้ทันที',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/market_map');
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(
                  'สำรวจและจองแผงค้า',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: activeList.length,
      itemBuilder: (context, index) => _buildActiveBookingCard(activeList[index]),
    );
  }

  // --- History Tab Content (Tab 1) ---
  Widget _buildHistoryTabContent() {
    final historyList = _filteredHistoryBookings;
    final rawHistoryList = _rawHistoryBookings;

    if (rawHistoryList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 46,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'ยังไม่มีประวัติการจองย้อนหลัง',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'เมื่อสัญญาเช่าแผงสิ้นสุดลง ข้อมูลจะถูกจัดเก็บไว้ที่นี่',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search Bar for History (รองรับเมื่อมีประวัติเยอะ)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _historySearchController,
            onChanged: (v) => setState(() => _historySearchQuery = v),
            decoration: InputDecoration(
              hintText: 'ค้นหาเลขที่บิล หรือ รหัสแผงค้า...',
              hintStyle: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              suffixIcon: _historySearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _historySearchController.clear();
                        setState(() => _historySearchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
            style: GoogleFonts.outfit(fontSize: 13.5),
          ),
        ),

        // Filter Chips (กรองสถานะ: หมดสัญญา, คืนเงินแล้ว, ไม่อนุมัติ ฯลฯ)
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _historyFilterOptions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final opt = _historyFilterOptions[idx];
              final isSelected = _selectedHistoryFilter == opt;
              return FilterChip(
                label: Text(opt),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedHistoryFilter = opt),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFFEFF6FF),
                checkmarkColor: const Color(0xFF2563EB),
                labelStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // List of filtered history records
        Expanded(
          child: historyList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 40,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ไม่พบประวัติการจองที่ตรงกับเงื่อนไข',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: historyList.length,
                  itemBuilder: (context, index) =>
                      _buildHistoryRecordCard(historyList[index]),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'การจองของฉัน',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F172A), size: 22),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadBookings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'ลองใหม่อีกครั้ง',
                        style: GoogleFonts.outfit(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Top Segmented Switcher Tab Bar
                _buildSegmentedTabBar(),

                // Tab Content
                Expanded(
                  child: _selectedTab == 0
                      ? _buildActiveTabContent()
                      : _buildHistoryTabContent(),
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
            selectedIndex: 3,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                    arguments: {'initialIndex': 0},
                  );
                  break;
                case 1:
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                    arguments: {'initialIndex': 1},
                  );
                  break;
                case 2:
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                    arguments: {'initialIndex': 2},
                  );
                  break;
                case 3:
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                    arguments: {'initialIndex': 3},
                  );
                  break;
              }
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
