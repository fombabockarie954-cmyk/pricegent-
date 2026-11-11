import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth_gate.dart';
import 'auth_service.dart';
import 'firebase_config.dart';
import 'study_result_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!PricegentFirebaseConfig.isConfigured) {
    runApp(const PricegentApp());
    return;
  }
  try {
    await Firebase.initializeApp(options: PricegentFirebaseConfig.options);
  } on FirebaseException catch (error) {
    runApp(
      PricegentApp(
        setupMessage:
            'Firebase initialization failed: ${error.message ?? error.code}',
      ),
    );
    return;
  }
  runApp(PricegentApp(authService: FirebaseUserAuthService()));
}

const _ink = Color(0xFF24364B);
const _blue = Color(0xFF486E83);
const _paper = Color(0xFFF7F1E5);
const _saffron = Color(0xFFD7A94A);
const _red = Color(0xFFA44C3E);

class PricegentApp extends StatelessWidget {
  const PricegentApp({this.authService, this.setupMessage, super.key});

  final UserAuthService? authService;
  final String? setupMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _blue,
      brightness: Brightness.light,
      surface: _paper,
      primary: _ink,
      secondary: _saffron,
      error: _red,
    );

    return MaterialApp(
      title: 'Pricegent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _paper,
        textTheme: ThemeData(
          brightness: Brightness.light,
        ).textTheme.apply(bodyColor: _ink, displayColor: _ink),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFAF0),
          hintStyle: const TextStyle(color: _blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFB7B6A9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFB7B6A9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _blue, width: 2),
          ),
        ),
      ),
      home: authService == null
          ? FirebaseSetupPage(message: setupMessage)
          : AuthGate(
              authService: authService!,
              authenticatedBuilder: (context) => StudyHomePage(
                onSignOut: () => authService!.signOut(),
              ),
            ),
    );
  }
}

class Study {
  Study({required this.title, required this.source, required this.createdAt});

  final String title;
  final String source;
  final DateTime createdAt;
}

class StudyHomePage extends StatefulWidget {
  const StudyHomePage({this.onSignOut, super.key});

  final VoidCallback? onSignOut;

  @override
  State<StudyHomePage> createState() => _StudyHomePageState();
}

class _StudyHomePageState extends State<StudyHomePage> {
  final _studies = <Study>[];
  int _tabIndex = 0;

  Future<void> _addStudy() async {
    final study = await Navigator.of(context).push<Study>(
      MaterialPageRoute<Study>(builder: (context) => const AddMaterialPage()),
    );
    if (study == null || !mounted) return;
    setState(() {
      _studies.insert(0, study);
      _tabIndex = 0;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${study.title} added to your studies')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _HomeTab(
              studies: _studies,
              onAddStudy: _addStudy,
              onSignOut: widget.onSignOut,
              onSeeAll: () => setState(() => _tabIndex = 1),
            ),
            _StudiesTab(studies: _studies, onAddStudy: _addStudy),
            const _LibraryTab(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Studies',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.studies,
    required this.onAddStudy,
    required this.onSignOut,
    required this.onSeeAll,
  });

  final List<Study> studies;
  final VoidCallback onAddStudy;
  final VoidCallback? onSignOut;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final recent = studies.take(3).toList();
    return CustomScrollView(
      key: const PageStorageKey<String>('home'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _TopBar(onSignOut: onSignOut),
              const SizedBox(height: 27),
              Text(
                _todayLabel(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _blue,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A clearer path\nto what you learn.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bring a topic. Build understanding you can come back to.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: _blue, height: 1.45),
              ),
              const SizedBox(height: 23),
              _NewStudySection(onAddStudy: onAddStudy),
              const SizedBox(height: 27),
              _SectionHeading(
                title: 'Pick up where you left off',
                action: studies.isEmpty ? null : 'See all',
                onAction: onSeeAll,
              ),
              if (recent.isEmpty)
                const _EmptyStudies()
              else
                ...recent.map(
                  (study) => _StudyRow(
                    study: study,
                    onTap: () => _openStudy(context, study),
                  ),
                ),
              const SizedBox(height: 23),
              _SectionHeading(
                title: 'Your learning shelf',
                action:
                    '${studies.length} ${studies.length == 1 ? 'study' : 'studies'}',
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'pricegent',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        if (onSignOut != null)
          IconButton(
            onPressed: onSignOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          )
        else
          const CircleAvatar(
            radius: 19,
            backgroundColor: _saffron,
            foregroundColor: _ink,
            child: Text('PG', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}

class _NewStudySection extends StatelessWidget {
  const _NewStudySection({required this.onAddStudy});

  final VoidCallback onAddStudy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF0),
        border: Border.all(color: const Color(0xFFDFD4C3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start a new study',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'serif',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Paste notes to make a first study.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _blue),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddStudy,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add material'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class _EmptyStudies extends StatelessWidget {
  const _EmptyStudies();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Text(
        'Your studies will show up here once you add your first notes.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _blue),
      ),
    );
  }
}

class _StudyRow extends StatelessWidget {
  const _StudyRow({required this.study, this.onTap});

  final Study study;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 43,
                decoration: BoxDecoration(
                  color: _saffron,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      study.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${study.source.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length} words · ${_relativeDate(study.createdAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: _blue),
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right, color: _blue),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudiesTab extends StatelessWidget {
  const _StudiesTab({required this.studies, required this.onAddStudy});

  final List<Study> studies;
  final VoidCallback onAddStudy;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('studies'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _TopBar(),
              const SizedBox(height: 28),
              Text(
                'Your studies',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'The ideas you are working through.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: _blue),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAddStudy,
                icon: const Icon(Icons.add),
                label: const Text('Add material'),
              ),
              const SizedBox(height: 16),
              if (studies.isEmpty)
                const _EmptyStudies()
              else
                ...studies.map(
                  (study) => _StudyRow(
                    study: study,
                    onTap: () => _openStudy(context, study),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _TopBar(),
              const SizedBox(height: 28),
              Text(
                'Your library',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Saved explanations and concepts will live here.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: _blue),
              ),
              const SizedBox(height: 22),
              const Icon(Icons.bookmarks_outlined, size: 34, color: _blue),
              const SizedBox(height: 8),
              Text(
                'Nothing saved yet',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Save useful study notes here for later.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _blue),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class AddMaterialPage extends StatefulWidget {
  const AddMaterialPage({super.key});

  @override
  State<AddMaterialPage> createState() => _AddMaterialPageState();
}

class _AddMaterialPageState extends State<AddMaterialPage> {
  final _titleController = TextEditingController();
  final _materialController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  void _createStudy() {
    if (!_formKey.currentState!.validate()) return;
    final material = _materialController.text.trim();
    final title = _titleController.text.trim();
    Navigator.of(context).pop(
      Study(
        title: title.isEmpty ? _suggestTitle(material) : title,
        source: material,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add learning material'),
        backgroundColor: _paper,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
            children: [
              Text(
                'Start with what you have.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Paste notes or a passage. Pricegent will keep the source with your study.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: _blue, height: 1.45),
              ),
              const SizedBox(height: 22),
              Text(
                'Study title (optional)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'For example, Cell structure',
                ),
                maxLength: 60,
              ),
              const SizedBox(height: 12),
              Text(
                'Your material',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _materialController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                minLines: 8,
                maxLines: 14,
                maxLength: 20000,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  hintText: 'Paste your notes or a short passage here...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Paste some learning material to continue.';
                  }
                  if (value.trim().split(RegExp(r'\s+')).length < 5) {
                    return 'Add a little more text (at least 5 words).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAF0),
                  border: Border.all(color: const Color(0xFFDFD4C3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This first version saves your text on this screen only. AI explanations, document upload, and permanent storage are not connected yet.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _blue, height: 1.4),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _createStudy,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Create study'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openStudy(BuildContext context, Study study) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) =>
          StudyResultPage(title: study.title, source: study.source),
    ),
  );
}

String _suggestTitle(String material) {
  final firstLine = material
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => 'New study');
  final sentence = firstLine.split(RegExp(r'[.!?]')).first.trim();
  if (sentence.length <= 48) return sentence;
  return '${sentence.substring(0, 45).trimRight()}...';
}

String _todayLabel() {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final now = DateTime.now();
  return '${days[now.weekday - 1].toUpperCase()}, ${months[now.month - 1].toUpperCase()} ${now.day}';
}

String _relativeDate(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  if (difference.inDays < 1) return 'Today';
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays} days ago';
}
