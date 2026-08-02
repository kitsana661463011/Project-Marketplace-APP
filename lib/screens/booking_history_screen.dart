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

  @override
  void initState() {
    super.initState();
    _loadBookings();
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
          _error = 'กรุณาเข้าสู่ระบบก่อนดูประวัติการจอง';
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
    if (b.isApproved) return const Color(0xFFE6F4EA); // Light Green
    if (b.isPending) return const Color(0xFFE0F2FE); // Light Blue
    if (b.isRejected) return const Color(0xFFFEE2E2); // Light Red
    if (b.isRefundRequested) return const Color(0xFFFEF3C7); // Light Amber
    if (b.isRefunded) return const Color(0xFFF3E8FF); // Light Purple
    return const Color(0xFFFEF3C7); // Light Amber
  }

  Color _getStatusTextColor(Booking b) {
    if (b.isApproved) return const Color(0xFF137333); // Dark Green
    if (b.isPending) return const Color(0xFF0284C7); // Dark Blue
    if (b.isRejected) return const Color(0xFFDC2626); // Dark Red
    if (b.isRefundRequested) return const Color(0xFFD97706); // Dark Amber
    if (b.isRefunded) return const Color(0xFF7E22CE); // Dark Purple
    return const Color(0xFFD97706); // Dark Amber
  }

  String _getStatusLabel(Booking b) {
    if (b.isApproved) return 'อนุมัติ';
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
    final String slipUrl = _getImageUrl(b.paymentSlip);

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
                                ? 'ได้รับอนุมัติแผงค้าเรียบร้อย'
                                : b.isRejected
                                ? 'คำขอได้รับการปฏิเสธ'
                                : b.isRefundRequested
                                ? 'อยู่ระหว่างดำเนินการคืนเงิน'
                                : b.isRefunded
                                ? 'ดำเนินการคืนเงินเรียบร้อย'
                                : 'รอแอดมินตรวจสอบและอนุมัติ',
                            subtitle: b.isApproved
                                ? 'สามารถเข้าใช้งานแผงได้ตามกำหนดสัญญา'
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
                          // ค่าเช่า
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
                                  // คำนวณจากรายการที่แสดงจริง (ไม่ใช่ค่าเก่าใน DB)
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

                    // 4. Payment Slip Image Section
                    Text(
                      'หลักฐานการชำระเงิน',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (slipUrl.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => _showFullImageDialog(slipUrl),
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
                              slipUrl,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                    const SizedBox(height: 24),

                    // Actions Row: Request Refund & Close
                    Row(
                      children: [
                        if (!b.isRefundRequested && !b.isRefunded) ...[
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
          'ประวัติการจอง',
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
          : _bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_seat_outlined,
                      size: 48,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีประวัติการจองแผงค้า',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'คุณสามารถเลือกดูและจองแผงค้าได้ที่แผนที่ตลาด',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/market_map');
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(
                      'ไปที่แผนที่ตลาด',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final b = _bookings[index];
                final String billNo = _formatBillNumber(b.bookingId);
                final String stallCode = b.stallNumber ?? 'A01';
                final String stallSize = b.stallSize ?? '3x3 เมตร';
                final double totalAmount =
                    b.totalAmount ??
                    b.amount ??
                    (b.isMonthly
                        ? (b.monthlyPrice ?? 5000)
                        : (b.dailyPrice ?? 500));

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Bill No. & Status Badge (Matches Figma)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'เลขที่บิล $billNo',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
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
                      const SizedBox(height: 8),

                      // Store Icon + Stall Name (Matches Figma)
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'แผง $stallCode',
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Grid: Area & Total Payment (Matches Figma 2-box design)
                      Row(
                        children: [
                          // Left Box: พื้นที่รวม
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.square_foot_outlined,
                                      color: Color(0xFF64748B),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'พื้นที่รวม',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          stallSize,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13.5,
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
                          const SizedBox(width: 12),
                          // Right Box: ยอดชำระรวม
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ยอดชำระรวม',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '฿${totalAmount.toStringAsFixed(0)}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
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
                      const SizedBox(height: 16),

                      // Actions Row: เปิดบิล & ขอคืนเงิน
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showBillDetailsSheet(b),
                              icon: const Icon(Icons.receipt, size: 18),
                              label: Text(
                                'เปิดบิล',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          if (!b.isRefundRequested && !b.isRefunded) ...[
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () => _showRefundModal(b),
                              icon: const Icon(
                                Icons.currency_exchange,
                                size: 16,
                              ),
                              label: Text(
                                'ขอคืนเงิน',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(
                                  color: Color(0xFFDC2626),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
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
