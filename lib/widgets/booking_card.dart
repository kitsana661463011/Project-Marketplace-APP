import 'package:flutter/material.dart';
import '../models/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;

  const BookingCard({super.key, required this.booking, this.onTap});

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
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
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
