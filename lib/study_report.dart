class StudyReport {
  const StudyReport({
    required this.summary,
    required this.fundamentalPrinciple,
    required this.concepts,
    required this.relationships,
    required this.see,
    required this.recallQuestions,
  });

  factory StudyReport.fromJson(Map<String, dynamic> json) {
    return StudyReport(
      summary: json['summary'] as String,
      fundamentalPrinciple: json['fundamental_principle'] as String,
      concepts: (json['concepts'] as List<dynamic>)
          .map((item) => StudyConcept.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      relationships: (json['relationships'] as List<dynamic>)
          .map(
            (item) =>
                ConceptRelationship.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      see: SeeExplanation.fromJson(json['see'] as Map<String, dynamic>),
      recallQuestions: (json['recall_questions'] as List<dynamic>)
          .map((item) => RecallQuestion.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String summary;
  final String fundamentalPrinciple;
  final List<StudyConcept> concepts;
  final List<ConceptRelationship> relationships;
  final SeeExplanation see;
  final List<RecallQuestion> recallQuestions;
}

class StudyConcept {
  const StudyConcept({
    required this.id,
    required this.name,
    required this.definition,
    required this.sourceQuote,
  });

  factory StudyConcept.fromJson(Map<String, dynamic> json) => StudyConcept(
    id: json['id'] as String,
    name: json['name'] as String,
    definition: json['definition'] as String,
    sourceQuote: json['source_quote'] as String,
  );

  final String id;
  final String name;
  final String definition;
  final String sourceQuote;
}

class ConceptRelationship {
  const ConceptRelationship({
    required this.sourceId,
    required this.targetId,
    required this.relation,
  });

  factory ConceptRelationship.fromJson(Map<String, dynamic> json) =>
      ConceptRelationship(
        sourceId: json['source_id'] as String,
        targetId: json['target_id'] as String,
        relation: json['relation'] as String,
      );

  final String sourceId;
  final String targetId;
  final String relation;
}

class SeeExplanation {
  const SeeExplanation({
    required this.sense,
    required this.exaggerate,
    required this.energize,
  });

  factory SeeExplanation.fromJson(Map<String, dynamic> json) => SeeExplanation(
    sense: SenseStep.fromJson(json['sense'] as Map<String, dynamic>),
    exaggerate: ExaggerateStep.fromJson(
      json['exaggerate'] as Map<String, dynamic>,
    ),
    energize: EnergizeStep.fromJson(json['energize'] as Map<String, dynamic>),
  );

  final SenseStep sense;
  final ExaggerateStep exaggerate;
  final EnergizeStep energize;
}

class SenseStep {
  const SenseStep({required this.centralIdea, required this.sourceEvidence});

  factory SenseStep.fromJson(Map<String, dynamic> json) => SenseStep(
    centralIdea: json['central_idea'] as String,
    sourceEvidence: json['source_evidence'] as String,
  );

  final String centralIdea;
  final String sourceEvidence;
}

class ExaggerateStep {
  const ExaggerateStep({
    required this.conceptId,
    required this.imaginedScene,
    required this.whatStaysTrue,
    required this.whereItBreaks,
  });

  factory ExaggerateStep.fromJson(Map<String, dynamic> json) => ExaggerateStep(
    conceptId: json['concept_id'] as String,
    imaginedScene: json['imagined_scene'] as String,
    whatStaysTrue: json['what_stays_true'] as String,
    whereItBreaks: json['where_it_breaks'] as String,
  );

  final String conceptId;
  final String imaginedScene;
  final String whatStaysTrue;
  final String whereItBreaks;
}

class EnergizeStep {
  const EnergizeStep({
    required this.realWorldApplication,
    required this.tryThis,
  });

  factory EnergizeStep.fromJson(Map<String, dynamic> json) => EnergizeStep(
    realWorldApplication: json['real_world_application'] as String,
    tryThis: json['try_this'] as String,
  );

  final String realWorldApplication;
  final String tryThis;
}

class RecallQuestion {
  const RecallQuestion({
    required this.question,
    required this.answer,
    required this.level,
  });

  factory RecallQuestion.fromJson(Map<String, dynamic> json) => RecallQuestion(
    question: json['question'] as String,
    answer: json['answer'] as String,
    level: json['level'] as String,
  );

  final String question;
  final String answer;
  final String level;
}
