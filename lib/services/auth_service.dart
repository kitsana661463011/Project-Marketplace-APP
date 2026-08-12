import 'dart:convert';
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
        final matchingUser = users.firstWhere(
          (u) => u['email'] == email,
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
        'email': email,
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
        return {
          'status': false,
          'message': response['message'] ?? 'สมัครสมาชิกไม่สำเร็จ',
          'errors': response['data'],
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'status': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser?.userId == null) {
      return {'status': false, 'message': 'ไม่ได้เข้าสู่ระบบ'};
    }

    final response = await ApiService.put(
      '${ApiConfig.users}/${_currentUser!.userId}',
      data,
    );

    if (response['status'] == true && response['data'] != null) {
      _currentUser = UserModel.fromJson(response['data']);
      await _saveUserData();
      notifyListeners();
    }
    return response;
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
        {'email': email},
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
        {'email': email, 'code': code},
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
          'email': email,
          'code': code,
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
