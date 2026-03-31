import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interview_models.dart';

class ApiService {
  // Replace with the actual Cloudflare tunnel URL when deployed
  static const String _baseUrl = 'https://api.entrevistat.example.com';

  static String? _token;
  static String? _devName;
  static String? _devEmail;

  /// Sets a fake token and user info for dev/UI testing (no API call).
  static Future<void> devBypassLogin({
    required String token,
    required String name,
    required String email,
  }) async {
    _token = token;
    _devName = name;
    _devEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('dev_user_name', name);
    await prefs.setString('dev_user_email', email);
  }

  /// Returns the dev-bypass user name, or null if not in bypass mode.
  static String? get devUserName => _devName;
  static String? get devUserEmail => _devEmail;

  static Future<void> _loadToken() async {
    _token ??= (await SharedPreferences.getInstance()).getString('auth_token');
  }

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      _token = jsonDecode(res.body)['access_token'];
      await (await SharedPreferences.getInstance()).setString('auth_token', _token!);
    } else {
      throw Exception('Credencials incorrectes');
    }
  }

  static Future<void> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (res.statusCode == 201) {
      _token = jsonDecode(res.body)['access_token'];
      await (await SharedPreferences.getInstance()).setString('auth_token', _token!);
    } else {
      throw Exception('Error en crear el compte');
    }
  }

  static Future<void> logout() async {
    _token = null;
    await (await SharedPreferences.getInstance()).remove('auth_token');
  }

  static Future<bool> isLoggedIn() async {
    await _loadToken();
    return _token != null;
  }

  // ── Categories & Questions ────────────────────────────────────────────────

  static Future<List<InterviewCategory>> getCategories() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$_baseUrl/categories'), headers: _authHeaders);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => InterviewCategory.fromJson(e)).toList();
    }
    throw Exception('Error carregant categories');
  }

  static Future<List<Question>> getQuestions(String categoryId) async {
    await _loadToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/categories/$categoryId/questions'),
      headers: _authHeaders,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => Question.fromJson(e)).toList();
    }
    throw Exception('Error carregant preguntes');
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  static Future<List<InterviewSession>> getRecentSessions() async {
    await _loadToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/sessions?limit=5'),
      headers: _authHeaders,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).map((e) => InterviewSession.fromJson(e)).toList();
    }
    throw Exception('Error carregant sessions');
  }

  /// Uploads the recorded video to the backend.
  /// Returns the session_id to poll for results.
  static Future<String> submitInterview({
    required String categoryId,
    required String questionId,
    required String videoPath,
  }) async {
    await _loadToken();
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/sessions'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.fields['category_id'] = categoryId;
    request.fields['question_id'] = questionId;
    request.files.add(await http.MultipartFile.fromPath(
      'video',
      videoPath,
      contentType: MediaType('video', 'mp4'),
    ));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 202) {
      return jsonDecode(res.body)['session_id'];
    }
    throw Exception('Error en enviar el vídeo (${res.statusCode})');
  }

  /// Polls until the backend has finished processing and returns the result.
  static Future<InterviewResult> getResults(String sessionId) async {
    await _loadToken();
    for (int i = 0; i < 30; i++) {
      final res = await http.get(
        Uri.parse('$_baseUrl/sessions/$sessionId/results'),
        headers: _authHeaders,
      );
      if (res.statusCode == 200) {
        return InterviewResult.fromJson(jsonDecode(res.body));
      }
      if (res.statusCode == 202) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
      throw Exception('Error obtenint resultats (${res.statusCode})');
    }
    throw Exception('Timeout esperant que el servidor processi la sessió');
  }

  static Future<void> downloadPdf(String sessionId) async {
    await _loadToken();
    final res = await http.get(
      Uri.parse('$_baseUrl/sessions/$sessionId/pdf'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) throw Exception('Error descarregant PDF');
    // The PDF bytes are in res.bodyBytes — integrate a PDF viewer or save to downloads.
  }
}
