import 'package:flutter/material.dart';

// ── Categories ───────────────────────────────────────────────────────────────

class InterviewCategory {
  final String id;
  final String name;
  final IconData icon;
  final String? description;

  InterviewCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
  });

  /// Maps category name (nom) to a Flutter icon using keyword matching.
  static IconData _iconFromName(String nom) {
    final lower = nom.toLowerCase();
    const mapping = <String, IconData>{
      'software': Icons.code,
      'enginyer': Icons.code,
      'dades': Icons.analytics,
      'disseny': Icons.design_services,
      'ux': Icons.design_services,
      'projecte': Icons.people,
      'marketing': Icons.campaign,
      'financ': Icons.account_balance,
      'comptab': Icons.account_balance,
      'vend': Icons.storefront,
      'recurs': Icons.groups,
      'humans': Icons.groups,
      'legal': Icons.gavel,
      'assessor': Icons.gavel,
      'salut': Icons.local_hospital,
      'medic': Icons.local_hospital,
      'school': Icons.school,
      'devops': Icons.cloud,
      'cloud': Icons.cloud,
      'ciberseg': Icons.shield,
      'seguretat': Icons.shield,
      'product': Icons.rocket_launch,
      'general': Icons.work_outline,
    };
    for (final entry in mapping.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.work;
  }

  factory InterviewCategory.fromJson(Map<String, dynamic> json) {
    final nom = json['nom'] as String? ?? '';
    return InterviewCategory(
      id: json['id'].toString(),
      name: nom,
      icon: _iconFromName(nom),
      description: json['descripcio'] as String?,
    );
  }

  static List<InterviewCategory> defaults() => [
        InterviewCategory(id: '0', name: 'Enginyeria de Software', icon: Icons.code, description: 'Algorismes, arquitectura i sistemes'),
        InterviewCategory(id: '0', name: 'Disseny UX/UI', icon: Icons.design_services, description: 'UX/UI, prototipatge i recerca'),
        InterviewCategory(id: '0', name: 'General', icon: Icons.work_outline, description: 'General'),
      ];
}

// ── Questions ────────────────────────────────────────────────────────────────

class Question {
  final String id;
  final String text;
  final String categoryId;

  Question({required this.id, required this.text, required this.categoryId});

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'].toString(),
        text: json['text_pregunta'] as String? ?? '',
        categoryId: json['id_categoria']?.toString() ?? '',
      );

  static List<Question> fallback() => [
        Question(id: '0', text: "Explica'm un repte que hagis resolt recentment.", categoryId: '0'),
        Question(id: '0', text: 'Quines son les teves principals fortaleses?', categoryId: '0'),
        Question(id: '0', text: "On et veus d'aqui a cinc anys?", categoryId: '0'),
      ];
}

// ── Interview Sessions ───────────────────────────────────────────────────────

class InterviewSession {
  final String id;
  final int? questionId;
  final DateTime date;
  final String status;
  final String? videoUrl;
  final String? pdfUrl;
  final Map<String, dynamic>? metriques;
  String? categoryName;
  String? questionText;

  InterviewSession({
    required this.id,
    this.questionId,
    required this.date,
    required this.status,
    this.videoUrl,
    this.pdfUrl,
    this.metriques,
    this.categoryName,
    this.questionText,
  });

  factory InterviewSession.fromJson(Map<String, dynamic> json) =>
      InterviewSession(
        id: json['id'].toString(),
        questionId: json['id_pregunta'] as int?,
        date: DateTime.parse(json['data_hora'] as String),
        status: json['estat_proces'] as String? ?? 'pendent',
        videoUrl: json['url_video'] as String?,
        pdfUrl: json['url_informe_pdf'] as String?,
        metriques: json['metriques'] as Map<String, dynamic>?,
      );

  bool get isCompleted => status == 'completat';
  bool get isProcessing => status == 'processant';
  bool get isError => status == 'error';
  bool get isPending => status == 'pendent';

  String get statusLabel {
    switch (status) {
      case 'completat': return 'Completada';
      case 'processant': return 'Processant...';
      case 'pendent': return 'Pendent';
      case 'error': return 'Error';
      default: return status;
    }
  }

  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double? get overallScore {
    if (metriques == null || !isCompleted) return null;
    return InterviewResult._computeOverallFromMetriques(metriques!);
  }
}

// ── Interview Results ────────────────────────────────────────────────────────

class InterviewResult {
  final int interviewId;
  final String status;
  final String? transcript;
  final String? questionText;

  final double? durationTotal;
  final double? activeSpeechTime;
  final double? confidenceIndex;
  final double? communicationRhythmWpm;

  final double? questionAlignment;
  final double? discourseCoherence;
  final double? informationDensity;
  final double? specificityIndex;
  final double? lexicalRichness;

  final Map<String, double>? emotionDistribution;
  final String? dominantEmotion;
  final double? emotionalConsistency;

  final String? llmFeedback;
  final double? answerQualityScore;

  InterviewResult({
    required this.interviewId,
    required this.status,
    this.transcript,
    this.questionText,
    this.durationTotal,
    this.activeSpeechTime,
    this.confidenceIndex,
    this.communicationRhythmWpm,
    this.questionAlignment,
    this.discourseCoherence,
    this.informationDensity,
    this.specificityIndex,
    this.lexicalRichness,
    this.emotionDistribution,
    this.dominantEmotion,
    this.emotionalConsistency,
    this.llmFeedback,
    this.answerQualityScore,
  });

  // ── Derived scores (client-side heuristics, 0-100) ──

  double get wordsPerMinute => communicationRhythmWpm ?? 0;
  double get confidenceScore => (confidenceIndex ?? 0) * 100;

  double get contentScore {
    final values = [questionAlignment, informationDensity, specificityIndex]
        .whereType<double>().toList();
    if (values.isEmpty) return 0;
    return (values.reduce((a, b) => a + b) / values.length) * 100;
  }

  double get fluencyScore {
    final sr = (durationTotal != null && durationTotal! > 0 && activeSpeechTime != null)
        ? (activeSpeechTime! / durationTotal!).clamp(0.0, 1.0) : 0.0;
    final wpmNorm = communicationRhythmWpm != null
        ? (1.0 - ((communicationRhythmWpm! - 145).abs() / 145)).clamp(0.0, 1.0) : 0.0;
    return (sr * 0.5 + wpmNorm * 0.5) * 100;
  }

  double get structureScore => (discourseCoherence ?? 0) * 100;
  double get lexicalScore => (lexicalRichness ?? 0) * 100;
  double get answerQualityPercent => (answerQualityScore ?? 0) * 100;

  double get overallScore {
    final scores = [contentScore, fluencyScore, structureScore, confidenceScore, answerQualityPercent];
    if (scores.every((s) => s == 0)) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  double get speechRatio {
    if (durationTotal == null || durationTotal! <= 0 || activeSpeechTime == null) return 0;
    return ((activeSpeechTime! / durationTotal!) * 100).clamp(0, 100);
  }

  static double? _computeOverallFromMetriques(Map<String, dynamic> metriques) {
    try {
      // Reuse the same InterviewResult parsing and score formula
      final result = InterviewResult.fromJson({
        'id_entrevista': 0,
        'estat_proces': 'completat',
        'metriques': metriques,
      });
      final score = result.overallScore;
      return score > 0 ? score : null;
    } catch (_) { return null; }
  }

  factory InterviewResult.fromJson(Map<String, dynamic> json) {
    final metriques = json['metriques'] as Map<String, dynamic>? ?? {};
    final audio = metriques['audio_metrics'] as Map<String, dynamic>? ?? {};
    final text = metriques['text_metrics'] as Map<String, dynamic>? ?? {};
    final video = metriques['video_metrics'] as Map<String, dynamic>? ?? {};

    Map<String, double>? emotionDist;
    if (video['emotion_distribution'] != null) {
      emotionDist = (video['emotion_distribution'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    // confidence_index is a nested object with a 'score' field
    final confidenceRaw = audio['confidence_index'];
    final confidenceVal = confidenceRaw is Map
        ? (confidenceRaw['score'] as num?)?.toDouble()
        : (confidenceRaw as num?)?.toDouble();

    // discourse_coherence is a nested object with a 'global_coherence' field
    final coherenceRaw = text['discourse_coherence'];
    final coherenceVal = coherenceRaw is Map
        ? (coherenceRaw['global_coherence'] as num?)?.toDouble()
        : (coherenceRaw as num?)?.toDouble();

    return InterviewResult(
      interviewId: json['id_entrevista'] as int? ?? 0,
      status: json['estat_proces'] as String? ?? 'pendent',
      transcript: metriques['transcript'] as String?,
      questionText: null,
      durationTotal: (audio['duration_total'] as num?)?.toDouble(),
      activeSpeechTime: (audio['active_speech_time'] as num?)?.toDouble(),
      confidenceIndex: confidenceVal,
      communicationRhythmWpm: (audio['communication_rhythm_wpm'] as num?)?.toDouble(),
      questionAlignment: (text['question_alignment'] as num?)?.toDouble(),
      discourseCoherence: coherenceVal,
      informationDensity: (text['information_density'] as num?)?.toDouble(),
      specificityIndex: (text['specificity_index'] as num?)?.toDouble(),
      lexicalRichness: (text['lexical_richness'] as num?)?.toDouble(),
      emotionDistribution: emotionDist,
      dominantEmotion: video['dominant_emotion'] as String?,
      emotionalConsistency: (video['emotional_stability'] as num?)?.toDouble(),
      llmFeedback: metriques['llm_feedback'] as String?,
      answerQualityScore: (metriques['answer_quality_score'] as num?)?.toDouble(),
    );
  }

  static InterviewResult mock() => InterviewResult(
        interviewId: 0,
        status: 'completat',
        transcript: 'He treballat en diversos projectes de software. '
            "El meu enfocament principal es assegurar la qualitat del codi.",
        questionText: 'Explica la teva experiència professional més rellevant.',
        durationTotal: 120.0,
        activeSpeechTime: 95.0,
        confidenceIndex: 0.72,
        communicationRhythmWpm: 142.0,
        questionAlignment: 0.78,
        discourseCoherence: 0.75,
        informationDensity: 0.65,
        specificityIndex: 0.70,
        lexicalRichness: 0.68,
        emotionDistribution: {'neutral': 0.55, 'happy': 0.25, 'surprise': 0.10, 'sad': 0.05, 'angry': 0.05},
        dominantEmotion: 'neutral',
        emotionalConsistency: 0.78,
        llmFeedback: "La teva resposta mostra una bona comprensió del tema. "
            "Has mantingut un to professional i has donat exemples concrets. "
            "Per millorar, podries estructurar millor la teva resposta seguint "
            "el mètode STAR (Situació, Tasca, Acció, Resultat) i reduir les "
            "pauses llargues entre idees.",
        answerQualityScore: 0.72,
      );
}