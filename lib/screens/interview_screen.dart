import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSerif;
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
    with TickerProviderStateMixin {
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

  // Animation controllers
  late final AnimationController _borderPulseCtrl;
  late final AnimationController _dotPulseCtrl;
  late final AnimationController _ringPulseCtrl;

  String get _displayName =>
      widget.categoryName ?? widget.categoryId;

  @override
  void initState() {
    super.initState();

    _borderPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _dotPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _ringPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _loadQuestion();
    await _initCamera();
    _showOnboardingIfNeeded();
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
    final statuses = await [Permission.camera, Permission.microphone].request();
    setState(() {
      _permissionsGranted = statuses.values.every((s) => s.isGranted);
    });
  }

  Future<void> _loadQuestion() async {
    try {
      final questions = await ApiService.getQuestions(widget.categoryId);
      setState(() {
        _question = questions.isNotEmpty ? questions.first : Question.fallback().first;
      });
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
    await _camera?.dispose();
    _camera = CameraController(description, ResolutionPreset.medium, enableAudio: true);
    await _camera!.initialize();
    if (mounted) setState(() {});
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
    _timer?.cancel();
    setState(() { _recording = false; _uploading = true; });
    try {
      final file = await _camera!.stopVideoRecording();
      final sessionId = await ApiService.submitInterview(
        categoryId: widget.categoryId,
        questionId: _question!.id,
        videoPath: file.path,
      );
      if (mounted) context.go('/report-sent/$sessionId');
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
    _borderPulseCtrl.dispose();
    _dotPulseCtrl.dispose();
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _recording ? null : () => context.go('/home'),
          color: _recording ? context.colors.textDisabled : null,
        ),
        title: Text(_displayName),
        actions: const [],
      ),
      body: DotGridBackground(
        child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: kS24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Question (prominent, centered, card treatment) ───────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Container(
                          padding: const EdgeInsets.all(kS24),
                          decoration: BoxDecoration(
                            color: context.colors.bgSurface,
                            borderRadius: BorderRadius.circular(kRadiusMd),
                            border: Border.all(color: context.colors.borderSubtle),
                          ),
                          child: Text(
                            question.text,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontFamily: kFontSerif,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.normal,
                              fontSize: 26,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: kS16),

                    // ── Tutorial button (hidden while recording) ─────────
                    if (!_recording)
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

                    // ── Camera preview with overlaid info ──────────────────────
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                          child: AnimatedBuilder(
                            animation: _borderPulseCtrl,
                            builder: (context, child) {
                              final borderColor = _recording
                                  ? Color.lerp(
                                      kErrorRed.withValues(alpha: 0.3),
                                      kErrorRed,
                                      _borderPulseCtrl.value,
                                    )!
                                  : context.colors.borderSubtle;
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(kRadiusMd + 3),
                                  border: Border.all(
                                    color: borderColor,
                                    width: _recording ? 3.0 : 1.0,
                                  ),
                                ),
                                child: child,
                              );
                            },
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
                                    // Camera switch button (only when >1 camera)
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

                    // ── Timer (below camera) ─────────────────────────────────
                    if (_recording) Center(child: _buildTimerBadge()),

                    if (_recording) ...[
                      const SizedBox(height: kS8),
                      // ── Progress bar (60s) ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(kRadiusMd),
                            child: LinearProgressIndicator(
                              value: (_elapsed.inSeconds / 60).clamp(0.0, 1.0),
                              minHeight: 4,
                              color: kAccent,
                              backgroundColor: context.colors.borderSubtle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: kS8),
                      Text(
                        'Prem el botó per aturar i enviar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: kErrorRed),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: kS16),

                    // ── Record button ────────────────────────────────────────
                    Center(child: _buildRecordButton()),
                  ],
                ),
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildTimerBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _dotPulseCtrl,
          builder: (context, child) {
            return Opacity(
              opacity: 0.3 + 0.7 * _dotPulseCtrl.value,
              child: child,
            );
          },
          child: const Icon(Icons.circle, color: kErrorRed, size: 8),
        ),
        const SizedBox(width: kS6),
        Text(
          _elapsedFormatted,
          style: const TextStyle(
            color: kErrorRed,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordButton() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring when idle
          if (!_recording)
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
            onTap: _recording ? _stopAndSubmit : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _recording ? kErrorRed : kAccent,
                boxShadow: [
                  BoxShadow(
                    color: (_recording ? kErrorRed : kAccent).withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _recording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
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
              Text(_error!, textAlign: TextAlign.center),
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

