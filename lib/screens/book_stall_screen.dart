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
  int _selectedDurationMonths = 1; // Can be selected from 1 to 12 months for monthly stalls
  int _selectedDurationDays = 1; // Can be selected from 1 to 5 days for daily stalls
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
  List<Map<String, dynamic>> _bankAccounts = [];
  int _selectedBankIndex = 0;

  Color _getBankColor(String? code) {
    switch (code?.toLowerCase()) {
      case 'kbank':
        return const Color(0xFF137F44);
      case 'scb':
        return const Color(0xFF4E2A84);
      case 'bbl':
        return const Color(0xFF1E3F8A);
      case 'ktb':
        return const Color(0xFF00A6E6);
      case 'bay':
        return const Color(0xFFFEC43B);
      case 'ttb':
        return const Color(0xFF002D63);
      case 'gsb':
        return const Color(0xFFEB1985);
      case 'baac':
        return const Color(0xFF224A25);
      case 'promptpay':
      default:
        return const Color(0xFF003D7C);
    }
  }

  String _getBankShortName(String? code) {
    switch (code?.toLowerCase()) {
      case 'kbank':
        return 'กสิกรไทย';
      case 'scb':
        return 'ไทยพาณิชย์';
      case 'bbl':
        return 'กรุงเทพ';
      case 'ktb':
        return 'กรุงไทย';
      case 'bay':
        return 'กรุงศรี';
      case 'ttb':
        return 'ทีทีบี';
      case 'gsb':
        return 'ออมสิน';
      case 'baac':
        return 'ธ.ก.ส.';
      case 'promptpay':
        return 'พร้อมเพย์';
      default:
        return 'บัญชีธนาคาร';
    }
  }

  String get _selectedBankTitle {
    if (_bankAccounts.isNotEmpty && _selectedBankIndex < _bankAccounts.length) {
      final item = _bankAccounts[_selectedBankIndex];
      return (item['bank_name'] as String?)?.isNotEmpty == true
          ? item['bank_name']!
          : _getBankShortName(item['bank_code']);
    }
    return 'พร้อมเพย์ / ธนาคาร';
  }

  String get _currentBankCode {
    if (_bankAccounts.isNotEmpty && _selectedBankIndex < _bankAccounts.length) {
      return _bankAccounts[_selectedBankIndex]['bank_code'] ?? 'promptpay';
    }
    return 'promptpay';
  }

  String _formatQrUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleaned = path
        .replaceFirst(RegExp(r'^/?storage/'), '')
        .replaceFirst(RegExp(r'^/?api/images/'), '');
    return '${ApiConfig.apiImageUrl}/$cleaned';
  }

  String _formatImageUrl(String path) => _formatQrUrl(path);

  void _openImagePreview(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    padding: const EdgeInsets.all(32),
                    color: const Color(0xFF1E293B),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'ไม่สามารถโหลดรูปภาพได้',
                          style: GoogleFonts.outfit(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSelectBank(int index) {
    if (index >= 0 && index < _bankAccounts.length) {
      setState(() {
        _selectedBankIndex = index;
        final selected = _bankAccounts[index];
        _accountName = selected['account_name'] ?? '';
        _accountNumber = selected['account_number'] ?? '';
        _qrCodeImage = selected['qr_code_path'];
      });
    }
  }

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
        final rawAccounts = data['accounts'];
        List<Map<String, dynamic>> accounts = [];

        if (rawAccounts is List && rawAccounts.isNotEmpty) {
          for (var item in rawAccounts) {
            if (item is Map) {
              final mapItem = Map<String, dynamic>.from(item);
              final isActive = mapItem['is_active'];
              if (isActive == true || isActive == 1 || isActive == '1' || isActive == null) {
                accounts.add(mapItem);
              }
            }
          }
        }

        setState(() {
          if (accounts.isNotEmpty) {
            _bankAccounts = accounts;
            _selectedBankIndex = 0;
            _accountName = _bankAccounts[0]['account_name'] ?? _accountName;
            _accountNumber = _bankAccounts[0]['account_number'] ?? _accountNumber;
            _qrCodeImage = _bankAccounts[0]['qr_code_path'];
          } else {
            if (data['account_name'] != null) {
              _accountName = data['account_name'];
            }
            if (data['account_number'] != null) {
              _accountNumber = data['account_number'];
            }
            if (data['qr_code_path'] != null) {
              _qrCodeImage = data['qr_code_path'];
            }
            _bankAccounts = [
              {
                'bank_code': data['bank_code'] ?? 'promptpay',
                'bank_name': data['bank_name'] ?? 'พร้อมเพย์ (PromptPay)',
                'account_name': _accountName,
                'account_number': _accountNumber,
                'qr_code_path': _qrCodeImage,
              }
            ];
            _selectedBankIndex = 0;
          }
        });
      }
    } catch (_) {
      // fallback defaults
    }
  }

  bool get _isMonthly => _stallItem?.isMonthly ?? false;

  String get _durationLabel => _isMonthly
      ? '$_selectedDurationMonths เดือน'
      : '$_selectedDurationDays วัน';

  /// Calculate safe end date for 1-12 months or 1-5 days duration
  DateTime get _endDate {
    if (_isMonthly) {
      final year = _startDate.year;
      final month = _startDate.month + _selectedDurationMonths;
      final day = _startDate.day;
      int targetYear = year + (month - 1) ~/ 12;
      int targetMonth = (month - 1) % 12 + 1;
      int maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
      int targetDay = day > maxDays ? maxDays : day;
      return DateTime(targetYear, targetMonth, targetDay);
    } else {
      return _startDate.add(Duration(days: _selectedDurationDays - 1));
    }
  }

  // Correct price fields from DB
  double get _rentalRate => _isMonthly
      ? (_stallItem?.monthlyPrice ?? _stallItem?.price ?? 5000)
      : (_stallItem?.dailyPrice ?? _stallItem?.price ?? 500);
  double get _rentTotal => _isMonthly
      ? (_rentalRate * _selectedDurationMonths)
      : (_rentalRate * _selectedDurationDays);
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

    if (_slipBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'กรุณาแนบหลักฐานการโอนเงิน (สลิปโอนเงิน) ก่อนทำรายการจอง',
                  style: GoogleFonts.outfit(),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEA580C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              'destination_bank': _selectedBankTitle,
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
                      _durationLabel,
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
          if (item.hasImages) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final imgUrl = _formatImageUrl(item.images[index]);
                  return GestureDetector(
                    onTap: () => _openImagePreview(
                      context,
                      imgUrl,
                      'รูปแผงค้า ${item.stallNum} (รูปที่ ${index + 1})',
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.network(
                            imgUrl,
                            width: item.images.length == 1 ? 260 : 180,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 150,
                              height: 120,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fullscreen, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ดูรูปขยาย',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'รูปที่ ${index + 1}',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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

          // Facilities & Highlights Badges (Dynamic from Database / Stall Settings)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _stallFeatureBadge(
                _stallItem?.hasElectricity ?? true ? Icons.bolt_rounded : Icons.power_off_outlined,
                _stallItem?.hasElectricity ?? true ? 'ไฟฟ้าพร้อมใช้' : 'ไม่มีไฟฟ้า',
                isAvailable: _stallItem?.hasElectricity ?? true,
                badgeColor: const Color(0xFFD97706),
              ),
              _stallFeatureBadge(
                _stallItem?.hasWater ?? true ? Icons.water_drop_rounded : Icons.opacity_outlined,
                _stallItem?.hasWater ?? true ? 'น้ำประปา' : 'ไม่มีน้ำประปา',
                isAvailable: _stallItem?.hasWater ?? true,
                badgeColor: const Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stallFeatureBadge(
    IconData icon,
    String label, {
    bool isAvailable = true,
    Color badgeColor = const Color(0xFF475569),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAvailable ? badgeColor.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? badgeColor.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isAvailable ? badgeColor : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: isAvailable ? badgeColor : const Color(0xFF94A3B8),
              fontWeight: isAvailable ? FontWeight.w600 : FontWeight.w500,
              decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
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
    final bool isMonthly = _isMonthly;
    final int maxDuration = isMonthly ? 12 : 5;
    final int currentDuration =
        isMonthly ? _selectedDurationMonths : _selectedDurationDays;

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
                child: Icon(
                  isMonthly ? Icons.calendar_month_outlined : Icons.today_outlined,
                  color: const Color(0xFF2563EB),
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
                isMonthly
                    ? 'เลื่อนเลือกจำนวนเดือน (1 - 12 เดือน)'
                    : 'เลือกจำนวนวันเช่า (1 - 5 วัน)',
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
                  isMonthly
                      ? '$_selectedDurationMonths เดือน${_selectedDurationMonths == 12 ? ' (1 ปี)' : _selectedDurationMonths == 6 ? ' (ครึ่งปี)' : ''}'
                      : '$_selectedDurationDays วัน',
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
                      color: currentDuration > 1
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      iconSize: 24,
                      onPressed: currentDuration > 1
                          ? () {
                              setState(() {
                                if (isMonthly) {
                                  _selectedDurationMonths--;
                                } else {
                                  _selectedDurationDays--;
                                }
                              });
                            }
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
                          value: currentDuration.toDouble(),
                          min: 1.0,
                          max: maxDuration.toDouble(),
                          divisions: isMonthly ? 11 : 4,
                          label: isMonthly
                              ? '$_selectedDurationMonths เดือน'
                              : '$_selectedDurationDays วัน',
                          onChanged: (val) {
                            setState(() {
                              if (isMonthly) {
                                _selectedDurationMonths = val.round();
                              } else {
                                _selectedDurationDays = val.round();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    // Stepper (+)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: currentDuration < maxDuration
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                      iconSize: 24,
                      onPressed: currentDuration < maxDuration
                          ? () {
                              setState(() {
                                if (isMonthly) {
                                  _selectedDurationMonths++;
                                } else {
                                  _selectedDurationDays++;
                                }
                              });
                            }
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
                    children: isMonthly
                        ? [
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
                          ]
                        : [
                            Text(
                              '1 วัน',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '3 วัน',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '5 วัน (สูงสุด)',
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

          // Quick preset buttons for fast shortcut selection
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: (isMonthly ? [1, 3, 6, 12] : [1, 2, 3, 4, 5]).map((val) {
                final isSel = currentDuration == val;
                String label = isMonthly ? '$val เดือน' : '$val วัน';
                if (isMonthly && val == 12) label = '12 เดือน (1 ปี)';
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
                        setState(() {
                          if (isMonthly) {
                            _selectedDurationMonths = val;
                          } else {
                            _selectedDurationDays = val;
                          }
                        });
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
                  Icons.info_outline,
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
                : 'ค่าเช่า (฿${_formatCurrency(_rentalRate)}/วัน × $_selectedDurationDays วัน)',
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

          // Bank Selector Carousel / Chips (if multiple accounts available)
          if (_bankAccounts.length > 1) ...[
            Text(
              'เลือกบัญชีธนาคารปลายทางที่ต้องการโอน:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _bankAccounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final bank = _bankAccounts[idx];
                  final isSelected = _selectedBankIndex == idx;
                  final code = bank['bank_code'] as String?;
                  final bankColor = _getBankColor(code);
                  final shortName = _getBankShortName(code);

                  return InkWell(
                    onTap: () => _onSelectBank(idx),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? bankColor : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? bankColor : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: bankColor.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : bankColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            shortName,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

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
                      decoration: BoxDecoration(
                        color: _getBankColor(_currentBankCode),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getBankColor(_currentBankCode)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _selectedBankTitle,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getBankColor(_currentBankCode),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
                    'สแกน QR Code สำหรับ $_selectedBankTitle',
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
                      _formatQrUrl(_qrCodeImage!),
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
                  'ยอดชำระสุทธิ ($_durationLabel)',
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
