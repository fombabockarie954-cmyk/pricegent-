import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:pricegent_mobile/auth_service.dart';
import 'package:pricegent_mobile/learning_service.dart';
import 'package:pricegent_mobile/main.dart';
import 'package:pricegent_mobile/study_report.dart';
import 'package:pricegent_mobile/study_result_page.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('requires Firebase configuration before app use', (tester) async {
    await tester.pumpWidget(const PricegentApp());
    expect(find.textContaining('Firebase is not configured.'), findsOneWidget);
  });

  testWidgets('home opens add-material flow and validates empty input', (
    tester,
  ) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(
      PricegentApp(authService: _FakeAuthService()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add material'));
    await tester.pumpAndSettle();

    expect(find.text('Your material'), findsOneWidget);
    await tester.tap(find.text('Create study'));
    await tester.pumpAndSettle();
    expect(
      find.text('Paste some learning material to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('submitted material opens its study source and build action', (
    tester,
  ) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(
      PricegentApp(authService: _FakeAuthService()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add material'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Photosynthesis');
    await tester.enterText(
      find.byType(TextFormField).last,
      'Photosynthesis converts light energy into chemical energy in plants. '
      'Chlorophyll absorbs sunlight in the leaves.',
    );
    await tester.tap(find.text('Create study'));
    await tester.pumpAndSettle();

    expect(find.text('Photosynthesis'), findsOneWidget);
    await tester.tap(find.text('Photosynthesis'));
    await tester.pumpAndSettle();
    expect(find.text('Original material'), findsOneWidget);
    expect(find.text('Build my study guide'), findsOneWidget);
  });

  testWidgets('study guide shows SEE, concept map, and recall practice', (
    tester,
  ) async {
    _setPhoneSize(tester);
    final service = _FakeLearningService(_sampleReport);
    await tester.pumpWidget(
      MaterialApp(
        home: StudyResultPage(
          title: 'Photosynthesis',
          source: 'Plants absorb light energy. They store energy as glucose. '
              'This process supports life.',
          learningService: service,
        ),
      ),
    );

    await tester.tap(find.text('Build my study guide'));
    await tester.pumpAndSettle();

    expect(find.text('Sense'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Exaggerate'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Exaggerate'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Energize'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Energize'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('How the ideas connect'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('How the ideas connect'), findsOneWidget);
    expect(find.text('Plant cells'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cross-section illustration'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Generate illustration'));
    await tester.pumpAndSettle();
    expect(service.illustrationCalls, 1);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Concept labels'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Try it from memory'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Try it from memory'), findsOneWidget);

    await tester.tap(find.text('What does sunlight provide?'));
    await tester.pumpAndSettle();
    expect(find.text('Answer: Energy.'), findsOneWidget);
  });

  testWidgets('study service failure is visible and can be retried', (
    tester,
  ) async {
    _setPhoneSize(tester);
    final service = _FakeLearningService(
      _sampleReport,
      failure: const LearningServiceException(
        'The learning service is not configured.',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StudyResultPage(
          title: 'Photosynthesis',
          source: 'Plants absorb light energy. They store energy as glucose. '
              'This process supports life.',
          learningService: service,
        ),
      ),
    );

    await tester.tap(find.text('Build my study guide'));
    await tester.pumpAndSettle();
    expect(
      find.text('The learning service is not configured.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(service.calls, 1);
  });

  test('missing API base URL surfaces a clear configuration error', () async {
    final service = ApiLearningService(baseUrl: '');

    await expectLater(
      service.processStudy(title: 'Java', source: 'Java is a modern language.'),
      throwsA(
        isA<LearningServiceException>().having(
          (error) => error.message,
          'message',
          contains('PRICEGENT_API_BASE_URL'),
        ),
      ),
    );

    service.close();
  });

  test('missing default API URL does not try a local backend', () async {
    final requests = <Uri>[];
    final service = ApiLearningService(
      client: _RecordingHttpClient(requests),
    );

    await expectLater(
      service.processStudy(
        title: 'Java',
        source:
            'Java is a modern programming language used for many applications.',
      ),
      throwsA(
        isA<LearningServiceException>().having(
          (error) => error.message,
          'message',
          contains('PRICEGENT_API_BASE_URL'),
        ),
      ),
    );

    expect(requests, isEmpty);
    service.close();
  });

  test('illustration service returns generated image bytes', () async {
    final client = _ImageResponseClient();
    final service = ApiLearningService(
      client: client,
      baseUrl: 'http://example.test',
      tokenProvider: () async => 'test-id-token',
    );

    final image = await service.generateCrossSectionImage(
      title: 'Photosynthesis',
      source: 'Plants absorb light energy and store it as chemical energy.',
    );

    expect(image, [1, 2, 3]);
    expect(
      client.uri,
      Uri.parse('http://example.test/v1/studies/illustrate'),
    );
    expect(
      jsonDecode(client.body!)['title'],
      'Photosynthesis',
    );
    expect(client.authorization, 'Bearer test-id-token');
    service.close();
  });

  test('network errors recommend checking the hosted API URL', () async {
    final service = ApiLearningService(
      client: _FailingHttpClient(http.ClientException('network failure')),
      baseUrl: 'https://api.example.test',
      tokenProvider: () async => 'test-id-token',
    );

    await expectLater(
      service.processStudy(
        title: 'Java',
        source: 'Java is a modern programming language.',
      ),
      throwsA(
        isA<LearningServiceException>().having(
          (error) => error.message,
          'message',
          contains('PRICEGENT_API_BASE_URL'),
        ),
      ),
    );

    service.close();
  });
}

class _FakeAuthService implements UserAuthService {
  @override
  Stream<AuthUser?> get authStateChanges =>
      Stream.value(const AuthUser(id: 'test-user'));

  @override
  Future<String?> getIdToken() async => 'test-id-token';

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeLearningService implements LearningService {
  _FakeLearningService(this.report, {this.failure});

  final StudyReport report;
  final LearningServiceException? failure;
  int calls = 0;
  int illustrationCalls = 0;

  @override
  void close() {}

  @override
  Future<StudyReport> processStudy({
    required String title,
    required String source,
  }) async {
    calls++;
    if (failure case final error?) throw error;
    return report;
  }

  @override
  Future<Uint8List> generateCrossSectionImage({
    required String title,
    required String source,
  }) async {
    illustrationCalls++;
    return base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
    );
  }
}

class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient(this.requests);

  final List<Uri> requests;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url);
    return http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

class _ImageResponseClient extends http.BaseClient {
  Uri? uri;
  String? body;
  String? authorization;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    authorization = request.headers['authorization'];
    body = utf8.decode(await request.finalize().toBytes());
    return http.StreamedResponse(
      Stream.value([1, 2, 3]),
      200,
      headers: const {'content-type': 'image/png'},
    );
  }
}

class _FailingHttpClient extends http.BaseClient {
  _FailingHttpClient(this.error);

  final Exception error;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw error;
  }
}

const _sampleReport = StudyReport(
  summary: 'Plants turn light into stored chemical energy.',
  fundamentalPrinciple: 'Light energy can drive chemical change.',
  concepts: [
    StudyConcept(
      id: 'light',
      name: 'Light energy',
      definition: 'Energy carried by sunlight.',
      sourceQuote: 'Plants absorb light energy.',
    ),
    StudyConcept(
      id: 'chemical',
      name: 'Plant cells',
      definition: 'Cells store energy as glucose.',
      sourceQuote: 'They store energy as glucose.',
    ),
  ],
  relationships: [
    ConceptRelationship(
      sourceId: 'light',
      targetId: 'chemical',
      relation: 'causes',
    ),
  ],
  see: SeeExplanation(
    sense: SenseStep(
      centralIdea: 'Plants store some absorbed light energy.',
      sourceEvidence: 'Plants absorb light energy.',
    ),
    exaggerate: ExaggerateStep(
      conceptId: 'light',
      imaginedScene: 'Imagine each leaf as a tiny solar workshop.',
      whatStaysTrue: 'Light supplies energy to the process.',
      whereItBreaks: 'Leaves are not factories with workers.',
    ),
    energize: EnergizeStep(
      realWorldApplication: 'The stored energy becomes part of food.',
      tryThis: 'Trace the energy path from sunlight to a meal.',
    ),
  ),
  recallQuestions: [
    RecallQuestion(
      question: 'What does sunlight provide?',
      answer: 'Energy.',
      level: 'remember',
    ),
    RecallQuestion(
      question: 'Where is some energy stored?',
      answer: 'In glucose.',
      level: 'explain',
    ),
    RecallQuestion(
      question: 'Trace the energy path.',
      answer: 'From sunlight into stored chemical energy.',
      level: 'apply',
    ),
  ],
);
