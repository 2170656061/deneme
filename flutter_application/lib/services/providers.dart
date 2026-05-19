import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;
  final _storage = const FlutterSecureStorage();

  Map<String, dynamic>? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;

  // All signed-in users are admin by the current paradigm,
  // but we still check the role field for future flexibility.
  bool get isAdmin => _currentUser?['role'] == 'admin';

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await _storage.read(key: 'auth_token');
      if (_token != null) {
        await _loadCurrentUser();
      }
    } catch (e) {
      _error = e.toString();
      _token = null;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser() async {
    if (_token == null) return;
    try {
      _currentUser = await ApiService.getMe(_token!);
    } catch (e) {
      _token = null;
      _currentUser = null;
      await _storage.delete(key: 'auth_token');
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(username, password);
      _token = response['access_token'];
      _currentUser = response['user'];
      await _storage.write(key: 'auth_token', value: _token);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _token = null;
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
      String username, String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.register(username, email, password, role);
      _token = response['access_token'];
      _currentUser = response['user'];
      await _storage.write(key: 'auth_token', value: _token);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _token = null;
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }
}

class CourseProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _courses = [];
  final Map<int, List<Map<String, dynamic>>> _checkpointsByCourse = {};
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _courses = await ApiService.getCourses();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCheckpoints(int courseId) async {
    if (_checkpointsByCourse.containsKey(courseId)) return;

    try {
      final checkpoints = await ApiService.getCheckpoints(courseId);
      _checkpointsByCourse[courseId] = checkpoints;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getCheckpoints(int courseId) {
    return _checkpointsByCourse[courseId] ?? [];
  }

  Future<void> forceReloadCheckpoints(int courseId) async {
    _checkpointsByCourse.remove(courseId);
    await loadCheckpoints(courseId);
  }

  Future<void> uploadKML(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.uploadKML(filePath);
      await loadCourses();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class UserProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get users => _users;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all users. Requires an admin token.
  Future<void> loadUsers({String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await ApiService.getUsers(token: token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(String username, String email, String password, String role,
      {String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await ApiService.createUser(username, email, password, role,
          token: token);
      _users.add(user);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentUser(Map<String, dynamic> user) {
    _currentUser = user;
    notifyListeners();
  }
}

class ResultProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadResults() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _results = await ApiService.getResults();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncResult(
    int userId,
    int courseId,
    double totalTimeSeconds,
    {String? token}
  ) async {
    try {
      await ApiService.syncResult(userId, courseId, totalTimeSeconds, token: token);
      await loadResults();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
