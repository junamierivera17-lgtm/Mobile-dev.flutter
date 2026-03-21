import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/violation.dart';

class DatabaseService {
  // Base URL of your API
  static const String _baseUrl = 'http://192.168.50.27:5277';

  // Initialize — kept for compatibility
  static void initialize() {}

  // ── Get saved JWT token ───────────────────────────────────────────────────
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // ── Save JWT token ────────────────────────────────────────────────────────
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // ── Clear JWT token on logout ─────────────────────────────────────────────
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // ── Headers with token ────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────
  static Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 1) {
        // Save the JWT token for future requests
        await _saveToken(data['data']['token']);

        // Map API role string to UserRole enum
        final roleStr = (data['data']['role'] as String).toLowerCase();
        UserRole role;
        switch (roleStr) {
          case 'guard':    role = UserRole.guard;    break;
          case 'student':  role = UserRole.student;  break;
          case 'sao':      role = UserRole.sao;      break;
          case 'guidance': role = UserRole.guidance; break;
          default:         role = UserRole.student;
        }

        return User(
          id: data['data']['id'].toString(),
          username: data['data']['username'],
          password: '',
          name: data['data']['name'],
          role: role,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // ── REGISTER ──────────────────────────────────────────────────────────────
  static Future<User?> register({
    required String username,
    required String password,
    required String name,
    required UserRole role,
    String? gradeSection,
    String? contactNumber,
    String? studentNo,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? address,
    String? course,
    String? year,
  }) async {
    try {
      // Split name into first and last
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email ?? '$username@aclc.com',
          'firstName': firstName,
          'lastName': lastName,
          'dateOfBirth': dateOfBirth ?? '2000-01-01',
          'gender': gender ?? 'Male',
          'address': address ?? '',
          'number': contactNumber ?? '',
          'role': role.name,
          'course': course,
          'year': year,
          'studentNo': studentNo,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 1) {
        return User(
          id: '',
          username: username,
          password: '',
          name: name,
          role: role,
          contactNumber: contactNumber,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // ── GET ALL STUDENTS ──────────────────────────────────────────────────────
  static Future<List<User>> getAllStudents() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/guidance/students'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List students = data['data'];
        return students.map((s) => User(
          id: s['student_no'] ?? '',
          username: s['student_no'] ?? '',
          password: '',
          name: s['name'] ?? '',
          role: UserRole.student,
          contactNumber: s['contact_number'],
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  // ── GET ALL USERS ─────────────────────────────────────────────────────────
  static Future<List<User>> getAllUsers() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List users = data['data'];
        return users.map((u) {
          final roleStr = (u['role'] as String).toLowerCase();
          UserRole role;
          switch (roleStr) {
            case 'guard':    role = UserRole.guard;    break;
            case 'student':  role = UserRole.student;  break;
            case 'sao':      role = UserRole.sao;      break;
            case 'guidance': role = UserRole.guidance; break;
            default:         role = UserRole.student;
          }
          return User(
            id: u['id'].toString(),
            username: u['username'],
            password: '',
            name: u['name'],
            role: role,
            contactNumber: u['contact_number'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // ── GET VIOLATIONS BY STUDENT ─────────────────────────────────────────────
  static Future<List<Violation>> getStudentViolations(String studentNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/student/$studentNo/violations'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List violations = data['data']['violations'];
        return violations.map((v) => Violation(
          id: v['id'].toString(),
          studentId: studentNo,
          type: ViolationType.noId, // default type since API returns string
          date: DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
          remarks: v['details'] ?? '',
          status: _parseStatus(v['status']),
          offenseCount: 1,
          reportedBy: v['recorded_by'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get violations: $e');
    }
  }

  // ── GET ALL VIOLATIONS ────────────────────────────────────────────────────
  static Future<List<Violation>> getAllViolations() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/sao/violations'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List violations = data['data'];
        return violations.map((v) => Violation(
          id: v['id'].toString(),
          studentId: v['student_no'] ?? '',
          type: ViolationType.noId, // default type since API returns string
          date: DateTime.tryParse(v['date'] ?? '') ?? DateTime.now(),
          remarks: v['details'] ?? '',
          status: _parseStatus(v['status']),
          offenseCount: 1,
          reportedBy: v['recorded_by'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get all violations: $e');
    }
  }

  // ── ADD VIOLATION ─────────────────────────────────────────────────────────
  static Future<void> addViolation(Violation violation) async {
    try {
      final headers = await _authHeaders();
      await http.post(
        Uri.parse('$_baseUrl/api/guard/student/violation'),
        headers: headers,
        body: jsonEncode({
          'studentNo': violation.studentId,
          'violationType': violation.type.name,
          'details': violation.remarks ?? '',
          'severity': 'minor',
          'guardId': violation.reportedBy ?? '',
        }),
      );
    } catch (e) {
      throw Exception('Failed to add violation: $e');
    }
  }

  // ── UPDATE VIOLATION STATUS ───────────────────────────────────────────────
  static Future<void> updateViolationStatus(
      String violationId, ViolationStatus status) async {
    try {
      final headers = await _authHeaders();

      // Map Flutter status to API action
      // Only pending → approved or pending → rejected is supported by the API
      String action;
      if (status == ViolationStatus.referredToSAO) {
        action = 'approve';
      } else {
        action = 'reject';
      }

      await http.put(
        Uri.parse('$_baseUrl/api/sao/violations/$violationId/$action'),
        headers: headers,
      );
    } catch (e) {
      throw Exception('Failed to update violation status: $e');
    }
  }

  // ── GET VIOLATION COUNT ───────────────────────────────────────────────────
  static Future<int> getViolationCount(
      String studentId, ViolationType type) async {
    try {
      final violations = await getStudentViolations(studentId);
      return violations.where((v) => v.type == type).length;
    } catch (e) {
      return 0;
    }
  }

  // ── Parse API status string to ViolationStatus enum ──────────────────────
  // API returns: Pending, Approved, Rejected
  // Flutter enum has: pending, warning, parentNotified, referredToSAO,
  //                   referredToGuidance, disciplinaryAction, cleared
  static ViolationStatus _parseStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved': return ViolationStatus.referredToSAO;
      case 'rejected': return ViolationStatus.cleared;
      default:         return ViolationStatus.pending;
    }
  }
}