import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/app_dialog.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  State<VendorRegistrationScreen> createState() =>
      _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _citizenIdController = TextEditingController();
  final _addressController = TextEditingController();
  String? _uploadedFileName;
  Uint8List? _uploadedFileBytes;
  String? _uploadedFilePath;
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Fetch latest user details from server to ensure all fields are populated
      await auth.fetchUserProfile();
      final user = auth.currentUser;
      if (mounted) {
        if (user != null) {
          if (user.username.isNotEmpty) {
            _fullNameController.text = user.username;
          }
          if (user.phone != null && user.phone!.isNotEmpty) {
            _phoneController.text = user.phone!;
          }
          if (user.citizenId != null && user.citizenId!.isNotEmpty) {
            _citizenIdController.text = user.citizenId!;
          }
          if (user.address != null && user.address!.isNotEmpty) {
            _addressController.text = user.address!;
          }
          if (user.documentImage != null && user.documentImage!.isNotEmpty) {
            _uploadedFileName = user.documentImage;
          }
        }
        setState(() {
          _isLoadingUser = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _citizenIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickFileWithFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _uploadedFileName = file.name;
          _uploadedFileBytes = file.bytes;
          _uploadedFilePath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถเลือกไฟล์ได้: $e',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _uploadedFileName = image.name;
          _uploadedFileBytes = bytes;
          _uploadedFilePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถเลือกรูปภาพได้: $e',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _pickWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _uploadedFileName = image.name;
          _uploadedFileBytes = bytes;
          _uploadedFilePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถเปิดกล้องได้: $e',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _onUploadPressed() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'เลือกวิธีการอัปโหลดเอกสาร',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF1E88E5),
                ),
                title: Text(
                  'เลือกจากคลังรูปภาพ (Gallery)',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'เลือกรูปถ่ายสำเนาบัตรประชาชนจากแกลเลอรีรูปภาพ',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.folder_open,
                  color: Color(0xFF1E88E5),
                ),
                title: Text(
                  'เลือกไฟล์รูปภาพ / เอกสารจากอุปกรณ์ (Files)',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'รองรับไฟล์ JPG, PNG, PDF จากคลังของคุณ',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFileWithFilePicker();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1E88E5)),
                title: Text('ถ่ายรูปด้วยกล้อง (Camera)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'เปิดกล้องเพื่อถ่ายรูปสำเนาบัตรประชาชนทันที',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickWithCamera();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitData() async {
    final fullName = _fullNameController.text.trim();
    final citizenId = _citizenIdController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (fullName.isEmpty) {
      AppDialog.showError(
        context,
        title: 'ข้อผิดพลาด',
        message: 'กรุณากรอกชื่อจริง-นามสกุลจริงตามสำเนาบัตรประชาชน',
      );
      return;
    }
    if (citizenId.isEmpty) {
      AppDialog.showError(
        context,
        title: 'ข้อผิดพลาด',
        message: 'กรุณากรอกเลขบัตรประชาชน',
      );
      return;
    }
    if (citizenId.length != 13 || !RegExp(r'^[0-9]{13}$').hasMatch(citizenId)) {
      AppDialog.showError(
        context,
        title: 'ข้อผิดพลาด',
        message: 'เลขบัตรประชาชนต้องมี 13 หลักเป็นตัวเลขเท่านั้น',
      );
      return;
    }
    if (_uploadedFileName == null) {
      AppDialog.showError(
        context,
        title: 'ข้อผิดพลาด',
        message: 'กรุณาอัปโหลดรูปถ่ายสำเนาบัตรประชาชน (พร้อมเซ็นสำเนาถูกต้อง)',
      );
      return;
    }
    if (address.isEmpty) {
      AppDialog.showError(
        context,
        title: 'ข้อผิดพลาด',
        message: 'กรุณากรอกที่อยู่ปัจจุบันของคุณ',
      );
      return;
    }

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
      ),
    );

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final payload = <String, dynamic>{
        'role': 'buyer',
        'document_status': 'pending',
        'submission_date': DateTime.now().toIso8601String(),
        'username': fullName,
        'citizen_id': citizenId,
        'address': address,
      };
      if (phone.isNotEmpty) {
        payload['phone'] = phone;
      }
      if (_uploadedFileBytes == null && _uploadedFileName != null) {
        payload['document_image'] = _uploadedFileName;
      }
      final response = await authService.updateProfile(
        payload,
        fileKey: 'document_image_file',
        filePath: _uploadedFilePath,
        fileBytes: _uploadedFileBytes,
        fileName: _uploadedFileName,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (response['status'] == true) {
        // Refresh user profile from server so currentUser contains fresh submission data
        await authService.fetchUserProfile();
        if (mounted) {
          AppDialog.showSuccess(
            context,
            title: 'ส่งข้อมูลสำเร็จ',
            message: 'ส่งใบสมัครเป็นผู้ค้าเรียบร้อยแล้ว กรุณารอการตรวจสอบและอนุมัติจากผู้ดูแลระบบ',
            onConfirm: () {
              if (mounted) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              }
            },
          );
        }
      } else {
        if (mounted) {
          AppDialog.showError(
            context,
            title: 'เกิดข้อผิดพลาด',
            message: response['message'] ?? 'ไม่สามารถอัปเดตข้อมูลได้ในขณะนี้',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        AppDialog.showError(
          context,
          title: 'เกิดข้อผิดพลาด',
          message: e.toString(),
        );
      }
    }
  }

  String _formatThaiDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ];
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.day} ${months[date.month - 1]} ${date.year + 543} เวลา $hour:$minute น.';
    } catch (_) {
      return dateStr;
    }
  }

  void _viewFullScreenImage(String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('ไม่สามารถโหลดรูปภาพได้', style: GoogleFonts.outfit()),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelApplication() async {
    AppDialog.showConfirm(
      context,
      title: 'ยกเลิกคำขอสมัครเป็นผู้ค้า',
      message:
          'คุณต้องการยกเลิกคำขอสมัครเป็นผู้ค้าและลบใบสมัครนี้ใช่หรือไม่?\nข้อมูลและเอกสารสำเนาที่เคยส่งไปจะถูกลบออกจากระบบ',
      confirmText: 'ยกเลิกคำขอสมัคร',
      cancelText: 'ย้อนกลับ',
      onConfirm: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFDC2626)),
          ),
        );

        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          final response = await authService.cancelVendorApplication();

          if (mounted) {
            Navigator.pop(context); // Close loading dialog
          }

          if (response['status'] == true) {
            if (mounted) {
              setState(() {
                _citizenIdController.clear();
                _addressController.clear();
                _uploadedFileName = null;
                _uploadedFileBytes = null;
                _uploadedFilePath = null;
              });
              AppDialog.showSuccess(
                context,
                title: 'ยกเลิกคำขอสำเร็จ',
                message: 'ยกเลิกคำขอสมัครเป็นผู้ค้าและลบข้อมูลเอกสารเรียบร้อยแล้ว',
                onConfirm: () {
                  if (mounted) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  }
                },
              );
            }
          } else {
            if (mounted) {
              AppDialog.showError(
                context,
                title: 'เกิดข้อผิดพลาด',
                message: response['message'] ?? 'ไม่สามารถยกเลิกคำขอได้ในขณะนี้',
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context);
            AppDialog.showError(
              context,
              title: 'เกิดข้อผิดพลาด',
              message: e.toString(),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

    if (_isLoadingUser) {
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
          title: Text(
            'สมัครเป็นผู้ค้า',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
        ),
      );
    }

    final bool hasPendingApplication = user != null &&
        user.documentStatus == 'pending' &&
        (user.submissionDate != null ||
            user.documentImage != null ||
            (user.citizenId != null && user.citizenId!.isNotEmpty));

    final bool canCancel = hasPendingApplication ||
        (user != null &&
            (user.documentStatus == 'rejected' ||
                user.submissionDate != null ||
                user.documentImage != null ||
                (user.citizenId != null && user.citizenId!.isNotEmpty)));

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
        title: Text(
          hasPendingApplication ? 'ตรวจสอบใบสมัครผู้ค้า' : 'สมัครเป็นผู้ค้า',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สมัครเป็นผู้ค้า',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasPendingApplication
                    ? 'ตรวจสอบข้อมูลที่คุณยื่นสมัครไว้ด้านล่างนี้'
                    : 'กรุณากรอกข้อมูลส่วนตัวของคุณเพื่อเริ่มต้นการใช้งาน',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (hasPendingApplication) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.hourglass_top_rounded,
                              color: Color(0xFFD97706),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'อยู่ระหว่างรอการตรวจสอบและอนุมัติ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                                if (user.submissionDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'ยื่นเรื่องเมื่อ: ${_formatThaiDateTime(user.submissionDate)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ข้อมูลและเอกสารที่คุณเคยส่งถูกนำมาแสดงในแบบฟอร์มด้านล่างแล้ว เพื่อให้คุณตรวจสอบความถูกต้อง หากต้องการเปลี่ยนแปลงสามารถพิมพ์แก้ไขข้อมูลและกดบันทึกส่งใหม่ได้',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: const Color(0xFF78350F),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (user?.documentStatus == 'rejected') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'คำขอสมัครเป็นผู้ค้าก่อนหน้านี้ไม่ผ่านการอนุมัติ',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                      if (user?.rejectReason != null && user!.rejectReason!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'เหตุผล: ${user.rejectReason}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFFB91C1C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'กรุณาตรวจสอบความถูกต้องของข้อมูลและสำเนาบัตรประชาชน แล้วกดยื่นเรื่องใหม่อีกครั้ง',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF7F1D1D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              Text(
                'ชื่อจริง-นามสกุลจริง (ตามสำเนาบัตรประชาชน)',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF334155),
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
                  controller: _fullNameController,
                  style: GoogleFonts.outfit(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'ระบุชื่อ-นามสกุลตามสำเนาบัตรประชาชน',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'เบอร์โทรศัพท์ (ไม่บังคับ มีไว้ติดต่อในกรณีมีปัญหา)',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF334155),
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
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.outfit(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'เช่น 0812345678',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'เลขประจำตัวประชาชน (ตามสำเนาบัตรประชาชน)',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF334155),
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
                  controller: _citizenIdController,
                  keyboardType: TextInputType.number,
                  maxLength: 13,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.outfit(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'ระบุเลขบัตรประชาชน 13 หลัก',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'รูปถ่ายสำเนาบัตรประชาชน (พร้อมเซ็นสำเนาถูกต้อง)',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _onUploadPressed,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _uploadedFileName != null
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFFCBD5E1),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_uploadedFileBytes != null &&
                          (_uploadedFileName?.endsWith('.pdf') != true)) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _uploadedFileBytes!,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else if (_uploadedFileBytes == null &&
                          _uploadedFileName != null &&
                          _uploadedFileName!.isNotEmpty &&
                          !_uploadedFileName!.endsWith('.pdf')) ...[
                        GestureDetector(
                          onTap: () {
                            _viewFullScreenImage(
                              ApiService.getImagePath(_uploadedFileName),
                            );
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  ApiService.getImagePath(_uploadedFileName),
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'แตะเพื่อดูรูปเต็ม',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _uploadedFileName != null
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _uploadedFileName != null
                                ? Icons.check
                                : Icons.cloud_upload_outlined,
                            color: _uploadedFileName != null
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF1E88E5),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        _uploadedFileName != null
                            ? (_uploadedFileBytes != null
                                ? 'เลือกไฟล์ใหม่เรียบร้อยแล้ว'
                                : 'สำเนาบัตรประชาชนที่เคยส่งไว้')
                            : 'คลิกเพื่ออัปโหลดสำเนาบัตรประชาชน',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _uploadedFileName != null
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _uploadedFileName != null
                            ? (_uploadedFileBytes != null
                                ? _uploadedFileName!
                                : 'แตะที่นี่เพื่อเปลี่ยนรูปถ่ายสำเนาบัตรประชาชน')
                            : 'PNG, JPG หรือ PDF (สูงสุด 5MB)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'คำแนะนำเพื่อความปลอดภัย (PDPA): กรุณาใช้สำเนาบัตรประชาชน ขีดคร่อมเขียนข้อความ "สำเนาถูกต้อง ใช้สำหรับสมัครเป็นผู้ค้าตลาดเท่านั้น" พร้อมลงลายมือชื่อกำกับ',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'ที่อยู่ปัจจุบัน',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF334155),
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
                  controller: _addressController,
                  maxLines: 3,
                  style: GoogleFonts.outfit(color: Colors.black),
                  decoration: InputDecoration(
                    hintText:
                        'เลขที่บ้าน, ถนน, แขวง/ตำบล, เขต/อำเภอ, จังหวัด, รหัสไปรษณีย์',
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasPendingApplication
                            ? 'บันทึกและส่งข้อมูลแก้ไข'
                            : (user?.documentStatus == 'rejected'
                                ? 'ยื่นคำขอสมัครใหม่อีกครั้ง'
                                : 'ส่งข้อมูล'),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              if (canCancel) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _cancelApplication,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Color(0xFFDC2626),
                    ),
                    label: Text(
                      'ยกเลิกคำขอสมัครเป็นผู้ค้า (ลบใบสมัคร)',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
