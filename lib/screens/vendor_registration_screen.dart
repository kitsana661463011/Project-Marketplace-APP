import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/app_dialog.dart';
import '../services/auth_service.dart';

class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  State<VendorRegistrationScreen> createState() => _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _uploadedFileName;
  Uint8List? _uploadedFileBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickFileWithFilePicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _uploadedFileName = file.name;
          _uploadedFileBytes = file.bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกไฟล์ได้: $e', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _pickWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _uploadedFileName = image.name;
          _uploadedFileBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิดกล้องได้: $e', style: GoogleFonts.outfit()),
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
                leading: const Icon(Icons.folder_open, color: Color(0xFF1E88E5)),
                title: Text('เลือกไฟล์รูปภาพ / เอกสารจากอุปกรณ์', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                subtitle: Text('รองรับไฟล์ JPG, PNG, PDF จากคลังของคุณ', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(context);
                  _pickFileWithFilePicker();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1E88E5)),
                title: Text('ถ่ายรูปด้วยกล้อง', style: GoogleFonts.outfit()),
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
    if (_fullNameController.text.trim().isEmpty) {
      AppDialog.showError(
        context,
        title: 'ข้อผิดพลาด',
        message: 'กรุณากรอกชื่อจริง-นามสกุลจริงตามบัตรประชาชน',
      );
      return;
    }
    if (_uploadedFileName == null) {
      AppDialog.showError(
        context,
        title: 'ข้อผิดพลาด',
        message: 'กรุณาอัปโหลดรูปถ่ายบัตรประชาชนเพื่อทำการยืนยันตน',
      );
      return;
    }
    if (_addressController.text.trim().isEmpty) {
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
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5))),
    );

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final payload = <String, dynamic>{
        'role': 'seller',
        'document_status': 'approved',
        'citizen_id': '1234567890123',
        'address': _addressController.text.trim(),
      };
      if (_uploadedFileName != null) {
        payload['document_image'] = _uploadedFileName;
      }
      final response = await authService.updateProfile(payload);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (response['status'] == true) {
        if (mounted) {
          AppDialog.showSuccess(
            context,
            title: 'ส่งข้อมูลสำเร็จ',
            message: 'ส่งใบสมัครและเปิดใช้งานบัญชีผู้ค้าเรียบร้อยแล้ว!',
            onConfirm: () {
              Navigator.pop(context); // Pop success dialog
              Navigator.pop(context); // Go back to profile screen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sign Up',
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
                'กรุณากรอกข้อมูลส่วนตัวของคุณเพื่อเริ่มต้นการใช้งาน',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'ชื่อจริง-นามสกุลจริง(ตามบัตรประชาชน)',
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
                    hintText: 'ระบุชื่อ-นามสกุลตามบัตรประชาชน',
                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'รูปถ่ายบัตรประชาชน',
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
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _uploadedFileName != null ? const Color(0xFF1E88E5) : const Color(0xFFCBD5E1),
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
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _uploadedFileName != null ? const Color(0xFFE8F5E9) : const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _uploadedFileName != null ? Icons.check : Icons.cloud_upload_outlined,
                            color: _uploadedFileName != null ? const Color(0xFF2E7D32) : const Color(0xFF1E88E5),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        _uploadedFileName ?? 'คลิกเพื่ออัปโหลดรูปบัตรประชาชน',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _uploadedFileName != null ? const Color(0xFF2E7D32) : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PNG, JPG หรือ PDF (สูงสุด 5MB)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ตรวจสอบให้แน่ใจว่ารูปถ่ายชัดเจนและเห็นข้อความครบถ้วน',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
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
                    hintText: 'เลขที่บ้าน, ถนน, แขวง/ตำบล, เขต/อำเภอ, จังหวัด, รหัสไปรษณีย์',
                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
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
                        'ส่งข้อมูล',
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
