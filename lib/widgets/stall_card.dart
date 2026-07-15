import 'package:flutter/material.dart';
import '../models/stall.dart';

class StallCard extends StatelessWidget {
  final Stall stall;
  final VoidCallback? onTap;

  const StallCard({super.key, required this.stall, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = stall.isAvailable;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isAvailable
                ? [
                    const Color(0xFF1B5E20).withValues(alpha: 0.15),
                    const Color(0xFF004D40).withValues(alpha: 0.08),
                  ]
                : [
                    Colors.grey.withValues(alpha: 0.15),
                    Colors.grey.withValues(alpha: 0.08),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable
                ? const Color(0xFF00BFA5).withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'แผง ${stall.stallNumber}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  _buildStatusBadge(theme),
                ],
              ),
              const SizedBox(height: 12),
              // Zone
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stall.zoneName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Size
              if (stall.size != null)
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ขนาด: ${stall.size}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              // Price
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '฿${stall.zonePrice.toStringAsFixed(0)}/วัน',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color bgColor;
    Color textColor;
    String text;

    switch (stall.status) {
      case 'available':
        bgColor = const Color(0xFF00C853).withValues(alpha: 0.2);
        textColor = const Color(0xFF00C853);
        text = 'ว่าง';
        break;
      case 'occupied':
        bgColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange;
        text = 'ไม่ว่าง';
        break;
      case 'maintenance':
        bgColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        text = 'ปิดปรับปรุง';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.2);
        textColor = Colors.grey;
        text = stall.status;
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
        ),
      ),
    );
  }
}
