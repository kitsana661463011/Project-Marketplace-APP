import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userData));
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ดึงรายชื่อ users ทั้งหมดแล้วเช็ค email
      final response = await ApiService.get(ApiConfig.users);

      if (response['status'] == true && response['data'] != null) {
        final users = response['data'] as List;
        final cleanEmail = email.trim().toLowerCase();
        final matchingUser = users.firstWhere(
          (u) => (u['email'] ?? '').toString().trim().toLowerCase() == cleanEmail,
          orElse: () => null,
        );

        if (matchingUser != null) {
          _currentUser = UserModel.fromJson(matchingUser);
          await _saveUserData();
          _isLoading = false;
          notifyListeners();
          return {'status': true, 'message': 'เข้าสู่ระบบสำเร็จ'};
        } else {
          _isLoading = false;
          notifyListeners();
          return {'status': false, 'message': 'ไม่พบอีเมลนี้ในระบบ'};
        }
      } else {
        _isLoading = false;
        notifyListeners();
        return {
          'status': false,
          'message': response['message'] ?? 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้',
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'status': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? phone,
    String role = 'buyer',
    String? interests,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'username': username,
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': phone,
        'role': role,
        'status': 'active',
      };
      if (interests != null && interests.isNotEmpty) {
        payload['interests'] = interests;
      }

      final response = await ApiService.post(ApiConfig.users, payload);

      if (response['status'] == true && response['data'] != null) {
        _currentUser = UserModel.fromJson(response['data']);
        await _saveUserData();
        _isLoading = false;
        notifyListeners();
        return {'status': true, 'message': 'สมัครสมาชิกสำเร็จ'};
      } else {
        _isLoading = false;
        notifyListeners();
        String errorMessage =
            response['message']?.toString() ?? 'สมัครสมาชิกไม่สำเร็จ';
        bool isDuplicateEmail = false;

        if (response['data'] is Map) {
          final errors = response['data'] as Map<String, dynamic>;
          if (errors.containsKey('email')) {
            isDuplicateEmail = true;
            final emailErr = errors['email'];
            if (emailErr is List && emailErr.isNotEmpty) {
              errorMessage = emailErr.first.toString();
            } else if (emailErr is String && emailErr.isNotEmpty) {
              errorMessage = emailErr;
            }
          }
        }

        final lowerMsg = errorMessage.toLowerCase();
        if (isDuplicateEmail ||
            lowerMsg.contains('already been taken') ||
            lowerMsg.contains('unique') ||
            lowerMsg.contains('ซ้ำ') ||
            errorMessage.contains('ถูกใช้งานแล้ว') ||
            errorMessage.contains('มีผู้ใช้งานแล้ว')) {
          isDuplicateEmail = true;
          errorMessage =
              'อีเมลนี้มีผู้ใช้งานแล้วในระบบ กรุณาใช้อีเมลอื่นหรือเข้าสู่ระบบ';
        }

        return {
          'status': false,
          'message': errorMessage,
          'isDuplicateEmail': isDuplicateEmail,
          'errors': response['data'],
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'status': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data, {
    String? fileKey,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    if (_currentUser?.userId == null) {
      return {'status': false, 'message': 'ไม่ได้เข้าสู่ระบบ'};
    }

    final userId = _currentUser!.userId;
    Map<String, dynamic> response;

    if (fileBytes != null || (filePath != null && filePath.isNotEmpty)) {
      final fields = <String, String>{
        '_method': 'PUT',
      };
      data.forEach((key, value) {
        if (value != null) {
          fields[key] = value.toString();
        }
      });

      response = await ApiService.postMultipart(
        '${ApiConfig.users}/$userId',
        fields,
        fileKey: fileKey ?? 'document_image_file',
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName ?? 'document.png',
      );
    } else {
      response = await ApiService.put(
        '${ApiConfig.users}/$userId',
        data,
      );
    }

    if (response['status'] == true && response['data'] != null) {
      _currentUser = UserModel.fromJson(response['data']);
      await _saveUserData();
      notifyListeners();
    }
    return response;
  }

  Future<UserModel?> fetchUserProfile() async {
    if (_currentUser?.userId == null) return _currentUser;
    try {
      final response = await ApiService.get('${ApiConfig.users}/${_currentUser!.userId}');
      if (response['status'] == true && response['data'] != null) {
        _currentUser = UserModel.fromJson(response['data']);
        await _saveUserData();
        notifyListeners();
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
    return _currentUser;
  }

  Future<Map<String, dynamic>> cancelVendorApplication() async {
    if (_currentUser?.userId == null) {
      return {'status': false, 'message': 'ไม่ได้เข้าสู่ระบบ'};
    }
    try {
      final userId = _currentUser!.userId;
      final response = await ApiService.post(
        '${ApiConfig.users}/$userId/cancel-vendor-application',
        {},
      );
      if (response['status'] == true && response['data'] != null) {
        _currentUser = UserModel.fromJson(response['data']);
        await _saveUserData();
        notifyListeners();
      }
      return response;
    } catch (e) {
      return {'status': false, 'message': 'เกิดข้อผิดพลาดในการยกเลิกคำขอ: $e'};
    }
  }

  Future<void> updateUserData(Map<String, dynamic> userData) async {
    _currentUser = UserModel.fromJson(userData);
    await _saveUserData();
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }

  Future<Map<String, dynamic>> sendForgotPasswordCode(String email) async {
    try {
      final response = await ApiService.post(
        ApiConfig.forgotPassword,
        {'email': email.trim().toLowerCase()},
      );
      return response;
    } catch (e) {
      return {'status': false, 'message': 'เกิดข้อผิดพลาดในการส่งข้อมูล: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final response = await ApiService.post(
        ApiConfig.verifyResetCode,
        {'email': email.trim().toLowerCase(), 'code': code.trim()},
      );
      return response;
    } catch (e) {
      return {'status': false, 'message': 'เกิดข้อผิดพลาดในการส่งข้อมูล: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.resetPassword,
        {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
          'password': password,
        },
      );
      return response;
    } catch (e) {
      return {
        'status': false,
        'message': 'เกิดข้อผิดพลาดในการบันทึกรหัสผ่านใหม่: $e',
      };
    }
  }

  Future<void> _saveUserData() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'user_data',
        jsonEncode(_currentUser!.toJson()..['user_id'] = _currentUser!.userId),
      );
    }
  }
}
