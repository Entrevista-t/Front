import 'package:flutter/material.dart';

class InterviewCategory {
  final String id;
  final String name;
  final IconData icon;

  InterviewCategory({required this.id, required this.name, required this.icon});

  factory InterviewCategory.fromJson(Map<String, dynamic> json) {
    const iconMap = {
      'code': Icons.code,
      'business': Icons.business_center,
      'design': Icons.design_services,
      'data': Icons.analytics,
      'management': Icons.people,
      'marketing': Icons.campaign,
    };
    return InterviewCategory(
      id: json['id'],
      name: json['name'],
      icon: iconMap[json['icon'] as String? ?? ''] ?? Icons.work,
    );
  }

  static List<InterviewCategory> defaults() => [
        InterviewCategory(id: 'software', name: 'Enginyeria de Software', icon: Icons.code),
        InterviewCategory(id: 'data', name: 'Ciència de Dades', icon: Icons.analytics),
        InterviewCategory(id: 'design', name: 'Disseny UX/UI', icon: Icons.design_services),
        InterviewCategory(id: 'management', name: 'Gestió de Projectes', icon: Icons.people),
        InterviewCategory(id: 'marketing', name: 'Màrqueting Digital', icon: Icons.campaign),
        InterviewCategory(id: 'general', name: 'General', icon: Icons.work_outline),
      ];
}

class InterviewSession {
  final String id;
  final String categoryName;
  final double overallScore;
  final DateTime date;

  InterviewSession({
    required this.id,
    required this.categoryName,
    required this.overallScore,
    required this.date,
  });

  factory InterviewSession.fromJson(Map<String, dynamic> json) => InterviewSession(
        id: json['id'],
        categoryName: json['category_name'],
        overallScore: (json['overall_score'] as num).toDouble(),
        date: DateTime.parse(json['created_at']),
      );

  String get formattedDate => '${date.day}/${date.month}/${date.year}';
}

class Question {
  final String id;
  final String text;
  final String category;

  Question({required this.id, required this.text, required this.category});

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'],
        text: json['text'],
        category: json['category'] as String? ?? '',
      );

  static List<Question> fallback() => [
        Question(
          id: '1',
          text: "Explica'm un repte tècnic que hagis resolt recentment.",
          category: 'Experiència',
        ),
        Question(
          id: '2',
          text: 'Quines són les teves principals fortaleses professionals?',
          category: 'Personal',
        ),
        Question(
          id: '3',
          text: "On et veus d'aquí a cinc anys?",
          category: 'Motivació',
        ),
      ];
}

class InterviewResult {
  final String sessionId;
  final String categoryName;
  final double overallScore;
  final double wordsPerMinute;
  final double eyeContactPercent;
  final int excessivePauses;
  final int fillerWordsCount;
  final double contentScore;
  final double fluencyScore;
  final double structureScore;
  final double confidenceScore;
  final String aiFeedback;
  final List<String> strengths;
  final List<String> improvements;
  final DateTime date;

  InterviewResult({
    required this.sessionId,
    required this.categoryName,
    required this.overallScore,
    required this.wordsPerMinute,
    required this.eyeContactPercent,
    required this.excessivePauses,
    required this.fillerWordsCount,
    required this.contentScore,
    required this.fluencyScore,
    required this.structureScore,
    required this.confidenceScore,
    required this.aiFeedback,
    required this.strengths,
    required this.improvements,
    required this.date,
  });

  String get formattedDate => '${date.day}/${date.month}/${date.year}';

  factory InterviewResult.fromJson(Map<String, dynamic> json) => InterviewResult(
        sessionId: json['session_id'],
        categoryName: json['category_name'],
        overallScore: (json['overall_score'] as num).toDouble(),
        wordsPerMinute: (json['words_per_minute'] as num).toDouble(),
        eyeContactPercent: (json['eye_contact_percent'] as num).toDouble(),
        excessivePauses: json['excessive_pauses'] as int,
        fillerWordsCount: json['filler_words_count'] as int,
        contentScore: (json['content_score'] as num).toDouble(),
        fluencyScore: (json['fluency_score'] as num).toDouble(),
        structureScore: (json['structure_score'] as num).toDouble(),
        confidenceScore: (json['confidence_score'] as num).toDouble(),
        aiFeedback: json['ai_feedback'],
        strengths: List<String>.from(json['strengths']),
        improvements: List<String>.from(json['improvements']),
        date: DateTime.parse(json['created_at']),
      );

  static InterviewResult mock() => InterviewResult(
        sessionId: 'mock',
        categoryName: 'Enginyeria de Software',
        overallScore: 74,
        wordsPerMinute: 142,
        eyeContactPercent: 68,
        excessivePauses: 3,
        fillerWordsCount: 7,
        contentScore: 80,
        fluencyScore: 65,
        structureScore: 75,
        confidenceScore: 70,
        aiFeedback:
            'Has demostrat un bon coneixement tècnic i has estructurat bé la resposta. '
            'No obstant, es detecten algunes pauses excessives que podrien millorar la fluïdesa general. '
            'Intenta reduir l\'ús de paraules falca i mantenir el contacte visual de manera més consistent.',
        strengths: [
          'Contingut tècnic sòlid',
          'Bona estructura de la resposta',
          'Vocabulari adequat al context',
        ],
        improvements: [
          'Reduir pauses excessives',
          'Menys paraules falca (e.g. "o sigui", "eh")',
          'Millorar el contacte visual constant',
        ],
        date: DateTime.now(),
      );
}
