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
    _loadMap();
  }

  @override
  void dispose() {
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
          if (map == null) _error = 'ไม่สามารถโหลดแผนที่ได้';
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
    if (!item.isBlock) return _parseColor(item.fillColor, opacity: 0.35);

    if (_isVacantForViewer(item)) {
      return const Color(0xFF22C55E); // Green (ว่าง)
    } else if (item.isPending) {
      return const Color(0xFF3B82F6); // Blue (กำลังจอง - pending approval)
    } else if (item.isApproved) {
      return const Color(0xFFEF4444); // Red (มีผู้เช่าแล้ว)
    } else if (item.isRepair) {
      return const Color(0xFFF59E0B); // Amber / Yellow-Orange (ปิดปรับปรุง)
    } else if (item.isRefundRequested) {
      return const Color(0xFF8B5CF6); // Purple (ขอคืนเงิน)
    } else if (item.isRefunded) {
      return const Color(0xFF7C3AED); // Deep Purple (คืนเงินแล้ว)
    } else {
      return const Color(0xFF64748B); // Fallback
    }
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildStallSheet(item, isSeller: isSeller),
    ).whenComplete(() {
      if (mounted) setState(() => _selectedItem = null);
    });
  }

  Widget _buildStallSheet(model.MarketMapItem item, {bool isSeller = false}) {
    if (!isSeller) {
      return _buildCustomerStallSheet(item);
    }

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
                if (_shouldExposeSellerDetails(item)) ...[
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.person_outline,
                    'ผู้เช่า',
                    item.seller!['name'] ?? 'ไม่ระบุ',
                  ),
                  if (item.seller!['shop_name'] != null) ...[
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
    final hasShop = showSellerIdentity;
    final shopName =
        sellerInfo?['shop_name'] ?? sellerInfo?['name'] ?? 'ร้านค้าในตลาด';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                fontSize: 17,
              ),
            ),
            if (_map != null)
              Text(
                '$availableCount แผงว่าง · $pendingCount กำลังจอง · $approvedCount มีผู้เช่า · $repairCount ปิดปรับปรุง',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_outlined,
              color: Color(0xFF0F172A),
              size: 22,
            ),
            onPressed: _loadMap,
            tooltip: 'รีเฟรช',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(82),
          child: _buildFilterBar(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : _error != null
          ? _buildError()
          : _buildMapCanvas(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: _zoomIn,
            backgroundColor: Colors.white,
            elevation: 3,
            child: const Icon(Icons.add, color: Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: _zoomOut,
            backgroundColor: Colors.white,
            elevation: 3,
            child: const Icon(Icons.remove, color: Color(0xFF475569), size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'reset',
            onPressed: _resetZoom,
            backgroundColor: Colors.white,
            elevation: 3,
            child: const Icon(
              Icons.center_focus_strong,
              color: Color(0xFF475569),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final statusFilters = [
      {'key': 'all', 'label': 'ทั้งหมด', 'color': const Color(0xFF2563EB)},
      {'key': 'available', 'label': 'ว่าง', 'color': const Color(0xFF22C55E)},
      {
        'key': 'occupied',
        'label': 'กำลังจอง',
        'color': const Color(0xFF3B82F6),
      },
      {
        'key': 'approved',
        'label': 'มีผู้เช่า',
        'color': const Color(0xFFEF4444),
      },
      {
        'key': 'repair',
        'label': 'ปิดปรับปรุง',
        'color': const Color(0xFFF59E0B),
      },
    ];

    final rentalTypeFilters = [
      {'key': 'all', 'label': 'ทั้งหมด'},
      {'key': 'daily', 'label': '📅 แผงรายวัน'},
      {'key': 'monthly', 'label': '📆 แผงรายเดือน'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Status Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ...statusFilters.map((f) {
                  final isActive = _filterStatus == f['key'];
                  final Color itemColor = f['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _filterStatus = f['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? itemColor.withValues(alpha: 0.15)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive
                                ? itemColor
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (f['key'] != 'all') ...[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: itemColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              f['label'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isActive
                                    ? itemColor
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Row 2: Rental Type Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Text(
                  'สัญญา: ',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                ...rentalTypeFilters.map((rf) {
                  final isActive = _filterRentalType == rf['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _filterRentalType = rf['key'] as String,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          rf['label'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
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
        double dynamicScale = (screenW * 0.92) / rawW;
        if (dynamicScale < 0.3) dynamicScale = 0.3;
        if (dynamicScale > 1.2) dynamicScale = 1.2;

        final contentW = rawW * dynamicScale;
        final contentH = rawH * dynamicScale;

        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.3,
          maxScale: 8.0,
          boundaryMargin: const EdgeInsets.all(120),
          child: Center(
            child: Container(
              width: contentW,
              height: contentH,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Grid background
                  CustomPaint(
                    size: Size(contentW, contentH),
                    painter: _GridPainter(),
                  ),
                  // Map items — offset by minX/minY so content starts at top-left
                  ...visibleItems.map((item) {
                    final x = (item.x - minX) * dynamicScale;
                    final y = (item.y - minY) * dynamicScale;
                    final w = item.width * dynamicScale;
                    final h = item.height * dynamicScale;

                    return Positioned(
                      left: x,
                      top: y,
                      child: GestureDetector(
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
        );
      },
    );
  }

  Widget _buildMapElement(model.MarketMapItem item, double w, double h) {
    if (item.isZone) {
      return _buildZone(item, w, h);
    } else if (item.isRoad) {
      return _buildRoad(item, w, h);
    } else if (item.isEntrance) {
      return _buildEntrance(item, w, h);
    } else {
      return _buildBlock(item, w, h);
    }
  }

  Widget _buildZone(model.MarketMapItem item, double w, double h) {
    final zoneColor = _parseColor(item.fillColor);
    final headerFontSize = (h * 0.08).clamp(10.0, 13.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: zoneColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
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
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: w,
        height: h,
        color: const Color(0xFFE2E8F0),
        child: Center(
          child: Icon(
            Icons.arrow_forward,
            size: (h * 0.25).clamp(8.0, 20.0),
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildEntrance(model.MarketMapItem item, double w, double h) {
    final iconSize = (h * 0.28).clamp(10.0, 32.0);
    final fontSize = (h * 0.12).clamp(6.0, 10.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
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
            if (h > 30) ...[
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

  Widget _buildBlock(model.MarketMapItem item, double w, double h) {
    final isSelected = _selectedItem?.mapItemId == item.mapItemId;
    final baseColor = _getStallColor(item);
    final iconSize = (h * 0.28).clamp(10.0, 32.0);
    final fontSize = (h * 0.14).clamp(7.0, 12.5);
    final showLabel = h > 26;

    // Show shop/seller name only for occupied/approved stalls.
    // Available, repair, and refund-related stalls should not show seller names on the map.
    final String displayText;
    if ((item.isApproved || item.isPending) &&
        item.seller != null &&
        !item.isRefundRequested &&
        !item.isRefunded) {
      final String? shopName = item.seller!['shop_name'];
      final String? sellerName = item.seller!['name'];
      displayText = (shopName != null && shopName.isNotEmpty)
          ? shopName
          : (sellerName != null && sellerName.isNotEmpty)
          ? sellerName
          : item.label;
    } else {
      displayText = '';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: w,
      height: h,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: isSelected ? 1.0 : 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? Colors.white : baseColor,
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
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
            if (showLabel && displayText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  displayText,
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
  }
}

/// Paints a subtle grid on the map canvas background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 35.0;
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
