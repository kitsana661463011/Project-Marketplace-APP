import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/market_map_item.dart' as model;
import '../models/shop.dart';
import '../services/auth_service.dart';
import '../services/market_map_service.dart';

class MarketMapScreen extends StatefulWidget {
  final bool isEmbedded;
  const MarketMapScreen({super.key, this.isEmbedded = false});

  @override
  State<MarketMapScreen> createState() => _MarketMapScreenState();
}

class _MarketMapScreenState extends State<MarketMapScreen>
    with TickerProviderStateMixin {
  model.MarketMap? _map;
  bool _isLoading = true;
  String? _error;
  model.MarketMapItem? _selectedItem;
  String? _targetStallNum;
  bool _hasFocusedTarget = false;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  // Transform controller for zoom/pan
  final TransformationController _transformationController =
      TransformationController();

  // Filters
  String _filterStatus =
      'all'; // 'all', 'available', 'occupied', 'approved', 'repair'
  String _filterRentalType = 'all'; // 'all', 'daily', 'monthly'

  // Padding around the content bounds
  static const double _canvasPadding = 40.0;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _loadMap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      if (args is String) {
        _targetStallNum = args;
      } else if (args is Map) {
        _targetStallNum = args['stall_number']?.toString() ??
            args['stall_id']?.toString() ??
            args['stall']?.toString();
        final shopObj = args['shop'];
        if (shopObj != null && shopObj is Shop) {
          _targetStallNum ??= shopObj.stallNumber;
        }
      } else if (args is Shop) {
        _targetStallNum = args.stallNumber;
      }
      if (_map != null && !_hasFocusedTarget) {
        _checkAndFocusTargetStall();
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadMap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final map = await MarketMapService.getMainMap();
      if (mounted) {
        setState(() {
          _map = map;
          _isLoading = false;
          if (map == null) {
            _error = 'ไม่สามารถโหลดแผนที่ได้';
          } else {
            _checkAndFocusTargetStall();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'เกิดข้อผิดพลาด: $e';
        });
      }
    }
  }

  void _checkAndFocusTargetStall() {
    if (_map == null || _targetStallNum == null || _hasFocusedTarget) return;

    final String targetClean = _targetStallNum!
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    if (targetClean.isEmpty) return;

    model.MarketMapItem? matchedItem;
    for (final item in _map!.items) {
      if (!item.isBlock) continue;
      final labelClean = item.label
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
          .toUpperCase();
      final itemIdClean = item.mapItemId
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
          .toUpperCase();
      final stallIdClean = item.stallId?.toString() ?? '';

      if (labelClean == targetClean ||
          itemIdClean == targetClean ||
          stallIdClean == targetClean ||
          (labelClean.isNotEmpty && targetClean.contains(labelClean)) ||
          (targetClean.isNotEmpty && labelClean.contains(targetClean))) {
        matchedItem = item;
        break;
      }
    }

    if (matchedItem != null) {
      _selectedItem = matchedItem;
      _filterStatus = 'all';
      _filterRentalType = 'all';
      _hasFocusedTarget = true;
    }
  }

  Color _parseColor(String hex, {double opacity = 1.0}) {
    try {
      final h = hex.replaceAll('#', '');
      final color = Color(int.parse('FF$h', radix: 16));
      return color.withValues(alpha: opacity);
    } catch (_) {
      return Colors.grey.withValues(alpha: opacity);
    }
  }

  bool _isCurrentUserRefundOwner(model.MarketMapItem item) {
    final currentUserId = Provider.of<AuthService>(
      context,
      listen: false,
    ).currentUser?.userId;
    final sellerId = int.tryParse(
      item.seller?['id']?.toString() ??
          item.seller?['user_id']?.toString() ??
          '',
    );

    return currentUserId != null &&
        sellerId != null &&
        currentUserId == sellerId;
  }

  bool _isVacantForViewer(model.MarketMapItem item) {
    if (item.isAvailable) return true;
    if (item.isRefundRequested || item.isRefunded) {
      return !_isCurrentUserRefundOwner(item);
    }
    return false;
  }

  bool _shouldExposeSellerDetails(model.MarketMapItem item) {
    if (item.seller == null) return false;
    if (item.isRefundRequested || item.isRefunded) {
      return _isCurrentUserRefundOwner(item);
    }
    return item.isApproved || item.isPending;
  }

  Color _getStallColor(model.MarketMapItem item) {
    if (item.isRoad) {
      return const Color(0xFFE2E8F0);
    }
    if (item.isEntrance) {
      return const Color(0xFFF97316);
    }
    if (item.isToilet) {
      return const Color(0xFF06B6D4);
    }
    if (item.isExit) {
      return const Color(0xFFDC2626);
    }
    if (item.isDining) {
      return const Color(0xFFF59E0B);
    }
    if (item.isParking) {
      return const Color(0xFF2563EB);
    }
    if (item.isInfo) {
      return const Color(0xFF7C3AED);
    }
    if (item.isTrash) {
      return const Color(0xFF334155);
    }
    if (item.isZone) {
      return _parseColor(item.fillColor, opacity: 0.15);
    }

    if (_isVacantForViewer(item)) {
      return const Color(0xFF10B981); // Emerald Green (แผงว่าง)
    } else if (item.isPending) {
      return const Color(0xFF3B82F6); // Blue (กำลังจอง)
    } else if (item.isApproved) {
      return const Color(0xFFEF4444); // Red (มีผู้เช่าแล้ว / ร้านค้า)
    } else if (item.isRepair) {
      return const Color(0xFFF59E0B); // Amber / Yellow-Orange (ปิดปรับปรุง)
    } else if (item.isRefundRequested) {
      return const Color(0xFF8B5CF6); // Purple (ขอคืนเงิน)
    } else if (item.isRefunded) {
      return const Color(0xFF7C3AED); // Deep Purple (คืนเงินแล้ว)
    } else {
      return const Color(0xFF10B981);
    }
  }

  Color _getFacilityBackground(model.MarketMapItem item) {
    if (item.isToilet) return const Color(0xFF06B6D4);
    if (item.isExit) return const Color(0xFFDC2626);
    if (item.isDining) return const Color(0xFFF59E0B);
    if (item.isParking) return const Color(0xFF2563EB);
    if (item.isInfo) return const Color(0xFF7C3AED);
    if (item.isTrash) return const Color(0xFF334155);
    return _parseColor(item.fillColor, opacity: 0.8);
  }

  bool _shouldShow(model.MarketMapItem item) {
    if (!item.isBlock) return true; // always show zones/roads/entrances

    // Filter by Status
    bool matchesStatus = true;
    if (_filterStatus != 'all') {
      if (_filterStatus == 'available') {
        matchesStatus = item.isAvailable;
      } else if (_filterStatus == 'occupied') {
        matchesStatus = item.isPending;
      } else if (_filterStatus == 'approved') {
        matchesStatus = item.isApproved;
      } else if (_filterStatus == 'repair') {
        matchesStatus = item.isRepair;
      }
    }

    // Filter by Rental Type
    bool matchesRental = true;
    if (_filterRentalType != 'all') {
      if (_filterRentalType == 'daily') {
        matchesRental = item.isDaily;
      } else if (_filterRentalType == 'monthly') {
        matchesRental = item.isMonthly;
      }
    }

    return matchesStatus && matchesRental;
  }

  void _showStallDetail(model.MarketMapItem item) {
    if (!item.isBlock) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final isSeller =
        authService.currentUser?.role == 'seller' ||
        authService.currentUser?.role == 'admin';
    setState(() => _selectedItem = item);

    final bool hasShop = (item.isApproved || item.isPending) &&
        item.seller != null &&
        !item.isRefundRequested &&
        !item.isRefunded &&
        item.seller!['shop_name'] != null &&
        item.seller!['shop_name'].toString().trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        if (!isSeller && hasShop) {
          return _buildCustomerStallSheet(item);
        } else {
          return _buildStallSheet(item, isSeller: isSeller);
        }
      },
    ).whenComplete(() {
      if (mounted) setState(() => _selectedItem = null);
    });
  }

  Widget _buildStallSheet(model.MarketMapItem item, {bool isSeller = false}) {
    final isViewerOwner = _isCurrentUserRefundOwner(item);
    final canBook = _isVacantForViewer(item);
    final statusColor = item.isRefundRequested
        ? (isViewerOwner ? const Color(0xFF8B5CF6) : const Color(0xFF22C55E))
        : item.isRefunded
        ? (isViewerOwner ? const Color(0xFF7C3AED) : const Color(0xFF22C55E))
        : item.isAvailable
        ? const Color(0xFF22C55E)
        : item.isPending
        ? const Color(0xFF3B82F6)
        : item.isApproved
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);

    final statusLabel = item.isRefundRequested
        ? (isViewerOwner ? 'อยู่ระหว่างคืนเงิน' : 'ว่าง')
        : item.isRefunded
        ? (isViewerOwner ? 'คืนเงินแล้ว' : 'ว่าง')
        : item.isAvailable
        ? 'ว่าง'
        : item.isPending
        ? 'กำลังรอจอง'
        : item.isApproved
        ? 'มีผู้เช่าแล้ว'
        : 'ปิดปรับปรุง';

    final priceText = item.isMonthly
        ? '฿${(item.monthlyPrice ?? item.price).toStringAsFixed(0)}/เดือน'
        : '฿${(item.dailyPrice ?? item.price).toStringAsFixed(0)}/วัน';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'แผงค้า ${item.label}',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                // Info rows
                _infoRow(Icons.straighten_outlined, 'ขนาดแผง', item.size),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.sell_outlined,
                  'รูปแบบการเช่า',
                  item.isMonthly ? 'เช่ารายเดือน' : 'เช่ารายวัน',
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.payments_outlined, 'ค่าเช่า', priceText),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Text(
                      'ระบบสาธารณูปโภค: ',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _facilityBadge(
                            item.hasElectricity ? Icons.bolt_rounded : Icons.power_off_outlined,
                            item.hasElectricity ? 'ไฟฟ้า' : 'ไม่มีไฟ',
                            isAvailable: item.hasElectricity,
                            badgeColor: const Color(0xFFD97706),
                          ),
                          _facilityBadge(
                            item.hasWater ? Icons.water_drop_rounded : Icons.opacity_outlined,
                            item.hasWater ? 'น้ำประปา' : 'ไม่มีน้ำ',
                            isAvailable: item.hasWater,
                            badgeColor: const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_shouldExposeSellerDetails(item)) ...[
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.person_outline,
                    'ผู้เช่า',
                    item.seller!['user_name'] ?? item.seller!['name'] ?? 'ไม่ระบุ',
                  ),
                  if (item.seller!['shop_name'] != null &&
                      item.seller!['shop_name'].toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.store_outlined,
                      'ชื่อร้าน',
                      item.seller!['shop_name'],
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                if (canBook)
                  if (isSeller)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.pushNamed(
                            context,
                            '/book_stall',
                            arguments: {'stall': item},
                          );
                          if (result == true && mounted) {
                            _loadMap();
                          }
                        },
                        icon: const Icon(Icons.calendar_month_outlined, size: 18),
                        label: Text(
                          'จองแผงค้านี้',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'แผงนี้ว่างพร้อมเปิดจองสำหรับผู้ค้าในตลาด',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                color: const Color(0xFF15803D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/create_shop');
                        },
                        icon: const Icon(Icons.storefront_rounded, size: 18),
                        label: Text(
                          'สมัครเป็นผู้ค้าเพื่อจองแผงนี้',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ]
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'ปิด',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStallSheet(model.MarketMapItem item) {
    final sellerInfo = item.seller;
    final showSellerIdentity = _shouldExposeSellerDetails(item);
    final hasShop = showSellerIdentity &&
        sellerInfo?['shop_name'] != null &&
        sellerInfo!['shop_name'].toString().trim().isNotEmpty;
    final shopName =
        sellerInfo?['shop_name'] ?? 'ร้านค้าในตลาด';
    final categoryName = sellerInfo?['category_name'] ?? 'อาหารและเครื่องดื่ม';
    final description =
        sellerInfo?['description'] ?? 'มีเมนูเด็ดและสินค้าพร้อมให้บริการ';
    final shopPhone = sellerInfo?['shop_phone'] ?? sellerInfo?['phone'] ?? '';
    final shopImage = sellerInfo?['shop_image'];
    final shopId =
        int.tryParse(
          sellerInfo?['shop_id']?.toString() ??
              sellerInfo?['id']?.toString() ??
              '',
        ) ??
        0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasShop) ...[
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child:
                              shopImage != null &&
                                  shopImage.toString().isNotEmpty
                              ? Image.network(
                                  '${ApiConfig.apiImageUrl}/$shopImage',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.storefront,
                                        color: Color(0xFF2563EB),
                                        size: 32,
                                      ),
                                )
                              : const Icon(
                                  Icons.storefront,
                                  color: Color(0xFF2563EB),
                                  size: 32,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    categoryName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '📍 แผง ${item.label}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
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
                  const SizedBox(height: 18),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),
                  Text(
                    'รายละเอียดร้านค้า',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      description.toString().isNotEmpty
                          ? description.toString()
                          : 'ยินดีต้อนรับสู่ $shopName มีสินค้าและเมนูอร่อยมากมายให้เลือกซื้อ',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        color: const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (shopPhone.toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.phone_outlined,
                      'เบอร์โทรติดต่อ',
                      shopPhone.toString(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final shopObj = Shop(
                          shopId: shopId,
                          shopName: shopName,
                          description: description.toString(),
                          shopPhone: shopPhone.toString(),
                          shopImage: shopImage?.toString(),
                          status: item.status,
                        );
                        Navigator.pushNamed(
                          context,
                          '/shop_detail',
                          arguments: {'shop': shopObj, 'tabIndex': 0},
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu, size: 20),
                      label: Text(
                        'ดูเมนูอาหาร & รายละเอียดร้าน',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: Color(0xFF94A3B8),
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'แผงค้า ${item.label}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          showSellerIdentity
                              ? 'ตำแหน่งนี้ยังไม่มีร้านค้าเปิดให้บริการ'
                              : 'ข้อมูลร้านค้าไม่พร้อมเปิดเผยสำหรับแผงนี้',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ลองแตะดูแผงค้าอื่นๆ บนแผนที่เพื่อหาร้านค้าและเมนูอร่อยได้ค่ะ',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'ปิด',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _facilityBadge(
    IconData icon,
    String label, {
    bool isAvailable = true,
    Color badgeColor = const Color(0xFF475569),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable ? badgeColor.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAvailable ? badgeColor.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isAvailable ? badgeColor : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: isAvailable ? badgeColor : const Color(0xFF94A3B8),
              fontWeight: isAvailable ? FontWeight.w600 : FontWeight.w500,
              decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _zoomIn() {
    final Matrix4 updated = Matrix4.copy(_transformationController.value)
      ..scaledByDouble(1.25, 0, 0, 1);
    setState(() {
      _transformationController.value = updated;
    });
  }

  void _zoomOut() {
    final Matrix4 updated = Matrix4.copy(_transformationController.value)
      ..scaledByDouble(0.8, 0, 0, 1);
    setState(() {
      _transformationController.value = updated;
    });
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'สัญลักษณ์บนแผนที่',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendItem(
                color: const Color(0xFF10B981),
                icon: Icons.storefront_outlined,
                title: 'แผงว่าง',
                subtitle: 'สามารถติดต่อจองได้ทันที',
              ),
              _legendItem(
                color: const Color(0xFF3B82F6),
                icon: Icons.access_time_rounded,
                title: 'กำลังจอง',
                subtitle: 'อยู่ระหว่างรอการอนุมัติสัญญา',
              ),
              _legendItem(
                color: const Color(0xFFEF4444),
                icon: Icons.store_rounded,
                title: 'มีผู้เช่าแล้ว / มีร้านค้า',
                subtitle: 'ร้านค้าเปิดให้บริการตามปกติ',
              ),
              _legendItem(
                color: const Color(0xFFF59E0B),
                icon: Icons.build_rounded,
                title: 'ปิดปรับปรุง',
                subtitle: 'งดให้บริการชั่วคราว',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              _legendFacilityItem(
                icon: '🚻',
                bgColor: const Color(0xFF06B6D4),
                title: 'ห้องน้ำ',
                subtitle: 'สุขาสาธารณะของตลาด',
              ),
              _legendFacilityItem(
                icon: '🍽️',
                bgColor: const Color(0xFFF59E0B),
                title: 'พักกินอาหาร',
                subtitle: 'พื้นที่รับประทานอาหาร',
              ),
              _legendFacilityItem(
                icon: '🅿️',
                bgColor: const Color(0xFF2563EB),
                title: 'ที่จอดรถ',
                subtitle: 'ลานจอดรถของตลาด',
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'เข้าใจแล้ว',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendFacilityItem({
    required String icon,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCount =
        _map?.items.where((i) => i.isBlock && i.isAvailable).length ?? 0;
    final pendingCount =
        _map?.items.where((i) => i.isBlock && i.isPending).length ?? 0;
    final approvedCount =
        _map?.items.where((i) => i.isBlock && i.isApproved).length ?? 0;
    final repairCount =
        _map?.items.where((i) => i.isBlock && i.isRepair).length ?? 0;

    final authService = Provider.of<AuthService>(context, listen: false);
    final isSeller =
        authService.currentUser?.role == 'seller' ||
        authService.currentUser?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF0F172A),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _map?.mapName ?? 'แผนที่ตลาด',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 16.5,
              ),
            ),
            if (_map != null)
              Text(
                '$availableCount ว่าง · $pendingCount จอง · $approvedCount มีผู้เช่า · $repairCount ปรับปรุง',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
            onPressed: _showLegendDialog,
            tooltip: 'สัญลักษณ์',
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF0F172A),
              size: 22,
            ),
            onPressed: _loadMap,
            tooltip: 'รีเฟรช',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isSeller ? 84 : 48),
          child: _buildFilterBar(isSeller: isSeller),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _error != null
          ? _buildError()
          : _buildMapCanvas(),
    );
  }

  Widget _buildFilterBar({bool isSeller = false}) {
    final availableCount =
        _map?.items.where((i) => i.isBlock && i.isAvailable).length ?? 0;
    final pendingCount =
        _map?.items.where((i) => i.isBlock && i.isPending).length ?? 0;
    final approvedCount =
        _map?.items.where((i) => i.isBlock && i.isApproved).length ?? 0;
    final repairCount =
        _map?.items.where((i) => i.isBlock && i.isRepair).length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Status Filters (Full width equal columns)
          Row(
            children: [
              _buildFilterPill(
                label: 'ทั้งหมด',
                isActive: _filterStatus == 'all',
                color: const Color(0xFF2563EB),
                onTap: () => setState(() => _filterStatus = 'all'),
              ),
              const SizedBox(width: 6),
              _buildFilterPill(
                label: '🟢 ว่าง ($availableCount)',
                isActive: _filterStatus == 'available',
                color: const Color(0xFF10B981),
                onTap: () => setState(
                  () => _filterStatus = (_filterStatus == 'available')
                      ? 'all'
                      : 'available',
                ),
              ),
              const SizedBox(width: 6),
              _buildFilterPill(
                label: '🔵 จอง ($pendingCount)',
                isActive: _filterStatus == 'occupied',
                color: const Color(0xFF3B82F6),
                onTap: () => setState(
                  () => _filterStatus = (_filterStatus == 'occupied')
                      ? 'all'
                      : 'occupied',
                ),
              ),
              const SizedBox(width: 6),
              _buildFilterPill(
                label: '🔴 เช่า ($approvedCount)',
                isActive: _filterStatus == 'approved',
                color: const Color(0xFFEF4444),
                onTap: () => setState(
                  () => _filterStatus = (_filterStatus == 'approved')
                      ? 'all'
                      : 'approved',
                ),
              ),
            ],
          ),
          if (isSeller) ...[
            const SizedBox(height: 6),
            // Row 2: Rental Type Filters (For Sellers / Admins)
            Row(
              children: [
                _buildFilterPill(
                  label: '🏢 ทุกสัญญา',
                  isActive: _filterRentalType == 'all' && _filterStatus != 'repair',
                  color: const Color(0xFF475569),
                  onTap: () => setState(() {
                    _filterRentalType = 'all';
                    if (_filterStatus == 'repair') _filterStatus = 'all';
                  }),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: '📅 รายวัน',
                  isActive: _filterRentalType == 'daily',
                  color: const Color(0xFF6366F1),
                  onTap: () => setState(
                    () => _filterRentalType = (_filterRentalType == 'daily')
                        ? 'all'
                        : 'daily',
                  ),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: '📆 รายเดือน',
                  isActive: _filterRentalType == 'monthly',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => setState(
                    () => _filterRentalType = (_filterRentalType == 'monthly')
                        ? 'all'
                        : 'monthly',
                  ),
                ),
                if (repairCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildFilterPill(
                    label: '🟠 ปรับปรุง ($repairCount)',
                    isActive: _filterStatus == 'repair',
                    color: const Color(0xFFF59E0B),
                    onTap: () => setState(
                      () => _filterStatus = (_filterStatus == 'repair')
                          ? 'all'
                          : 'repair',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : const Color(0xFFCBD5E1),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? color : const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, color: Color(0xFFCBD5E1), size: 64),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadMap,
            icon: const Icon(Icons.refresh),
            label: Text('ลองใหม่', style: GoogleFonts.outfit()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCanvas() {
    if (_map == null) return const SizedBox();
    final map = _map!;
    final allItems = map.items;

    // Compute actual content bounds from items
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    for (final item in allItems) {
      if (item.x < minX) minX = item.x;
      if (item.y < minY) minY = item.y;
      if (item.x + item.width > maxX) maxX = item.x + item.width;
      if (item.y + item.height > maxY) maxY = item.y + item.height;
    }
    // Fallback if no items
    if (minX == double.infinity) {
      minX = 0;
      minY = 0;
      maxX = 1000;
      maxY = 800;
    }

    // Add padding around content
    minX -= _canvasPadding;
    minY -= _canvasPadding;
    maxX += _canvasPadding;
    maxY += _canvasPadding;

    final rawW = (maxX - minX);
    final rawH = (maxY - minY);

    final visibleItems = map.items.where((item) => _shouldShow(item)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;

        // Scale dynamically so stalls are comfortably sized and clearly readable on mobile
        double baseScale = (screenW * 1.65) / rawW;
        if (baseScale < 0.95) baseScale = 0.95;
        if (baseScale > 2.5) baseScale = 2.5;

        final contentW = rawW * baseScale;
        final contentH = rawH * baseScale;

        return Stack(
          children: [
            // Interactive Map Canvas with full pan/zoom support
            InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.35,
              maxScale: 4.5,
              boundaryMargin: EdgeInsets.symmetric(
                horizontal: screenW * 0.5,
                vertical: screenH * 0.5,
              ),
              child: Container(
                width: contentW,
                height: contentH,
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Subtle Blueprint dot grid background & background tap listener
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_selectedItem != null) {
                            setState(() => _selectedItem = null);
                          }
                        },
                        child: CustomPaint(
                          size: Size(contentW, contentH),
                          painter: _GridPainter(),
                        ),
                      ),
                    ),
                    // Map items
                    ...visibleItems.map((item) {
                      final x = (item.x - minX) * baseScale;
                      final y = (item.y - minY) * baseScale;
                      final w = item.width * baseScale;
                      final h = item.height * baseScale;

                      return Positioned(
                        left: x,
                        top: y,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: item.isBlock
                              ? () => _showStallDetail(item)
                              : null,
                          child: _buildMapElement(item, w, h),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Top-Right Floating Controls (Zoom / Center / Legend)
            Positioned(
              top: 14,
              right: 14,
              child: _buildFloatingControls(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controlButton(Icons.add, 'ซูมเข้า', _zoomIn, const Color(0xFF2563EB)),
          const Divider(height: 4, thickness: 0.5, color: Color(0xFFE2E8F0)),
          _controlButton(Icons.remove, 'ซูมออก', _zoomOut, const Color(0xFF475569)),
          const Divider(height: 4, thickness: 0.5, color: Color(0xFFE2E8F0)),
          _controlButton(
            Icons.center_focus_strong_rounded,
            'รีเซ็ตมุมมอง',
            _resetZoom,
            const Color(0xFF475569),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildMapElement(model.MarketMapItem item, double w, double h) {
    if (item.isZone) {
      return _buildZone(item, w, h);
    } else if (item.isRoad) {
      return _buildRoad(item, w, h);
    } else if (item.isEntrance) {
      return _buildEntrance(item, w, h);
    } else if (item.isSpecialFacility) {
      return _buildFacilityItem(item, w, h);
    } else {
      return _buildBlock(item, w, h);
    }
  }

  Widget _buildZone(model.MarketMapItem item, double w, double h) {
    final zoneColor = _parseColor(item.fillColor);
    final headerFontSize = (h * 0.12).clamp(13.0, 17.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: zoneColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: zoneColor.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
        ),
        Positioned(
          top: -12,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: zoneColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              item.label,
              style: GoogleFonts.outfit(
                fontSize: headerFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoad(model.MarketMapItem item, double w, double h) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: w,
        height: h,
        color: const Color(0xFFE2E8F0),
        child: Center(
          child: Icon(
            Icons.arrow_forward_rounded,
            size: (h * 0.28).clamp(10.0, 22.0),
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildEntrance(model.MarketMapItem item, double w, double h) {
    final iconSize = (h * 0.35).clamp(16.0, 38.0);
    final fontSize = (h * 0.15).clamp(10.0, 14.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: w,
        height: h,
        color: const Color(0xFFF97316),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.door_front_door_outlined,
              color: Colors.white,
              size: iconSize,
            ),
            if (h > 26) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  item.label,
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityItem(model.MarketMapItem item, double w, double h) {
    final icon = _getFacilityIcon(item);
    final label = _getFacilityLabel(item);
    final bgColor = _getFacilityBackground(item);
    final iconSize = (h * 0.35).clamp(18.0, 42.0);
    final fontSize = (h * 0.18).clamp(12.0, 17.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: iconSize)),
            if (h > 30) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getFacilityIcon(model.MarketMapItem item) {
    if (item.isToilet) return '🚻';
    if (item.isExit) return '🚪';
    if (item.isDining) return '🍽️';
    if (item.isParking) return '🅿️';
    if (item.isInfo) return 'ℹ️';
    if (item.isTrash) return '🗑️';
    return '📍';
  }

  String _getFacilityLabel(model.MarketMapItem item) {
    if (item.isToilet) return 'ห้องน้ำ';
    if (item.isExit) return 'ทางออก';
    if (item.isDining) return 'พักกินอาหาร';
    if (item.isParking) return 'ที่จอดรถ';
    if (item.isInfo) return 'ประชาสัมพันธ์';
    if (item.isTrash) return 'จุดทิ้งขยะ';
    return item.label.isNotEmpty ? item.label : 'สิ่งอำนวยความสะดวก';
  }

  Widget _buildBlock(model.MarketMapItem item, double w, double h) {
    final isSelected = _selectedItem?.mapItemId == item.mapItemId;
    final baseColor = _getStallColor(item);
    final iconSize = (h * 0.32).clamp(16.0, 36.0);
    final fontSize = (h * 0.18).clamp(11.5, 17.0);

    final bool hasShop = (item.isApproved || item.isPending) &&
        item.seller != null &&
        !item.isRefundRequested &&
        !item.isRefunded &&
        item.seller!['shop_name'] != null &&
        item.seller!['shop_name'].toString().trim().isNotEmpty;

    final String displayText;
    if (hasShop) {
      displayText = item.seller!['shop_name'].toString().trim();
    } else {
      displayText = item.label;
    }

    final blockWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: w,
      height: h,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.isAvailable
                  ? Icons.storefront_outlined
                  : item.isRepair
                  ? Icons.build_outlined
                  : Icons.store,
              size: iconSize,
              color: Colors.white,
            ),
            if (displayText.isNotEmpty) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  displayText,
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!isSelected) {
      return blockWidget;
    }

    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        final double opacity = _blinkAnimation.value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Pulsing glow ring around target stall
            Positioned(
              left: -6,
              top: -6,
              right: -6,
              bottom: -6,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: opacity),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: opacity * 0.8),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
            blockWidget,
            // Floating pin location badge above stall - perfectly centered horizontally
            Positioned(
              top: -34,
              left: -50,
              right: -50,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF60A5FA).withValues(alpha: opacity),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF38BDF8),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'แผง ${item.label}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Paints a subtle grid on the map canvas background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 32.0;
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.6;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
