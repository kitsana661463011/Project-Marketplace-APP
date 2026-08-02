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
    // If we have shops, map them to the first approved bookings.
    // Any remaining approved bookings without shops go to "แผงค้าที่รอสร้างร้าน".
    final List<Map<String, dynamic>> activeShops = [];
    final List<Booking> pendingStalls = [];

    for (int i = 0; i < _myShops.length; i++) {
      String stallNum = 'C2'; // Fallback default matching Screenshot 1
      if (i < _approvedBookings.length) {
        stallNum = _approvedBookings[i].stallNumber ?? 'C2';
      }
      activeShops.add({'shop': _myShops[i], 'stall_number': stallNum});
    }

    // Remaining approved bookings that don't have a shop profile yet
    if (_approvedBookings.length > _myShops.length) {
      pendingStalls.addAll(_approvedBookings.sublist(_myShops.length));
    }

    // No fallback mock data - if shops are empty, show proper empty state

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
                              fontSize: 15,
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

                      // Shops list
                      ...activeShops.map((item) {
                        final Shop shop = item['shop'];
                        final String stallNum = item['stall_number'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.01),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar with green status indicator
                              Stack(
                                children: [
                                  ClipOval(
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      color: const Color(0xFFEFF6FF),
                                      child:
                                          shop.shopImage != null &&
                                              shop.shopImage!.isNotEmpty
                                          ? Image.network(
                                              ApiService.getImagePath(
                                                shop.shopImage,
                                              ),
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.storefront,
                                                    color: Color(0xFF2563EB),
                                                    size: 28,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.storefront,
                                              color: Color(0xFF2563EB),
                                              size: 28,
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
                                        color: const Color(
                                          0xFF10B981,
                                        ), // Green status dot
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

                              // Name and Stall Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.shopName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'แผงค้า: $stallNum',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Manage Button
                              ElevatedButton.icon(
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
                                  size: 14,
                                ),
                                label: Text(
                                  'จัดการ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  foregroundColor: const Color(0xFF2563EB),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 10),

                      // 2. แผงค้าที่รอสร้างร้าน Section
                      if (pendingStalls.isNotEmpty) ...[
                        Text(
                          'แผงค้าที่รอสร้างร้าน',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Dashed pending stall card
                        ...pendingStalls.map((booking) {
                          final String stallNum = booking.stallNumber ?? 'A3';
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                                style: BorderStyle
                                    .solid, // solid border since Flutter doesn't have dashed natively without custom painters
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Plus Storefront Icon
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_business_outlined,
                                    color: Color(0xFF2563EB),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Title text
                                Text(
                                  'คุณมีแผงใหม่: $stallNum',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Subtext
                                Text(
                                  'แผงค้าของคุณได้รับการอนุมัติแล้ว เริ่มสร้างโปรไฟล์ร้านค้ากันเลย',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: const Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Action Button
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
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'สร้างร้านค้าใหม่',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
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
