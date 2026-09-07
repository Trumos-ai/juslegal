import '../../../services/ai_service.dart';
import '../engine/form_validator.dart';
import '../models/document_definition.dart';
import '../models/document_form_data.dart';
import '../prompts/prompt_builder.dart';

class DocumentGenerationService {
  final AIService _aiService;
  final FormValidator _validator;
  final PromptBuilder _promptBuilder;

  DocumentGenerationService(this._aiService)
      : _validator = const FormValidator(),
        _promptBuilder = const PromptBuilder();

  Future<String> generateDocument({
    required DocumentDefinition definition,
    required DocumentFormData formData,
  }) async {
    final errors = _validator.validateDocument(
      definition: definition,
      formData: formData,
    );
    if (errors.isNotEmpty) {
      throw ValidationException(errors);
    }

    final prompt = _promptBuilder.build(
      definition: definition,
      formData: formData,
    );

    final raw = await _aiService.generateText(
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      temperature: 0.3,
    );

    String clean = raw.trim();
    if (clean.startsWith('```')) {
      final lines = clean.split('\n');
      if (lines.length > 2) {
        clean = lines.sublist(1, lines.length - 1).join('\n');
      }
    }
    clean = clean
        .replaceAll(RegExp(r'```[a-zA-Z]*\n?'), '')
        .replaceAll('```', '')
        .trim();
    return clean;
  }

  Map<String, String> validate({
    required DocumentDefinition definition,
    required DocumentFormData formData,
  }) {
    return _validator.validateDocument(
      definition: definition,
      formData: formData,
    );
  }
}

class ValidationException implements Exception {
  final Map<String, String> errors;
  ValidationException(this.errors);

  @override
  String toString() =>
      'ValidationException: ${errors.length} error(s) — ${errors.values.first}';
}
