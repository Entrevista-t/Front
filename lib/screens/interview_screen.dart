import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSans;
import '../widgets/dot_grid_background.dart';
import '../widgets/onboarding_dialog.dart';


class InterviewScreen extends StatefulWidget {
  final String categoryId;
  final String? categoryName;

  const InterviewScreen({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  Question? _question;
  bool _recording = false;
  bool _loading = true;
  bool _uploading = false;
  bool _permissionsGranted = false;
  String? _error;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  late final AnimationController _ringPulseCtrl;

  @override
  void initState() {
    super.initState();

    _ringPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _init();
  }

  Future<void> _init() async {
    try {
      await _requestPermissions();
      await _loadQuestion();
      await _initCamera();
      _showOnboardingIfNeeded();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error inicialitzant: $e';
        });
      }
    }
  }

  Future<void> _showOnboardingIfNeeded() async {
    if (mounted) {
      await showOnboardingDialog(context);
    }
  }

  void _openOnboarding() {
    showOnboardingDialog(context);
  }

  Future<void> _requestPermissions() async {
    try {
      final statuses = await [Permission.camera, Permission.microphone].request();
      setState(() {
        _permissionsGranted = statuses.values.every((s) => s.isGranted);
      });
    } catch (_) {
      // permission_handler may throw on some web browsers (Safari, Linux);
      // the browser itself will prompt when getUserMedia is called.
      setState(() { _permissionsGranted = true; });
    }
  }

  Future<void> _loadQuestion() async {
    try {
      final question = await ApiService.getRandomQuestion(widget.categoryId);
      setState(() { _question = question; });
    } catch (_) {
      setState(() { _question = Question.fallback().first; });
    }
  }

  Future<void> _initCamera() async {
    if (!_permissionsGranted) {
      setState(() { _loading = false; });
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() { _loading = false; _error = "No s'ha trobat cap càmera."; });
        return;
      }
      // Default to front camera if available
      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;

      await _initCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() { _error = 'Error inicialitzant la càmera: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    try {
      await _camera?.dispose();
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();
      _camera = controller;
      if (mounted) setState(() {});
    } catch (e) {
      _camera = null;
      rethrow;
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _recording) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    try {
      setState(() { _selectedCameraIndex = nextIndex; });
      await _initCameraController(_cameras[nextIndex]);
    } catch (e) {
      setState(() { _error = 'Error canviant de càmera: $e'; });
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
    final camera = _camera;
    final question = _question;
    if (camera == null || question == null) {
      setState(() { _error = "No s'ha pogut enviar: càmera o pregunta no disponible."; });
      return;
    }
    _timer?.cancel();
    setState(() { _recording = false; _uploading = true; });
    try {
      final file = await camera.stopVideoRecording();
      final bytes = await file.readAsBytes();
      // Web cameras typically record WebM; ensure filename has a valid extension
      var name = file.name;
      if (!RegExp(r'\.(mp4|webm|avi|mov|mkv|m4v|wmv)$', caseSensitive: false).hasMatch(name)) {
        name = 'recording.webm';
      }
      final interviewId = await ApiService.submitInterview(
        questionId: question.id,
        questionText: question.text,
        videoBytes: bytes,
        fileName: name,
      );
      if (mounted) context.go('/report-sent/$interviewId');
    } catch (e) {
      setState(() { _uploading = false; _error = 'Error en enviar la gravació: $e'; });
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
    _ringPulseCtrl.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    if (_uploading) return _buildUploading();
    if (!_permissionsGranted) return _buildPermissionsError();
    if (_error != null) return _buildError();

    final question = _question ?? Question.fallback().first;

    return Scaffold(
      body: DotGridBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: kS48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Question (large, no card) ─────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Text(
                            question.text,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontFamily: kFontSans,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.normal,
                              fontSize: 38,
                              height: 1.25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: kS16),

                      // ── Tutorial button (always visible) ──────────────────
                      Center(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _openOnboarding,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: kS16, vertical: kS8),
                              decoration: BoxDecoration(
                                color: kAccent.withValues(alpha: 0.10),
                                borderRadius:
                                    BorderRadius.circular(kRadiusFull),
                                border: Border.all(
                                  color: kAccent.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.help_outline_rounded,
                                      size: 16, color: kAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Com funciona?',
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: kS16),

                      // ── Camera preview (clean, static border) ─────────────
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(kRadiusMd + 3),
                                border: Border.all(
                                  color: context.colors.borderSubtle,
                                ),
                              ),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(kRadiusMd),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Container(
                                        color: context.colors.bgElevated,
                                        child: (_camera != null && _camera!.value.isInitialized)
                                            ? CameraPreview(_camera!)
                                            : _buildNoCameraPlaceholder(),
                                      ),
                                      if (_cameras.length > 1)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _recording ? null : _switchCamera,
                                              customBorder: const CircleBorder(),
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.black.withValues(alpha: 0.45),
                                                ),
                                                child: Icon(
                                                  Icons.cameraswitch_rounded,
                                                  size: 18,
                                                  color: _recording
                                                      ? Colors.white.withValues(alpha: 0.3)
                                                      : Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: kS8),

                      // ── Progress bar (60s, always reserves space) ─────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(kRadiusMd),
                            child: Opacity(
                              opacity: _recording ? 1.0 : 0.0,
                              child: LinearProgressIndicator(
                                value: (_elapsed.inSeconds / 60).clamp(0.0, 1.0),
                                minHeight: 4,
                                color: kAccent,
                                backgroundColor: context.colors.borderSubtle,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: kS16),

                      // ── Record / Stop button ──────────────────────────────
                      Center(child: _buildRecordButton()),
                    ],
                  ),
                ),
              ),

              // ── Close button (top-left) ───────────────────────────────
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: _recording
                        ? context.colors.textDisabled
                        : context.colors.textSecondary,
                  ),
                  onPressed: _recording ? null : () => context.go('/home'),
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.bgSurface.withValues(alpha: 0.7),
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    // Fixed height prevents layout shift when switching states
    return SizedBox(
      height: 120,
      child: _recording ? _buildStopButton() : _buildIdleRecordButton(),
    );
  }

  Widget _buildStopButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _stopAndSubmit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: kS24, vertical: kS12),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(kRadiusFull),
                boxShadow: [
                  BoxShadow(
                    color: kAccent.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: kS8),
                  const Text(
                    'Atura la gravació',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: kS8),
        Text(
          _elapsedFormatted,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildIdleRecordButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ringPulseCtrl,
          builder: (context, _) {
            final scale = 1.0 + 0.5 * _ringPulseCtrl.value;
            final opacity = 1.0 - _ringPulseCtrl.value;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kAccent.withValues(alpha: opacity * 0.5),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kAccent,
              boxShadow: [
                BoxShadow(
                  color: kAccent.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.fiber_manual_record_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoCameraPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.videocam_off_outlined, size: 40, color: context.colors.textSecondary),
        const SizedBox(height: kS8),
        Text('Càmera no disponible',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: kS16),
            Text('Inicialitzant càmera...'),
          ],
        ),
      ),
    );
  }

  Widget _buildUploading() {
    const steps = [
      '1. Pujant vídeo...',
      '2. Analitzant amb IA...',
      '3. Generant informe...',
    ];
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kS24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: kS24),
              Text(
                'Processant resposta...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: kS16),
              ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: kS4),
                child: Text(
                  step,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsError() {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrevista')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kS24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_rounded, size: 72, color: context.colors.textSecondary),
              const SizedBox(height: kS24),
              const Text(
                'Cal accés a la càmera i el micròfon',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kS8),
              const Text(
                "Atorga els permisos necessaris per poder\nenregistrar la simulació d'entrevista.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kS24),
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
          padding: const EdgeInsets.all(kS24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 72, color: kErrorRed),
              const SizedBox(height: kS16),
              Text(_error ?? '', textAlign: TextAlign.center),
              const SizedBox(height: kS24),
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home),
                label: const Text("Tornar a l'inici"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

