import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  static const int _maxInterests = 5;
  List<String> _interests = [];
  bool _isLoadingInterests = true;
  final List<String> _selectedInterests = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();

    _fetchInterestsFromDb();
  }

  void _sortInterestsWithOthersAtEnd(List<String> list) {
    final others = list
        .where((e) => e == 'อื่นๆ' || e.contains('อื่นๆ'))
        .toList();
    final normal = list
        .where((e) => e != 'อื่นๆ' && !e.contains('อื่นๆ'))
        .toList();
    _interests = [...normal, ...others];
  }

  Future<void> _fetchInterestsFromDb() async {
    try {
      final response = await ApiService.get('/v1/user-interests');
      if (response['status'] == true && response['data'] is List) {
        final List<dynamic> list = response['data'] as List<dynamic>;
        if (mounted) {
          setState(() {
            final List<String> items = list
                .where((e) => e != null)
                .map((e) {
                  if (e is Map && e.containsKey('interest_name')) {
                    return e['interest_name']?.toString() ?? '';
                  }
                  if (e is Map && e.containsKey('name')) {
                    return e['name']?.toString() ?? '';
                  }
                  return e.toString();
                })
                .where((e) => e.isNotEmpty)
                .toList();
            _sortInterestsWithOthersAtEnd(items);
            _isLoadingInterests = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load interests from DB: $e');
    }

    if (mounted) {
      setState(() {
        if (_interests.isEmpty) {
          _sortInterestsWithOthersAtEnd([
            'อาหาร',
            'เครื่องดื่ม',
            'ขนม',
            'สตรีทฟู้ด',
            'อื่นๆ',
          ]);
        }
        _isLoadingInterests = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: 'buyer',
      interests: _selectedInterests.join(','),
    );

    if (!mounted) return;

    if (result['status'] == true) {
      AppDialog.showSuccess(
        context,
        title: 'สร้างบัญชีสำเร็จ',
        message: 'บัญชีของคุณพร้อมใช้งานแล้ว ยินดีต้อนรับเข้าสู่ระบบ!',
        onConfirm: () {
          Navigator.pushReplacementNamed(context, '/home');
        },
      );
    } else {
      AppDialog.showError(
        context,
        title: 'สมัครสมาชิกไม่สำเร็จ',
        message: result['message'] ?? 'เกิดข้อผิดพลาดในการลงทะเบียน',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
        title: Text(
          'Sign Up',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'สร้างบัญชีของคุณ',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'เข้าร่วมกับเราเพื่อให้ประสบการณ์การเดินตลาดของคุณดีขึ้น',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Full Name field
                  Text(
                    'ชื่อ-นามสกุล',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _buildInputDecoration(
                      'กรอกชื่อ-นามสกุล',
                      Icons.person_outline,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'กรุณากรอกชื่อ-นามสกุล' : null,
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  Text(
                    'อีเมล',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _buildInputDecoration(
                      'กรอกอีเมล',
                      Icons.mail_outline,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'กรุณากรอกอีเมล';
                      if (!v.contains('@')) return 'อีเมลไม่ถูกต้อง';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  Text(
                    'รหัสผ่าน',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _buildInputDecoration(
                      'กรอกรหัสผ่าน',
                      Icons.lock_outline,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                      if (v.length < 6) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Interest Section Header with Selection Counter Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'คุณสนใจอะไรเป็นพิเศษ',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedInterests.length == _maxInterests
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedInterests.length == _maxInterests
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          'เลือกแล้ว ${_selectedInterests.length}/$_maxInterests',
                          style: GoogleFonts.outfit(
                            color: _selectedInterests.length == _maxInterests
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF475569),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'แตะเพื่อเลือกตามลำดับความสนใจ (1 = สนใจมากที่สุด, สูงสุด $_maxInterests ลำดับ)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interest Chips Wrap with Micro-Animations & Order Badges
                  _isLoadingInterests
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _interests.map((interest) {
                            final isSelected = _selectedInterests.contains(
                              interest,
                            );
                            final int orderIndex = isSelected
                                ? _selectedInterests.indexOf(interest) + 1
                                : 0;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (!isSelected) {
                                    if (_selectedInterests.length >=
                                        _maxInterests) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'เลือกความสนใจได้สูงสุด $_maxInterests อันดับ',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFFDC2626,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    _selectedInterests.add(interest);
                                  } else {
                                    _selectedInterests.remove(interest);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1E88E5)
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2.0 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF1E88E5,
                                            ).withValues(alpha: 0.18),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      Container(
                                        width: 20,
                                        height: 20,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1E88E5),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$orderIndex',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                    Text(
                                      interest,
                                      style: GoogleFonts.outfit(
                                        color: isSelected
                                            ? const Color(0xFF1E88E5)
                                            : const Color(0xFF475569),
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 48),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'มีบัญชีอยู่แล้ว? ',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 14.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'เข้าสู่ระบบ',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1E88E5),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  Consumer<AuthService>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(
                              0xFF1E88E5,
                            ).withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'ถัดไป',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData prefixIcon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(
        color: const Color(0xFF94A3B8),
        fontSize: 15,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
      ),
    );
  }
}
