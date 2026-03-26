import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';


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

  static const _infoBullets = [
    'Mantén la calma i respon amb naturalitat.',
    'Intenta parlar durant aproximadament un minut.',
    "Situa't en un lloc ben il·luminat.",
    'No surtis del marc de la càmera, podria afectar la teva avaluació.',
  ];

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
          color: _recording ? kTextDisabled : null,
        ),
        title: Text(_displayName),
        actions: const [],
      ),
      body: SafeArea(
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
                        color: kBgSurface,
                        borderRadius: BorderRadius.circular(kRadiusMd),
                        border: Border.all(color: kBorderSubtle),
                      ),
                      child: Text(
                        question.text,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: kS24),

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
                              : kBorderSubtle;
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
                                  color: kBgElevated,
                                  child: (_camera != null && _camera!.value.isInitialized)
                                      ? CameraPreview(_camera!)
                                      : _buildNoCameraPlaceholder(),
                                ),

                                // Info overlay with frosted glass (fades out on record)
                                AnimatedOpacity(
                                  opacity: _recording ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOut,
                                  child: IgnorePointer(
                                    ignoring: _recording,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(kRadiusMd),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                        child: Container(
                                          color: kBgBase.withValues(alpha: 0.88),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: kS32, vertical: kS24),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.info_outline_rounded,
                                                  color: kAccentSky, size: 28),
                                              const SizedBox(height: kS16),
                                              ..._infoBullets.map((text) => Padding(
                                                padding: const EdgeInsets.only(bottom: kS12),
                                                child: Text(text,
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context)
                                                      .textTheme.bodyMedium?.copyWith(
                                                    color: kAccentSky,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              )),
                                            ],
                                          ),
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
                          backgroundColor: kBorderSubtle,
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
            fontWeight: FontWeight.bold,
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
                    color: (_recording ? kErrorRed : kAccent).withValues(alpha: 0.35),
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
        const Icon(Icons.videocam_off_outlined, size: 40, color: kTextSecondary),
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
                  color: kTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: kS16),
              ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: kS4),
                child: Text(
                  step,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kTextSecondary,
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
              const Icon(Icons.no_photography_rounded, size: 72, color: kTextSecondary),
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

