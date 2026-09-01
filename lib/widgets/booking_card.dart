import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onRefundSuccess;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onRefundSuccess,
  });

  void _showRefundDialog(BuildContext context) {
    final bankController = TextEditingController();
    final accountNumberController = TextEditingController();
    final accountNameController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.currency_exchange, color: Color(0xFF9333EA), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'ยื่นคำขอคืนเงิน',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'กรุณากรอกข้อมูลบัญชีธนาคารสำหรับรับเงินโอนคืน',
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: bankController,
                  style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'ชื่อธนาคาร (เช่น กสิกรไทย, ไทยพาณิชย์)',
                    labelStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.account_balance, color: Color(0xFF64748B), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.8),
                    ),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อธนาคาร' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'เลขที่บัญชี',
                    labelStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.numbers, color: Color(0xFF64748B), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.8),
                    ),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกเลขที่บัญชี' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: accountNameController,
                  style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'ชื่อบัญชีผู้รับเงิน',
                    labelStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF64748B), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.8),
                    ),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อบัญชี' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  maxLines: 2,
                  style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'เหตุผลในการขอคืนเงิน',
                    labelStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.notes, color: Color(0xFF64748B), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.8),
                    ),
                    isDense: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุเหตุผล' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate() && booking.bookingId != null) {
                Navigator.pop(ctx);
                final res = await BookingService.requestRefund(
                  bookingId: booking.bookingId!,
                  refundReason: reasonController.text.trim(),
                  bankName: bankController.text.trim(),
                  accountNumber: accountNumberController.text.trim(),
                  accountName: accountNameController.text.trim(),
                );

                if (context.mounted) {
                  if (res['status'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ส่งคำขอคืนเงินเรียบร้อยแล้ว')),
                    );
                    onRefundSuccess?.call();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'] ?? 'เกิดข้อผิดพลาดในการยื่นขอคืนเงิน')),
                    );
                  }
                }
              }
            },
            child: const Text('ยืนยันส่งคำขอ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.bookmark_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'การจอง #${booking.bookingId}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'แผง ${booking.stallNumber ?? "-"}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(theme),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Details
              _buildInfoRow(
                theme,
                Icons.location_on_outlined,
                'โซน',
                booking.zoneName ?? '-',
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                theme,
                Icons.calendar_today_outlined,
                'วันที่จอง',
                booking.bookingDate ?? '-',
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                theme,
                Icons.date_range_outlined,
                'ระยะเวลา',
                '${booking.startDate ?? "-"} ถึง ${booking.endDate ?? "-"}',
              ),
              if (booking.amount != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  theme,
                  Icons.payments_outlined,
                  'ยอดชำระ',
                  '฿${booking.amount!.toStringAsFixed(0)}',
                ),
              ],
              if (booking.status == 'cancelled' || booking.rejectReason != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  theme,
                  Icons.error_outline,
                  'เหตุผลที่ไม่อนุมัติ',
                  booking.rejectReason != null && booking.rejectReason!.isNotEmpty
                      ? booking.rejectReason!
                      : 'ไม่ได้ระบุเหตุผล',
                  textColor: Colors.red.shade700,
                ),
              ],
              if (booking.status == 'refund_requested') ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  theme,
                  Icons.info_outline,
                  'สถานะคืนเงิน',
                  'กำลังรอแอดมินดำเนินการโอนเงินคืน',
                  textColor: Colors.purple.shade700,
                ),
              ],
              if (booking.status == 'refunded') ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  theme,
                  Icons.check_circle_outline,
                  'สถานะคืนเงิน',
                  'โอนเงินคืนเข้าบัญชีสำเร็จแล้ว',
                  textColor: Colors.cyan.shade800,
                ),
                if (booking.refundSlip != null && booking.refundSlip!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        final imageUrl = '${ApiConfig.apiImageUrl}/${booking.refundSlip}';
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text(
                              'หลักฐานการโอนเงินคืน',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.broken_image, size: 48, color: Color(0xFF94A3B8)),
                                          const SizedBox(height: 8),
                                          Text('ไม่สามารถโหลดภาพสลิปได้', style: GoogleFonts.outfit(color: const Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'ปิด',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('ดูสลิปโอนเงินคืน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
              // Refund Button Action
              if (booking.status == 'approved' || booking.status == 'pending') ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () => _showRefundDialog(context),
                    icon: const Icon(Icons.currency_exchange, size: 16),
                    label: const Text('ขอคืนเงิน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Color? textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color bgColor;
    Color textColor;
    String text;

    switch (booking.status) {
      case 'pending':
        bgColor = Colors.amber.withValues(alpha: 0.2);
        textColor = Colors.amber.shade700;
        text = 'รอดำเนินการ';
        break;
      case 'pending_review':
        bgColor = Colors.blue.withValues(alpha: 0.2);
        textColor = Colors.blue;
        text = 'รอตรวจสอบ';
        break;
      case 'approved':
        bgColor = const Color(0xFF00C853).withValues(alpha: 0.2);
        textColor = const Color(0xFF00C853);
        text = 'อนุมัติแล้ว';
        break;
      case 'refund_requested':
        bgColor = Colors.purple.withValues(alpha: 0.2);
        textColor = Colors.purple.shade700;
        text = 'รออนุมัติคืนเงิน';
        break;
      case 'refunded':
        bgColor = Colors.cyan.withValues(alpha: 0.2);
        textColor = Colors.cyan.shade800;
        text = 'คืนเงินสำเร็จ';
        break;
      case 'cancelled':
        bgColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        text = 'ยกเลิก';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.2);
        textColor = Colors.grey;
        text = booking.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
