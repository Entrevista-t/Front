import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interview_models.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api-entrevistat.kire.ovh',
  );

  static String? _token;
  static int? _userId;
  static String? _userName;
  static String? _userEmail;
  static String? _userCreatedAt;

  // ── Dev bypass ──────────────────────────────────────────────────────────────

  static Future<void> devBypassLogin({
    required String token,
    required String name,
    required String email,
  }) async {
    _token = token;
    _userName = name;
    _userEmail = email;
    _userId = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setInt('user_id', 0);
  }

  // ── User info getters ──────────────────────────────────────────────────────

  static String? get userName => _userName;
  static String? get userEmail => _userEmail;
  static int? get userId => _userId;

  // ── Token / header helpers ─────────────────────────────────────────────────

  static Future<void> _loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getInt('user_id');
    _userName = prefs.getString('user_name');
    _userEmail = prefs.getString('user_email');
    _userCreatedAt = prefs.getString('user_created_at');
  }

  static Map<String, String> get _jsonAuthHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };


  // ── Auth ────────────────────────────────────────────────────────────────────

  static Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      body: {'username': email, 'password': password},
    );
    if (res.statusCode == 200) {
      _token = jsonDecode(res.body)['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await _fetchAndCacheProfile();
    } else {
      throw Exception('Credencials incorrectes');
    }
  }

  static Future<void> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nom': name, 'email': email, 'password': password}),
    );
    if (res.statusCode == 201) {
      // Backend returns UsuariResponse without token; auto-login
      try {
        await login(email, password);
      } catch (_) {
        throw Exception('Compte creat. Si us plau, inicia sessio manualment.');
      }
    } else {
      final body = _tryDecodeBody(res.body);
      throw Exception(body?['detail'] ?? 'Error en crear el compte');
    }
  }

  static Future<void> logout() async {
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userCreatedAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_created_at');
  }

  static Future<bool> isLoggedIn() async {
    await _loadToken();
    return _token != null;
  }

  // ── User Profile ───────────────────────────────────────────────────────────

  static Future<void> _fetchAndCacheProfile() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/usuarios/me'),
      headers: _jsonAuthHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _userId = data['id'] as int;
      _userName = data['nom'] as String?;
      _userEmail = data['email'] as String?;
      _userCreatedAt = data['data_creacio'] as String?;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', _userId!);
      if (_userName != null) await prefs.setString('user_name', _userName!);
      if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
      if (_userCreatedAt != null) await prefs.setString('user_created_at', _userCreatedAt!);
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    await _loadToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/usuarios/me'),
      headers: _jsonAuthHeaders,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _userId = data['id'] as int;
      _userName = data['nom'] as String?;
      _userEmail = data['email'] as String?;
      _userCreatedAt = data['data_creacio'] as String?;
      return data;
    }
    await _guard(res);
    throw Exception('Error carregant el perfil');
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    String? nom,
    String? email,
    String? password,
  }) async {
    await _loadToken();
    if (_userId == null) throw Exception("ID d'usuari no disponible");
    final body = <String, dynamic>{};
    if (nom != null) body['nom'] = nom;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    final res = await http.patch(
      Uri.parse('$_baseUrl/usuarios/$_userId'),
      headers: _jsonAuthHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _userName = data['nom'] as String?;
      _userEmail = data['email'] as String?;
      final prefs = await SharedPreferences.getInstance();
      if (_userName != null) await prefs.setString('user_name', _userName!);
      if (_userEmail != null) await prefs.setString('user_email', _userEmail!);
      return data;
    }
    await _guard(res);
    throw Exception('Error actualitzant el perfil');
  }

  static Future<void> deleteAccount() async {
    await _loadToken();
    if (_userId == null) throw Exception("ID d'usuari no disponible");
    final res = await http.delete(
      Uri.parse('$_baseUrl/usuarios/$_userId'),
      headers: _jsonAuthHeaders,
    );
    if (res.statusCode == 200) {
      await logout();
      return;
    }
    await _guard(res);
    throw Exception('Error eliminant el compte');
  }

  // ── Categories ──────────────────────────────────────────────────────────────

  static Future<List<InterviewCategory>> getCategories() async {
    await _loadToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/categorias'),
      headers: _jsonAuthHeaders,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => InterviewCategory.fromJson(e))
          .toList();
    }
    await _guard(res);
    throw Exception('Error carregant categories');
  }

  // ── Questions ──────────────────────────────────────────────────────────────

  static Future<List<Question>> getQuestions(String categoryId) async {
    await _loadToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/preguntas?categoria_id=$categoryId'),
      headers: _jsonAuthHeaders,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => Question.fromJson(e))
          .toList();
    }
    await _guard(res);
    throw Exception('Error carregant preguntes');
  }

  static Future<Question> getRandomQuestion(String categoryId) async {
    await _loadToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/preguntas/random?categoria_id=$categoryId'),
      headers: _jsonAuthHeaders,
    );
    if (res.statusCode == 200) {
      return Question.fromJson(jsonDecode(res.body));
    }
    await _guard(res);
    throw Exception('Error carregant pregunta');
  }

  // ── Interviews ──────────────────────────────────────────────────────────────

  static Future<List<InterviewSession>> getRecentSessions() async {
    await _loadToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/entrevistas/me'),
      headers: _jsonAuthHeaders,
    );
    if (res.statusCode == 200) {
      final list = (jsonDecode(res.body) as List)
          .map((e) => InterviewSession.fromJson(e))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
    await _guard(res);
    throw Exception('Error carregant sessions');
  }

  static Future<InterviewSession> getInterviewById(String interviewId) async {
    await _loadToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/entrevistas/$interviewId'),
      headers: _jsonAuthHeaders,
    );
    if (res.statusCode == 200) {
      return InterviewSession.fromJson(jsonDecode(res.body));
    }
    await _guard(res);
    throw Exception("Error carregant l'entrevista");
  }

  /// Two-step interview submission:
  /// 1) Create a pending interview record
  /// 2) Upload video for analysis
  static Future<String> submitInterview({
    required String questionId,
    required String questionText,
    required List<int> videoBytes,
    required String fileName,
  }) async {
    await _loadToken();

    // Step 1: Create pending interview
    final createRes = await http.post(
      Uri.parse('$_baseUrl/entrevistas'),
      headers: _jsonAuthHeaders,
      body: jsonEncode({'id_pregunta': int.parse(questionId)}),
    );
    if (createRes.statusCode != 201) {
      await _guard(createRes);
      throw Exception("Error creant l'entrevista (${createRes.statusCode})");
    }
    final interviewId = jsonDecode(createRes.body)['id'].toString();

    // Step 2: Upload video for analysis
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/analyze'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.fields['question'] = questionText;
    request.fields['language'] = 'ca';
    request.fields['id_entrevista'] = interviewId;
    request.files.add(http.MultipartFile.fromBytes(
      'video',
      videoBytes,
      filename: fileName,
      contentType: MediaType('video', 'mp4'),
    ));
    final streamed = await request.send();
    final analyzeRes = await http.Response.fromStream(streamed);
    if (analyzeRes.statusCode != 200) {
      await _guard(analyzeRes);
      throw Exception('Error analitzant el video (${analyzeRes.statusCode})');
    }
    return interviewId;
  }

  /// Polls until the backend has finished processing.
  static Future<InterviewResult> getResults(String interviewId) async {
    await _loadToken();
    for (int i = 0; i < 30; i++) {
      final res = await http.get(
        Uri.parse('$_baseUrl/entrevistas/$interviewId/informe'),
        headers: _jsonAuthHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data['estat_proces'] as String? ?? '';
        if (status == 'completat') {
          return InterviewResult.fromJson(data);
        }
        if (status == 'error') {
          throw Exception("Error en el processament de l'entrevista");
        }
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
      await _guard(res);
      throw Exception('Error obtenint resultats (${res.statusCode})');
    }
    throw Exception("Temps d'espera esgotat. L'analisi encara s'esta processant.");
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Checks for 401 responses globally. Call after any authenticated request.
  /// Clears auth state so GoRouter's redirect sends user to login.
  static Future<void> _guard(http.Response res) async {
    if (res.statusCode == 401) {
      await logout();
      throw Exception('Sessio expirada. Torna a iniciar sessio.');
    }
  }

  static Map<String, dynamic>? _tryDecodeBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}