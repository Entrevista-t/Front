import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';

class InterviewScreen extends StatefulWidget {
  final String categoryId;

  const InterviewScreen({super.key, required this.categoryId});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  CameraController? _camera;
  List<Question> _questions = [];
  int _currentIndex = 0;
  bool _recording = false;
  bool _loading = true;
  bool _uploading = false;
  bool _permissionsGranted = false;
  String? _error;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _loadQuestions();
    await _initCamera();
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    setState(() {
      _permissionsGranted = statuses.values.every((s) => s.isGranted);
    });
  }

  Future<void> _loadQuestions() async {
    try {
      final q = await ApiService.getQuestions(widget.categoryId);
      setState(() { _questions = q; });
    } catch (_) {
      setState(() { _questions = Question.fallback(); });
    }
  }

  Future<void> _initCamera() async {
    if (!_permissionsGranted) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() { _loading = false; _error = "No s'ha trobat cap càmera."; });
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _camera = CameraController(front, ResolutionPreset.medium, enableAudio: true);
      await _camera!.initialize();
    } catch (e) {
      setState(() { _error = 'Error inicialitzant la càmera: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _startRecording() async {
    if (_camera == null || !_camera!.value.isInitialized) return;
    try {
      await _camera!.startVideoRecording();
      setState(() { _recording = true; _elapsed = Duration.zero; });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() { _elapsed += const Duration(seconds: 1); });
      });
    } catch (e) {
      setState(() { _error = 'Error iniciant la gravació: $e'; });
    }
  }

  void _stopAndSubmit() async {
    if (!_recording) return;
    _timer?.cancel();
    setState(() { _recording = false; _uploading = true; });
    try {
      final file = await _camera!.stopVideoRecording();
      final sessionId = await ApiService.submitInterview(
        categoryId: widget.categoryId,
        questionId: _questions[_currentIndex].id,
        videoPath: file.path,
      );
      if (mounted) context.go('/report-sent/$sessionId');
    } catch (e) {
      setState(() { _uploading = false; _error = 'Error en enviar la gravació: $e'; });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() { _currentIndex++; });
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() { _currentIndex--; });
    }
  }

  String get _elapsedFormatted {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Inicialitzant càmera...'),
          ],
        )),
      );
    }
    if (_uploading) return _buildUploading();
    if (!_permissionsGranted) return _buildPermissionsError();
    if (_error != null) return _buildError();

    final question = _questions.isEmpty ? Question.fallback().first : _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_camera != null && _camera!.value.isInitialized)
            CameraPreview(_camera!),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _recording ? null : () => context.go('/home'),
                    ),
                    if (_recording)
                      _buildRecordingBadge()
                    else
                      const SizedBox(width: 48),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${_questions.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Question card
          Positioned(
            left: 16, right: 16, top: 110,
            child: _buildQuestionCard(question),
          ),

          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous question (only when not recording)
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        color: (!_recording && _currentIndex > 0) ? Colors.white : Colors.white30,
                        size: 36,
                      ),
                      onPressed: (!_recording && _currentIndex > 0) ? _prevQuestion : null,
                    ),

                    // Record / Stop button
                    GestureDetector(
                      onTap: _recording ? _stopAndSubmit : _startRecording,
                      child: Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _recording ? Colors.red : Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                        ),
                        child: Icon(
                          _recording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded,
                          color: _recording ? Colors.white : Colors.red,
                          size: 38,
                        ),
                      ),
                    ),

                    // Next question (only when not recording)
                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: (!_recording && _currentIndex < _questions.length - 1) ? Colors.white : Colors.white30,
                        size: 36,
                      ),
                      onPressed: (!_recording && _currentIndex < _questions.length - 1) ? _nextQuestion : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Hint when not recording
          if (!_recording)
            Positioned(
              bottom: 110, left: 0, right: 0,
              child: Center(
                child: Text(
                  'Prem el botó vermell per iniciar la gravació',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: Colors.white, size: 9),
          const SizedBox(width: 6),
          Text(
            'REC  $_elapsedFormatted',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final blue = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  question.category.toUpperCase(),
                  style: TextStyle(color: blue, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildUploading() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Processant resposta...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text(
              'El servidor analitza el vídeo i l\'àudio amb IA.\nAixò pot trigar uns segons.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsError() {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrevista')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded, size: 72, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                'Cal accés a la càmera i el micròfon',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Atorga els permisos necessaris per poder\nenregistrar la simulació d\'entrevista.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Obrir configuració'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrevista')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home),
                label: const Text('Tornar a l\'inici'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
