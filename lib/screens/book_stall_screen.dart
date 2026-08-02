import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/market_map_item.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';

class BookStallScreen extends StatefulWidget {
  const BookStallScreen({super.key});

  @override
  State<BookStallScreen> createState() => _BookStallScreenState();
}

class _BookStallScreenState extends State<BookStallScreen> {
  MarketMapItem? _stallItem;

  DateTime _startDate = DateTime.now();
  int _selectedDurationMonths = 1; // Can be selected from 1 to 12 months
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  Uint8List? _slipBytes;
  String? _slipFileName;

  bool _agreeTerms = false;
  bool _isSubmitting = false;

  // Payment account details fetched from backend or default
  String _accountName = 'บัญชีตลาดนัดรอบเย็น';
  String _accountNumber = '123-4-56789-0 (กสิกรไทย)';
  String? _qrCodeImage;

  @override
  void initState() {
    super.initState();
    _fetchPaymentSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stallItem == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['stall'] != null) {
        _stallItem = args['stall'] as MarketMapItem;
      }
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user?.phone != null && user!.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchPaymentSettings() async {
    try {
      var res = await ApiService.get('/admin/market-payment-settings');
      if (res['status'] != true || res['data'] == null) {
        res = await ApiService.get('/v1/admin/market-payment-settings');
      }
      if (res['status'] == true && res['data'] != null) {
        final data = res['data'];
        setState(() {
          if (data['account_name'] != null) {
            _accountName = data['account_name'];
          }
          if (data['account_number'] != null) {
            _accountNumber = data['account_number'];
          }
          if (data['qr_code_path'] != null) {
            _qrCodeImage = data['qr_code_path'];
          }
        });
      }
    } catch (_) {
      // fallback defaults
    }
  }

  /// Calculate safe end date for 1-12 months duration without day overflow bugs
  DateTime get _endDate {
    final year = _startDate.year;
    final month = _startDate.month + _selectedDurationMonths;
    final day = _startDate.day;
    int targetYear = year + (month - 1) ~/ 12;
    int targetMonth = (month - 1) % 12 + 1;
    int maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
    int targetDay = day > maxDays ? maxDays : day;
    return DateTime(targetYear, targetMonth, targetDay);
  }

  // Correct price fields from DB
  bool get _isMonthly => _stallItem?.isMonthly ?? false;
  double get _rentalRate => _isMonthly
      ? (_stallItem?.monthlyPrice ?? _stallItem?.price ?? 5000)
      : (_stallItem?.dailyPrice ?? _stallItem?.price ?? 500);
  double get _rentTotal => _rentalRate * _selectedDurationMonths;
  double get _entryFeeAmount => _isMonthly ? (_stallItem?.entryFee ?? 0) : 0;
  double get _securityDepositAmount => _isMonthly ? (_stallItem?.securityDeposit ?? 0) : 0;
  double get _grandTotal => _rentTotal + _entryFeeAmount + _securityDepositAmount;

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year + 543}';
  }

  String _toIsoDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    final str = amount.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickSlipFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _slipBytes = file.bytes;
            _slipFileName = file.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เลือกไฟล์สลิปไม่สำเร็จ: $e',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('คัดลอก $label เรียบร้อยแล้ว', style: GoogleFonts.outfit()),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitBooking() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final UserModel? currentUser = authService.currentUser;

    if (currentUser == null || currentUser.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาล็อกอินก่อนทำรายการจอง',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_stallItem == null || _stallItem!.stallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่พบข้อมูลแผงค้าที่เลือก',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณากดยอมรับข้อตกลงและเงื่อนไขการเช่าก่อนทำรายการ',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Create booking in backend
      final bookingRes = await BookingService.createBooking(
        userId: currentUser.userId!,
        stallId: _stallItem!.stallId!,
        startDate: _toIsoDate(_startDate),
        endDate: _toIsoDate(_endDate),
        rentalType: _stallItem!.rentalType,
        dailyPrice: _stallItem!.dailyPrice,
        monthlyPrice: _stallItem!.monthlyPrice,
        entryFee: _stallItem!.entryFee,
        securityDeposit: _stallItem!.securityDeposit,
        totalAmount: _grandTotal,
      );

      if (bookingRes['status'] == true) {
        final bookingData = bookingRes['data'];
        final bookingId = bookingData != null
            ? bookingData['booking_id']
            : null;

        // 2. Upload payment slip if provided
        if (bookingId != null && _slipBytes != null) {
          try {
            final fields = {
              'booking_id': bookingId.toString(),
              'amount': _grandTotal.toString(),
              'payment_date': DateTime.now().toIso8601String(),
              'payment_slip': _slipFileName ?? 'slip.png',
              'status': 'pending',
            };
            await ApiService.postMultipart(
              '/v1/payments',
              fields,
              fileKey: 'payment_slip_file',
              fileBytes: _slipBytes,
              fileName: _slipFileName ?? 'slip.png',
            );
          } catch (_) {
            // payment upload optional retry
          }
        }

        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          setState(() => _isSubmitting = false);
          final msg = bookingRes['message'] ?? 'เกิดข้อผิดพลาดในการจอง';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('จองไม่สำเร็จ: $msg', style: GoogleFonts.outfit()),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF16A34A),
                  size: 56,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ส่งรายการจองสำเร็จ!',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'รายการจองแผงค้า ${_stallItem?.label ?? ''} ของคุณถูกส่งไปยังเจ้าหน้าที่เรียบร้อยแล้ว',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _dialogSummaryRow('แผงค้า', _stallItem?.label ?? '-'),
                    const SizedBox(height: 8),
                    _dialogSummaryRow(
                      'ระยะเวลาเช่า',
                      '$_selectedDurationMonths เดือน',
                    ),
                    const SizedBox(height: 8),
                    _dialogSummaryRow('เริ่มสัญญา', _formatDate(_startDate)),
                    const SizedBox(height: 8),
                    _dialogSummaryRow('สิ้นสุดสัญญา', _formatDate(_endDate)),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 4),
                    _dialogSummaryRow(
                      'ยอดสุทธิที่ชำระ',
                      '฿${_formatCurrency(_grandTotal)}',
                      isBold: true,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context, true); // return to map with true
                  },
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
                    'ตกลงและกลับสู่หน้าหลัก',
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
    );
  }

  Widget _dialogSummaryRow(
    String label,
    String val, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final item = _stallItem;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF0F172A),
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'จองแผงค้า',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (item != null)
              Text(
                'แผง ${item.label}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2563EB),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: item == null
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Stall Info Detailed Card
                          _buildStallCard(item),
                          const SizedBox(height: 20),

                          // 2. User Info Card
                          _buildUserCard(user),
                          const SizedBox(height: 20),

                          // 3. Rental Duration Selector Card (1-12 Months)
                          _buildDurationCard(),
                          const SizedBox(height: 20),

                          // 4. Cost Breakdown Card
                          _buildCostCard(),
                          const SizedBox(height: 20),

                          // 5. Payment Slip Uploader Card
                          _buildPaymentCard(),
                          const SizedBox(height: 20),

                          // 6. Terms & Condition Checkbox
                          _buildTermsCard(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // 7. Sticky Bottom Action Bar
                  _buildBottomActionBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildStallCard(MarketMapItem item) {
    final bool monthly = item.isMonthly;
    final double displayRate = monthly
        ? (item.monthlyPrice ?? item.price)
        : (item.dailyPrice ?? item.price);
    final double dailyEstimateVal = monthly ? (displayRate / 30) : displayRate;
    final String dailyEstimate = dailyEstimateVal.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Color(0xFF2563EB),
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'แผงค้า ${item.label}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ว่างพร้อมจอง',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.straighten,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ขนาด ${item.size}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),

          // Detailed Spec Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthly ? 'ค่าเช่ารายเดือน' : 'ค่าเช่ารายวัน',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '฿${_formatCurrency(displayRate)}',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          Text(
                            monthly ? ' /เดือน' : ' /วัน',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        monthly ? 'เฉลี่ย ~฿$dailyEstimate/วัน' : 'ต่อ 1 วันเช่า',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthly ? 'ค่าแรกเข้า + เงินประกัน' : 'ค่ามัดจำ',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthly
                            ? '฿${_formatCurrency((item.entryFee ?? 0) + (item.securityDeposit ?? 0))}'
                            : '฿0',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        monthly ? '*เงินประกันคืนเมื่อหมดสัญญา' : 'ไม่มีค่ามัดจำรายวัน',
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          color: monthly ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Facilities & Highlights Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _stallFeatureBadge(Icons.bolt, 'ฟรีจุดไฟ'),
              _stallFeatureBadge(Icons.water_drop, 'ฟรีจุดน้ำ'),
              _stallFeatureBadge(Icons.shield_outlined, 'รปภ. 24 ชม.'),
              _stallFeatureBadge(
                Icons.cleaning_services_outlined,
                'บริการเก็บขยะ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stallFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ข้อมูลผู้จองแผงค้า',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRowItem('ชื่อ-นามสกุล ผู้จอง', user?.username ?? 'ไม่ระบุ'),
          const SizedBox(height: 8),
          _infoRowItem('อีเมลสำหรับรับสัญญา', user?.email ?? '-'),
          const SizedBox(height: 14),
          Text(
            'เบอร์โทรศัพท์ติดต่อ *',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'กรอกเบอร์โทรศัพท์สำหรับติดต่อ',
              prefixIcon: const Icon(
                Icons.phone_outlined,
                size: 18,
                color: Color(0xFF64748B),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ระยะเวลาการเช่า / สัญญาเช่า',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Start Date Selector Button
          GestureDetector(
            onTap: _selectStartDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วันเริ่มสัญญาเช่า',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(_startDate),
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'เปลี่ยนวันที่',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Header for Duration Slider & Active Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เลื่อนเลือกจำนวนเดือน (1 - 12 เดือน)',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              // Highlight Badge showing current selection
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$_selectedDurationMonths เดือน${_selectedDurationMonths == 12
                      ? ' (1 ปี)'
                      : _selectedDurationMonths == 6
                      ? ' (ครึ่งปี)'
                      : ''}',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Slider Bar (หลอดเลื่อน)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Stepper (-)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: _selectedDurationMonths > 1
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      iconSize: 24,
                      onPressed: _selectedDurationMonths > 1
                          ? () => setState(() => _selectedDurationMonths--)
                          : null,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 8,
                          activeTrackColor: const Color(0xFF2563EB),
                          inactiveTrackColor: const Color(0xFFE2E8F0),
                          thumbColor: const Color(0xFF2563EB),
                          overlayColor: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.15),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 11,
                            elevation: 3,
                          ),
                          tickMarkShape: const RoundSliderTickMarkShape(
                            tickMarkRadius: 3,
                          ),
                          activeTickMarkColor: Colors.white.withValues(
                            alpha: 0.7,
                          ),
                          inactiveTickMarkColor: const Color(0xFFCBD5E1),
                        ),
                        child: Slider(
                          value: _selectedDurationMonths.toDouble(),
                          min: 1.0,
                          max: 12.0,
                          divisions: 11,
                          label: '$_selectedDurationMonths เดือน',
                          onChanged: (val) {
                            setState(() {
                              _selectedDurationMonths = val.round();
                            });
                          },
                        ),
                      ),
                    ),
                    // Stepper (+)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: _selectedDurationMonths < 12
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      iconSize: 24,
                      onPressed: _selectedDurationMonths < 12
                          ? () => setState(() => _selectedDurationMonths++)
                          : null,
                    ),
                  ],
                ),
                // Min / Max labels & Markers
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 เดือน',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '6 เดือน',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '12 เดือน (1 ปี)',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Quick preset buttons (1, 3, 6, 12 เดือน) for fast shortcut selection
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1, 3, 6, 12].map((m) {
                final isSel = _selectedDurationMonths == m;
                String label = '$m เดือน';
                if (m == 12) label = '12 เดือน (1 ปี)';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSel,
                    selectedColor: const Color(0xFFEFF6FF),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSel
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                    ),
                    labelStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF475569),
                    ),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDurationMonths = m);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // End Date Auto Display Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วันสิ้นสุดสัญญาเช่า (รวม $_selectedDurationMonths เดือน)',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(_endDate),
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_selectedDurationMonths/12 เดือน',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
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

  Widget _buildCostCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'สรุปรายการค่าใช้จ่าย',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _costRow(
            _isMonthly
                ? 'ค่าเช่า (฿${_formatCurrency(_rentalRate)}/เดือน × $_selectedDurationMonths เดือน)'
                : 'ค่าเช่า (฿${_formatCurrency(_rentalRate)}/วัน)',
            '฿${_formatCurrency(_rentTotal)}',
          ),
          if (_isMonthly && _entryFeeAmount > 0) ...[
            const SizedBox(height: 10),
            _costRow(
              'ค่าแรกเข้า',
              '฿${_formatCurrency(_entryFeeAmount)}',
            ),
          ],
          if (_isMonthly && _securityDepositAmount > 0) ...[
            const SizedBox(height: 10),
            _costRow(
              'เงินประกัน',
              '฿${_formatCurrency(_securityDepositAmount)}',
              subtitle: '* คืนเมื่อครบสัญญาเช่า',
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ยอดชำระรวมสุทธิ',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    _isMonthly ? 'ค่าเช่า + ค่าแรกเข้า + เงินประกัน' : 'ค่าเช่ารายวัน',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Text(
                '฿${_formatCurrency(_grandTotal)}',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, String amount, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            Text(
              amount,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ช่องทางชำระเงิน & แนบสลิป',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bank Info Box with Copy button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _accountName,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'เลขบัญชี: $_accountNumber',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _copyToClipboard(_accountNumber, 'เลขบัญชีธนาคาร'),
                    icon: const Icon(Icons.copy, size: 14),
                    label: Text(
                      'คัดลอกเลขบัญชี',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color(0xFFEFF6FF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_qrCodeImage != null && _qrCodeImage!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    'สแกน QR Code เพื่อชำระเงิน',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${ApiConfig.apiImageUrl}/$_qrCodeImage',
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),
          Text(
            'แนบหลักฐานการโอนเงิน (สลิปโอนเงิน)',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),

          // Uploader Area
          GestureDetector(
            onTap: _pickSlipFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _slipBytes != null
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _slipBytes != null
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFCBD5E1),
                  width: _slipBytes != null ? 1.5 : 1.0,
                ),
              ),
              child: _slipBytes != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _slipBytes!,
                            height: 170,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF16A34A),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _slipFileName ?? 'สลิปโอนเงิน.png',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A8A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _slipBytes = null;
                                  _slipFileName = null;
                                });
                              },
                              child: Text(
                                'เปลี่ยนสลิป',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'แตะเพื่อเลือกไฟล์สลิปชำระเงิน',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'รองรับไฟล์รูปภาพ JPG, PNG (ไม่เกิน 5MB)',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard() {
    return GestureDetector(
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _agreeTerms
              ? const Color(0xFFEFF6FF)
              : const Color(
                  0xFFFFF7ED,
                ), // Soft amber/warm tint when unchecked, blue tint when checked
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _agreeTerms
                ? const Color(0xFF2563EB)
                : const Color(
                    0xFFFDBA74,
                  ), // Orange border when unchecked, Blue when checked
            width: _agreeTerms ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _agreeTerms
                  ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Custom Prominent Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _agreeTerms ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _agreeTerms
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF97316),
                  width: 2,
                ),
              ),
              child: _agreeTerms
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _agreeTerms
                            ? Icons.verified_user
                            : Icons.gavel_outlined,
                        size: 16,
                        color: _agreeTerms
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ข้อตกลงและเงื่อนไขการเช่า *',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _agreeTerms
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ฉันได้อ่านและยอมรับข้อตกลงและเงื่อนไขการเช่าแผงค้าของตลาด รวมถึงยินยอมปฏิบัติตามกฎระเบียบของตลาดทุกประการ',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: _agreeTerms
                          ? const Color(0xFF1E40AF)
                          : const Color(0xFF475569),
                      height: 1.35,
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

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ยอดชำระสุทธิ ($_selectedDurationMonths เดือน)',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '฿${_formatCurrency(_grandTotal)}',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFF93C5FD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ยืนยันการจองแผง',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
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
      ),
    );
  }

  Widget _infoRowItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
