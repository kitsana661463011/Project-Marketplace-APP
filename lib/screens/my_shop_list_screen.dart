import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/shop_service.dart';
import '../services/booking_service.dart';
import '../models/shop.dart';
import '../models/booking.dart';

class MyShopListScreen extends StatefulWidget {
  const MyShopListScreen({super.key});

  @override
  State<MyShopListScreen> createState() => _MyShopListScreenState();
}

class _MyShopListScreenState extends State<MyShopListScreen> {
  List<Shop> _myShops = [];
  List<Booking> _approvedBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  Future<void> _loadMerchantData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null || currentUser.userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final shops = await ShopService.getShops(userId: currentUser.userId!);
      final bookings = await BookingService.getMyBookings(currentUser.userId!);
      final approved = bookings.where((b) => b.status == 'approved').toList();

      setState(() {
        _myShops = shops;
        _approvedBookings = approved;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stalls mapping logic:
    final List<Map<String, dynamic>> activeShops = [];
    final List<Booking> pendingStalls = [];

    for (int i = 0; i < _myShops.length; i++) {
      final Shop shop = _myShops[i];
      String stallNum = shop.stallNumber != null && shop.stallNumber!.isNotEmpty
          ? shop.stallNumber!
          : 'C02';
      String zoneName = shop.zoneName != null && shop.zoneName!.isNotEmpty
          ? shop.zoneName!
          : 'โซนตลาดใต้ตึก';

      if (i < _approvedBookings.length) {
        if (_approvedBookings[i].stallNumber != null &&
            _approvedBookings[i].stallNumber!.isNotEmpty) {
          stallNum = _approvedBookings[i].stallNumber!;
        }
        if (_approvedBookings[i].zoneName != null &&
            _approvedBookings[i].zoneName!.isNotEmpty) {
          zoneName = _approvedBookings[i].zoneName!;
        }
      }

      activeShops.add({
        'shop': shop,
        'stall_number': stallNum,
        'zone_name': zoneName,
      });
    }

    // Remaining approved bookings without shop profile
    if (_approvedBookings.length > _myShops.length) {
      pendingStalls.addAll(_approvedBookings.sublist(_myShops.length));
    }

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
          'จัดการร้านค้าของฉัน',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. ร้านค้าที่เปิดอยู่แล้ว Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ร้านค้าที่เปิดอยู่แล้ว',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${activeShops.length} ร้านค้า',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Active Shops list
                      ...activeShops.map((item) {
                        final Shop shop = item['shop'];
                        final String stallNum = item['stall_number'];
                        final String zoneName = item['zone_name'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Avatar with green status indicator
                                  Stack(
                                    children: [
                                      ClipOval(
                                        child: Container(
                                          width: 56,
                                          height: 56,
                                          color: const Color(0xFFEFF6FF),
                                          child:
                                              shop.shopImage != null &&
                                                      shop.shopImage!.isNotEmpty
                                                  ? Image.network(
                                                      ApiService.getImagePath(
                                                        shop.shopImage,
                                                      ),
                                                      width: 56,
                                                      height: 56,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.storefront,
                                                            color: Color(
                                                              0xFF2563EB,
                                                            ),
                                                            size: 26,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.storefront,
                                                      color: Color(0xFF2563EB),
                                                      size: 26,
                                                    ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: shop.isOpen
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),

                                  // Name and Stall Details with Zone Location
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shop.shopName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.place_rounded,
                                              size: 14,
                                              color: Color(0xFF2563EB),
                                            ),
                                            const SizedBox(width: 3),
                                            Expanded(
                                              child: Text(
                                                'แผง $stallNum ($zoneName)',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF1E40AF,
                                                  ),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 10),

                              // Quick Actions (Map Button & Manage Button)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/market_map',
                                          arguments: {
                                            'shop': shop,
                                            'stall_number': stallNum,
                                          },
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.map_outlined,
                                        size: 15,
                                        color: Color(0xFF059669),
                                      ),
                                      label: Text(
                                        'จุดตำแหน่งแผง',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF059669),
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color(0xFFECFDF5),
                                        side: const BorderSide(
                                          color: Color(0xFFA7F3D0),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/manage_shop',
                                          arguments: {
                                            'shop': shop,
                                            'stall_number': stallNum,
                                          },
                                        ).then((_) => _loadMerchantData());
                                      },
                                      icon: const Icon(
                                        Icons.settings_outlined,
                                        size: 15,
                                      ),
                                      label: Text(
                                        'จัดการร้านค้า',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1E88E5,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      // 3. แผงค้าที่รอสร้างร้าน Section
                      if (pendingStalls.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'แผงค้าที่รอสร้างร้าน',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'พร้อมสร้าง ${pendingStalls.length} แผง',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Pending Stalls List Cards
                        ...pendingStalls.map((booking) {
                          final String stallNum =
                              booking.stallNumber ?? 'A3';
                          final String zoneInfo =
                              booking.zoneName ?? 'โซนตลาดใต้ตึก';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF93C5FD),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2563EB,
                                  ).withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.add_business_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 24,
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
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFDCFCE7,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'อนุมัติแล้ว',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF15803D,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'แผงใหม่: $stallNum',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'ตำแหน่ง: $zoneInfo',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/create_shop',
                                        arguments: {
                                          'stall_number': stallNum,
                                          'stall_id': booking.stallId,
                                        },
                                      ).then((_) => _loadMerchantData());
                                    },
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'สร้างโปรไฟล์ร้านค้า',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
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
            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.home,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'หน้าหลัก',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.explore_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.explore,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'แผนที่',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.favorite_outline,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.favorite,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'ติดตาม',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
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
