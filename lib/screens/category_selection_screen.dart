import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/interview_models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  List<InterviewCategory> _categories = [];
  bool _loading = true;

  static const Map<String, String> _descriptions = {
    'software': 'Algorismes, arquitectura, disseny de sistemes i tecnologies web.',
    'data': 'Anàlisi de dades, machine learning i visualització.',
    'design': 'Investigació d\'usuaris, prototipatge i sistemes de disseny.',
    'management': 'Planificació, lideratge d\'equips i gestió àgil.',
    'marketing': 'Estratègia digital, SEO, SEM i xarxes socials.',
    'general': 'Preguntes comportamentals i competències transversals.',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() { _categories = cats; });
    } catch (_) {
      setState(() { _categories = InterviewCategory.defaults(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Nova entrevista'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(kPagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Per a quin lloc de\ntreball et prepares?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: kS8),
                  Text(
                    'Selecciona la categoria que millor descriu el rol.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: kS24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 700 ? 3 : 2;
                      final cats = _categories.isEmpty ? InterviewCategory.defaults() : _categories;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: kS12,
                          mainAxisSpacing: kS12,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: cats.length,
                        itemBuilder: (_, i) => _buildJobCard(cats[i]),
                      );
                    },
                  ),
                  const SizedBox(height: kS24),
                ],
              ),
            ),
    );
  }

  Widget _buildJobCard(InterviewCategory cat) {
    final desc = _descriptions[cat.id] ?? 'Practica entrevistes per a aquest rol.';
    return Material(
      color: kBgSurface,
      borderRadius: BorderRadius.circular(kRadiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusMd),
        onTap: () => context.go('/interview/${cat.id}?name=${Uri.encodeComponent(cat.name)}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusMd),
            border: Border.all(color: kBorderSubtle),
          ),
          padding: const EdgeInsets.all(kS16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(kRadiusMd),
                ),
                child: Icon(cat.icon, color: kAccent, size: 22),
              ),
              const Spacer(),
              Text(cat.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: kS4),
              Text(desc,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
