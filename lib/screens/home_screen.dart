import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/shop_service.dart';
import '../models/shop.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const _PlaceholderTab(title: 'แผนที่ตลาด', icon: Icons.explore_outlined),
      const _FollowedTab(),
      const _ProfileTab(),
    ];
  }

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF1E88E5).withOpacity(0.12),
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined, size: 24, color: Color(0xFF64748B)),
                selectedIcon: const Icon(Icons.home, size: 24, color: Color(0xFF1E88E5)),
                label: 'หน้าหลัก',
              ),
              NavigationDestination(
                icon: const Icon(Icons.explore_outlined, size: 24, color: Color(0xFF64748B)),
                selectedIcon: const Icon(Icons.explore, size: 24, color: Color(0xFF1E88E5)),
                label: 'แผนที่ตลาด',
              ),
              NavigationDestination(
                icon: const Icon(Icons.favorite_outline, size: 24, color: Color(0xFF64748B)),
                selectedIcon: const Icon(Icons.favorite, size: 24, color: Color(0xFF1E88E5)),
                label: 'ติดตาม',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline, size: 24, color: Color(0xFF64748B)),
                selectedIcon: const Icon(Icons.person, size: 24, color: Color(0xFF1E88E5)),
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Shop> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);
    try {
      final shops = await ShopService.getShops();
      if (mounted) {
        setState(() {
          _shops = shops;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToShopDetail(Shop shop) async {
    final result = await Navigator.pushNamed(
      context,
      '/shop_detail',
      arguments: {'shop': shop, 'tabIndex': 0},
    );
    if (result != null && result is int && mounted) {
      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeState != null) {
        homeState.setIndex(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadShops,
        color: const Color(0xFF1E88E5),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // App icon logo
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Image.asset(
                              'assets/home_logo.png',
                              color: Colors.white,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'MarketPlace',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  // Notification bell
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/announcements');
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Color(0xFF475569),
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '1',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  style: GoogleFonts.outfit(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาร้าน หรือ ร้านค้า...',
                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 15),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Followed Shops Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ร้านค้าที่คุณติดตาม',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'ดูทั้งหมด',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal list of followed shops
              _isLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
                      ),
                    )
                  : SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _shops.length,
                        itemBuilder: (context, index) {
                          final shop = _shops[index];
                          return GestureDetector(
                            onTap: () => _navigateToShopDetail(shop),
                            child: Container(
                              margin: const EdgeInsets.only(right: 18),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 34,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    backgroundImage: shop.shopImage != null && shop.shopImage!.isNotEmpty
                                        ? (shop.shopImage!.startsWith('http')
                                            ? NetworkImage(shop.shopImage!)
                                            : NetworkImage(ApiService.getImagePath(shop.shopImage)))
                                        : null,
                                    child: shop.shopImage == null || shop.shopImage!.isEmpty
                                        ? const Icon(Icons.storefront, color: Color(0xFF64748B), size: 30)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    shop.shopName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 24),

              // Recommended Shops Section
              Text(
                'ร้านแนะนำสำหรับคุณ',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Vertical list/card of recommended shops
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
                      ),
                    )
                  : _shops.isEmpty
                      ? Center(
                          child: Text(
                            'ยังไม่มีร้านแนะนำในขณะนี้',
                            style: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                          ),
                        )
                      : Column(
                          children: _shops.map((shop) => _buildRecommendedCard(shop)).toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedCard(Shop shop) {
    return GestureDetector(
      onTap: () => _navigateToShopDetail(shop),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: shop.shopImage != null && shop.shopImage!.isNotEmpty
                    ? (shop.shopImage!.startsWith('http')
                        ? Image.network(shop.shopImage!, fit: BoxFit.cover)
                        : Image.network(
                            ApiService.getImagePath(shop.shopImage),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildCoverPlaceholder(),
                          ))
                    : _buildCoverPlaceholder(),
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.shopName,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.description ?? 'ร้านค้าคุณภาพสำหรับคุณ',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.storefront,
          size: 60,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              'หน้ารายการ $title (ชั่วคราว)',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<String> _interests = ['อาหาร', 'แฟชั่น', 'ขนม', 'สตรีทฟู้ด', 'เครื่องดื่ม', 'อื่นๆ'];
  final List<String> _selectedInterests = ['อาหาร', 'แฟชั่น', 'ขนม'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initForm(UserModel? user) {
    _nameController.text = user?.username ?? 'สมชาย ใจดี';
    _phoneController.text = user?.phone ?? '081-999-99999';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // Use backend user details or fallback to mockup info
    final String displayName = user != null && user.username.isNotEmpty ? user.username : 'สมชาย ใจดี';
    final String displayRole = user != null && user.role == 'seller' ? 'เป็นสมาชิก และผู้ขาย' : 'เป็นสมาชิก';
    final String displayEmail = user?.email ?? 'Test@gmail.com';
    final String joinDate = 'เข้าร่วมเมื่อ มกราคม 2023';

    // Face image matching mock portrait
    const String defaultAvatarUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300';
    final String avatarUrl = user?.profileImage != null && user!.profileImage!.isNotEmpty
        ? (user.profileImage!.startsWith('http') ? user.profileImage! : ApiService.getImagePath(user.profileImage))
        : defaultAvatarUrl;

    if (_isEditing) {
      if (_nameController.text.isEmpty && _phoneController.text.isEmpty) {
        _initForm(user);
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top AppBar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.clear();
                          _phoneController.clear();
                        });
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF0F172A),
                          size: 18,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/announcements');
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Color(0xFF475569),
                              size: 24,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '1',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Avatar
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: CircleAvatar(
                            radius: 64,
                            backgroundColor: const Color(0xFFE2E8F0),
                            backgroundImage: NetworkImage(avatarUrl),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'คุณ$displayName',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          // Change photo trigger
                        },
                        child: Text(
                          'เปลี่ยนรูปโปรไฟล์',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        joinDate,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                Text(
                  'ชื่อ - นามสกุล',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.outfit(color: Colors.black),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'อีเมล (ไม่สามารถเปลี่ยนได้)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    enabled: false,
                    controller: TextEditingController(text: displayEmail),
                    style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'เบอร์โทร',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    style: GoogleFonts.outfit(color: Colors.black),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'สิ่งที่สนใจ',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _interests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(
                        interest,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                      selectedColor: const Color(0xFFE3F2FD),
                      checkmarkColor: const Color(0xFF1E88E5),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty) {
                        AppDialog.showError(context, title: 'ข้อผิดพลาด', message: 'กรุณากรอกชื่อ-นามสกุล');
                        return;
                      }

                      AppDialog.showConfirm(
                        context,
                        title: 'ยืนยันการบันทึก',
                        message: 'คุณต้องการบันทึกการเปลี่ยนแปลงข้อมูลโปรไฟล์ใช่หรือไม่?',
                        onConfirm: () async {
                          // Call authService backend update
                          await authService.updateProfile({
                            'username': _nameController.text.trim(),
                            'phone': _phoneController.text.trim(),
                          });

                          setState(() => _isEditing = false);
                          if (context.mounted) {
                            AppDialog.showSuccess(
                              context,
                              title: 'สำเร็จ',
                              message: 'บันทึกการเปลี่ยนแปลงโปรไฟล์เรียบร้อยแล้ว',
                            );
                          }
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'บันทึกการเปลี่ยนแปลง',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/announcements');
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Color(0xFF475569),
                          size: 24,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '1',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: CircleAvatar(
                    radius: 64,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                displayName,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayRole,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                joinDate,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              _buildMenuItem(
                icon: Icons.manage_accounts_outlined,
                title: 'แก้ไขโปรไฟล์',
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (user != null && user.role == 'seller') ...[
                _buildMenuItem(
                  icon: Icons.place_outlined,
                  title: 'จองแผง',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ฟังก์ชันจองแผง กำลังพัฒนา', style: GoogleFonts.outfit()),
                        backgroundColor: const Color(0xFF1E88E5),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.place_outlined,
                  title: 'ประวัติการจอง',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ฟังก์ชันประวัติการจอง กำลังพัฒนา', style: GoogleFonts.outfit()),
                        backgroundColor: const Color(0xFF1E88E5),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.storefront_outlined,
                  title: 'จัดการหน้าร้านค้า',
                  onTap: () async {
                    final tabIndex = await Navigator.pushNamed(context, '/my_shops');
                    if (!context.mounted) return;
                    if (tabIndex != null && tabIndex is int) {
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState.setIndex(tabIndex);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.place_outlined,
                  title: 'แจ้งปัญหา',
                  onTap: () async {
                    final tabIndex = await Navigator.pushNamed(context, '/report_problem');
                    if (!context.mounted) return;
                    if (tabIndex != null && tabIndex is int) {
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState.setIndex(tabIndex);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.history_outlined,
                  title: 'ประวัติการแจ้งปัญหา',
                  onTap: () async {
                    final tabIndex = await Navigator.pushNamed(context, '/problem_history');
                    if (!context.mounted) return;
                    if (tabIndex != null && tabIndex is int) {
                      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState.setIndex(tabIndex);
                      }
                    }
                  },
                ),
              ] else ...[
                _buildMenuItem(
                  icon: Icons.storefront_outlined,
                  title: 'สมัครเป็นผู้ค้า',
                  onTap: () {
                    Navigator.pushNamed(context, '/vendor_register');
                  },
                ),
              ],
              const SizedBox(height: 48),

              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'ยืนยันการออกจากระบบ',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        content: Text(
                          'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบบัญชีผู้ใช้งานนี้?',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        actionsAlignment: MainAxisAlignment.spaceEvenly,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'ยกเลิก',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogContext); // Close dialog
                              await authService.logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            child: Text(
                              'ออกจากระบบ',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ออกจากระบบ',
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1E88E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCBD5E1),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowedTab extends StatefulWidget {
  const _FollowedTab();

  @override
  State<_FollowedTab> createState() => _FollowedTabState();
}

class _FollowedTabState extends State<_FollowedTab> {
  List<Shop> _shops = [];
  bool _isLoading = true;

  // Mock shops matching screenshot
  final List<Map<String, dynamic>> _mockShopsData = [
    {
      'shop_name': 'ร้านชายโขง',
      'rating': 4.3,
      'image_url': 'https://images.unsplash.com/photo-1543007630-9710e4a00a20?w=300',
    },
    {
      'shop_name': 'ร้านผักสด',
      'rating': 4.8,
      'image_url': 'https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?w=300',
    },
    {
      'shop_name': 'PM ผลไม้สด',
      'rating': 3.6,
      'image_url': 'https://images.unsplash.com/photo-1596962248965-533b49751a13?w=300',
    },
    {
      'shop_name': 'น้ำตาลสดแท้',
      'rating': 4.1,
      'image_url': 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=300',
    },
    {
      'shop_name': 'สยาม สโตร์',
      'rating': 4.9,
      'image_url': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=300',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);
    try {
      final data = await ShopService.getShops();
      if (mounted) {
        setState(() {
          _shops = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToShopDetail(Shop shop) async {
    final result = await Navigator.pushNamed(
      context,
      '/shop_detail',
      arguments: {'shop': shop, 'tabIndex': 2},
    );
    if (result != null && result is int && mounted) {
      final homeState = context.findAncestorStateOfType<_HomeScreenState>();
      if (homeState != null) {
        homeState.setIndex(result);
      }
    }
  }

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.4;

    for (int i = 1; i <= 5; i++) {
      if (i <= fullStars) {
        stars.add(const Icon(Icons.star, color: Colors.amber, size: 14));
      } else if (i == fullStars + 1 && hasHalfStar) {
        stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 14));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 14));
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: stars,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate combined data: if API is empty, use mock data
    final displayCount = _shops.isNotEmpty ? _shops.length : _mockShopsData.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadShops,
          color: const Color(0xFF1E88E5),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Same as home)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Image.asset(
                                'assets/home_logo.png',
                                color: Colors.white,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'MarketPlace',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    // Notification bell
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/announcements');
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Color(0xFF475569),
                              size: 24,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '1',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    style: GoogleFonts.outfit(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาตลาด หรือ ร้านค้า...',
                      hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 15),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Followed Shops Section Title
                Text(
                  'ร้านค้าที่คุณติดตาม',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 20),

                // Grid View of Followed Shops
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 24,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: displayCount,
                        itemBuilder: (context, index) {
                          final Shop shop;
                          final double rating;

                          if (_shops.isNotEmpty) {
                            shop = _shops[index];
                            rating = ((shop.shopId ?? index) % 15) / 10 + 3.5;
                          } else {
                            final mock = _mockShopsData[index];
                            shop = Shop(
                              shopId: index + 100, // mock ID
                              shopName: mock['shop_name'],
                              description: 'ร้านค้าคุณภาพสำหรับคุณ',
                              shopImage: mock['image_url'],
                            );
                            rating = mock['rating'];
                          }

                          return GestureDetector(
                            onTap: () => _navigateToShopDetail(shop),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Avatar circular container with double border effect
                                Container(
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: CircleAvatar(
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      backgroundImage: shop.shopImage != null && shop.shopImage!.isNotEmpty
                                          ? (shop.shopImage!.startsWith('http')
                                              ? NetworkImage(shop.shopImage!)
                                              : NetworkImage(ApiService.getImagePath(shop.shopImage)))
                                          : null,
                                      child: shop.shopImage == null || shop.shopImage!.isEmpty
                                          ? const Icon(Icons.storefront, color: Color(0xFF94A3B8), size: 28)
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Shop Name
                                Text(
                                  shop.shopName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                // Rating Stars
                                _buildRatingStars(rating),
                                const SizedBox(height: 4),
                                // Rating value text
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
