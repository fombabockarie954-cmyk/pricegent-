import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'learning_service.dart';
import 'study_report.dart';

const _ink = Color(0xFF24364B);
const _blue = Color(0xFF486E83);
const _paper = Color(0xFFF7F1E5);
const _saffron = Color(0xFFD7A94A);
const _red = Color(0xFFA44C3E);
const _green = Color(0xFF426B58);

class StudyResultPage extends StatefulWidget {
  const StudyResultPage({
    super.key,
    required this.title,
    required this.source,
    this.learningService,
  });

  final String title;
  final String source;
  final LearningService? learningService;

  @override
  State<StudyResultPage> createState() => _StudyResultPageState();
}

class _StudyResultPageState extends State<StudyResultPage> {
  late final LearningService _learningService =
      widget.learningService ?? ApiLearningService();
  StudyReport? _report;
  Uint8List? _crossSectionImage;
  String? _error;
  String? _illustrationError;
  bool _isLoading = false;
  bool _isGeneratingIllustration = false;

  @override
  void dispose() {
    _learningService.close();
    super.dispose();
  }

  Future<void> _buildStudyGuide() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await _learningService.processStudy(
        title: widget.title,
        source: widget.source,
      );
      if (!mounted) return;
      setState(() => _report = report);
    } on LearningServiceException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateCrossSectionImage() async {
    setState(() {
      _isGeneratingIllustration = true;
      _illustrationError = null;
    });

    try {
      final image = await _learningService.generateCrossSectionImage(
        title: widget.title,
        source: widget.source,
      );
      if (!mounted) return;
      setState(() => _crossSectionImage = image);
    } on LearningServiceException catch (error) {
      if (!mounted) return;
      setState(() => _illustrationError = error.message);
    } finally {
      if (mounted) setState(() => _isGeneratingIllustration = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study guide'), backgroundColor: _paper),
      body: _report == null
          ? _buildSourceView(context)
          : _StudyReportView(
              report: _report!,
              crossSectionImage: _crossSectionImage,
              isGeneratingIllustration: _isGeneratingIllustration,
              illustrationError: _illustrationError,
              onGenerateIllustration: _generateCrossSectionImage,
            ),
    );
  }

  Widget _buildSourceView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your source · ${widget.source.length} characters',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _blue),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isLoading ? null : _buildStudyGuide,
          icon: _isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_outlined),
          label: Text(
            _isLoading ? 'Building your guide...' : 'Build my study guide',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'When you tap, this text is sent to the model configured for Pricegent. Avoid pasting private or sensitive material. Your original text stays available below.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: _blue, height: 1.4),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 16),
          _ErrorNotice(message: error, onRetry: _buildStudyGuide),
        ],
        const SizedBox(height: 22),
        Text(
          'Original material',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        SelectableText(widget.source),
      ],
    );
  }
}

class _StudyReportView extends StatelessWidget {
  const _StudyReportView({
    required this.report,
    required this.crossSectionImage,
    required this.isGeneratingIllustration,
    required this.illustrationError,
    required this.onGenerateIllustration,
  });

  final StudyReport report;
  final Uint8List? crossSectionImage;
  final bool isGeneratingIllustration;
  final String? illustrationError;
  final Future<void> Function() onGenerateIllustration;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 36),
      children: [
        Text(
          'The big idea',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(report.summary, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 14),
        _PrincipleLine(text: report.fundamentalPrinciple),
        const SizedBox(height: 26),
        Text(
          'Ideas from your material',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        ...report.concepts.map(
          (concept) => _ConceptDefinition(concept: concept),
        ),
        const SizedBox(height: 20),
        const _SeePath(),
        const SizedBox(height: 14),
        _SeeSection(
          title: 'Sense',
          subtitle: 'Find the signal',
          color: _blue,
          icon: Icons.center_focus_strong_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.see.sense.centralIdea),
              const SizedBox(height: 12),
              _SourceQuote(text: report.see.sense.sourceEvidence),
            ],
          ),
        ),
        _SeeSection(
          title: 'Exaggerate',
          subtitle: 'Make the mechanism vivid',
          color: _red,
          icon: Icons.zoom_out_map,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.see.exaggerate.imaginedScene,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              _RealityNote(
                label: 'What stays true',
                color: _green,
                text: report.see.exaggerate.whatStaysTrue,
              ),
              const SizedBox(height: 10),
              _RealityNote(
                label: 'Where imagination stops',
                color: _red,
                text: report.see.exaggerate.whereItBreaks,
              ),
            ],
          ),
        ),
        _SeeSection(
          title: 'Energize',
          subtitle: 'Carry the idea into the world',
          color: _green,
          icon: Icons.bolt_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.see.energize.realWorldApplication),
              const SizedBox(height: 12),
              _TryThis(text: report.see.energize.tryThis),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'How the ideas connect',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Move around the map to explore the relationships.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _blue),
        ),
        const SizedBox(height: 10),
        _ConceptMap(report: report),
        const SizedBox(height: 22),
        _CrossSectionIllustration(
          report: report,
          image: crossSectionImage,
          isGenerating: isGeneratingIllustration,
          error: illustrationError,
          onGenerate: onGenerateIllustration,
        ),
        const SizedBox(height: 22),
        Text(
          'Try it from memory',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Take a guess before opening an answer.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _blue),
        ),
        const SizedBox(height: 8),
        ...report.recallQuestions.map(
          (question) => _RecallPrompt(question: question),
        ),
      ],
    );
  }
}

class _CrossSectionIllustration extends StatelessWidget {
  const _CrossSectionIllustration({
    required this.report,
    required this.image,
    required this.isGenerating,
    required this.error,
    required this.onGenerate,
  });

  final StudyReport report;
  final Uint8List? image;
  final bool isGenerating;
  final String? error;
  final Future<void> Function() onGenerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cross-section illustration',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Generate a labeled visual from your study material.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _blue),
        ),
        const SizedBox(height: 10),
        if (image case final illustration?)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              illustration,
              width: double.infinity,
              fit: BoxFit.contain,
              semanticLabel: 'Generated cross-section illustration',
              errorBuilder: (context, error, stackTrace) => const Text(
                'The generated illustration could not be displayed.',
              ),
            ),
          ),
        if (image != null) ...[
          const SizedBox(height: 10),
          Text(
            'Concept labels',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: [
              for (final concept in report.concepts)
                Chip(
                  label: Text(concept.name),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
        if (isGenerating) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 6),
          Text(
            'Drawing your study illustration…',
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: _blue),
          ),
        ] else ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => onGenerate(),
            icon: Icon(
              image == null ? Icons.image_outlined : Icons.refresh,
            ),
            label: Text(
              image == null
                  ? 'Generate illustration'
                  : 'Regenerate illustration',
            ),
          ),
        ],
        if (error case final message?) ...[
          const SizedBox(height: 8),
          _ErrorNotice(message: message, onRetry: () => onGenerate()),
        ],
      ],
    );
  }
}

class _PrincipleLine extends StatelessWidget {
  const _PrincipleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF0),
        border: Border.all(color: const Color(0xFFDFD4C3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.push_pin_outlined, color: _saffron, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptDefinition extends StatelessWidget {
  const _ConceptDefinition({required this.concept});

  final StudyConcept concept;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            concept.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(concept.definition),
          const SizedBox(height: 8),
          _SourceQuote(text: concept.sourceQuote),
        ],
      ),
    );
  }
}

class _SourceQuote extends StatelessWidget {
  const _SourceQuote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF0),
        border: Border.all(color: const Color(0xFFDFD4C3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'From your source: “$text”',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: _blue, height: 1.4),
      ),
    );
  }
}

class _SeePath extends StatelessWidget {
  const _SeePath();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('SENSE', _blue),
      ('EXAGGERATE', _red),
      ('ENERGIZE', _green),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: steps[index].$2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              steps[index].$1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: steps[index].$2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
          if (index != steps.length - 1)
            const Icon(Icons.arrow_forward, size: 14, color: _blue),
        ],
      ],
    );
  }
}

class _SeeSection extends StatelessWidget {
  const _SeeSection({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 9),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.only(left: 29), child: child),
        ],
      ),
    );
  }
}

class _RealityNote extends StatelessWidget {
  const _RealityNote({
    required this.label,
    required this.color,
    required this.text,
  });

  final String label;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
              children: [
                TextSpan(
                  text: '$label. ',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TryThis extends StatelessWidget {
  const _TryThis({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF0),
        border: Border.all(color: const Color(0xFFDFD4C3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.play_arrow, color: _green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Try this: $text',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptMap extends StatefulWidget {
  const _ConceptMap({required this.report});

  final StudyReport report;

  @override
  State<_ConceptMap> createState() => _ConceptMapState();
}

class _ConceptMapState extends State<_ConceptMap> {
  static const _canvasSize = Size(720, 410);
  static const _nodeSize = Size(156, 100);

  String? _selectedConceptId;

  List<Offset> _nodeOrigins(int count) {
    if (count == 1) return const [Offset(282, 165)];
    final points = <Offset>[const Offset(282, 165)];
    for (var index = 1; index < count; index++) {
      final angle = -math.pi / 2 + ((index - 1) * 2 * math.pi / (count - 1));
      points.add(
        Offset(282 + 205 * math.cos(angle), 165 + 135 * math.sin(angle)),
      );
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final concepts = widget.report.concepts;
    final positions = _nodeOrigins(concepts.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 330,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFAF0),
            border: Border.all(color: const Color(0xFFDFD4C3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: InteractiveViewer(
              minScale: 0.7,
              maxScale: 2,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(30),
              child: SizedBox(
                width: _canvasSize.width,
                height: _canvasSize.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RelationshipPainter(
                          concepts: concepts,
                          relationships: widget.report.relationships,
                          origins: positions,
                          nodeSize: _nodeSize,
                        ),
                      ),
                    ),
                    for (var index = 0; index < concepts.length; index++)
                      Positioned(
                        left: positions[index].dx,
                        top: positions[index].dy,
                        width: _nodeSize.width,
                        height: _nodeSize.height,
                        child: _MapNode(
                          concept: concepts[index],
                          isRoot: index == 0,
                          selected: _selectedConceptId == concepts[index].id,
                          onTap: () => setState(
                            () => _selectedConceptId =
                                _selectedConceptId == concepts[index].id
                                    ? null
                                    : concepts[index].id,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_selectedConceptId case final selectedId?)
          ...widget.report.concepts
              .where((concept) => concept.id == selectedId)
              .map(
                (concept) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${concept.name}: ${concept.definition}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
      ],
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({
    required this.concept,
    required this.isRoot,
    required this.selected,
    required this.onTap,
  });

  final StudyConcept concept;
  final bool isRoot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isRoot ? _ink : const Color(0xFFF7F1E5);
    final foreground = isRoot ? const Color(0xFFFFFAF0) : _ink;
    return Semantics(
      button: true,
      selected: selected,
      label: '${concept.name}. ${concept.definition}',
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? _saffron : _blue, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  concept.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  concept.definition,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isRoot
                            ? const Color(0xFFE6DFD2)
                            : const Color(0xFF3D596B),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelationshipPainter extends CustomPainter {
  const _RelationshipPainter({
    required this.concepts,
    required this.relationships,
    required this.origins,
    required this.nodeSize,
  });

  final List<StudyConcept> concepts;
  final List<ConceptRelationship> relationships;
  final List<Offset> origins;
  final Size nodeSize;

  @override
  void paint(Canvas canvas, Size size) {
    final centers = <String, Offset>{
      for (var index = 0; index < concepts.length; index++)
        concepts[index].id:
            origins[index] + Offset(nodeSize.width / 2, nodeSize.height / 2),
    };
    final paint = Paint()
      ..color = _saffron
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final relationship in relationships) {
      final start = centers[relationship.sourceId];
      final end = centers[relationship.targetId];
      if (start == null || end == null) continue;

      final delta = end - start;
      final distance = delta.distance;
      if (distance == 0) continue;
      final direction = delta / distance;
      final nodeRadius = math.min(nodeSize.width, nodeSize.height) / 2 + 3;
      final lineStart = start + direction * nodeRadius;
      final lineEnd = end - direction * nodeRadius;
      canvas.drawLine(lineStart, lineEnd, paint);

      final perpendicular = Offset(-direction.dy, direction.dx);
      final arrowBase = lineEnd - direction * 9;
      final path = Path()
        ..moveTo(lineEnd.dx, lineEnd.dy)
        ..lineTo(
          arrowBase.dx + perpendicular.dx * 4,
          arrowBase.dy + perpendicular.dy * 4,
        )
        ..lineTo(
          arrowBase.dx - perpendicular.dx * 4,
          arrowBase.dy - perpendicular.dy * 4,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = _saffron
          ..style = PaintingStyle.fill,
      );

      final label = relationship.relation.replaceAll('_', ' ');
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: _ink,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 130);
      final midpoint = Offset(
        (lineStart.dx + lineEnd.dx) / 2,
        (lineStart.dy + lineEnd.dy) / 2,
      );
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: midpoint,
          width: textPainter.width + 10,
          height: textPainter.height + 5,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        labelRect,
        Paint()
          ..color = const Color(0xFFFFFAF0)
          ..style = PaintingStyle.fill,
      );
      textPainter.paint(
        canvas,
        midpoint - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RelationshipPainter oldDelegate) =>
      oldDelegate.relationships != relationships ||
      oldDelegate.concepts != concepts ||
      oldDelegate.origins != origins;
}

class _RecallPrompt extends StatefulWidget {
  const _RecallPrompt({required this.question});

  final RecallQuestion question;

  @override
  State<_RecallPrompt> createState() => _RecallPromptState();
}

class _RecallPromptState extends State<_RecallPrompt> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(widget.question.question),
      subtitle: Text(_levelLabel(widget.question.level)),
      onExpansionChanged: (expanded) => setState(() => _showAnswer = expanded),
      children: [
        if (_showAnswer)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Answer: ${widget.question.answer}'),
            ),
          ),
      ],
    );
  }
}

String _levelLabel(String level) => switch (level) {
      'remember' => 'Remember',
      'explain' => 'Explain',
      'apply' => 'Apply',
      _ => level,
    };

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EB),
        border: Border.all(color: const Color(0xFFCF9A81)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF713A31)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
