import '../constants/document_fields.dart';
import '../constants/document_prompts.dart';
import 'ai_service.dart';

class DocumentGenerationService {
  final AIService _aiService;

  DocumentGenerationService(this._aiService);

  /// Generate a legal document based on type, form data, and language
  Future<String> generateDocument({
    required String documentType,
    required Map<String, String> formData,
    required String language, // 'Hindi' or 'English'
  }) async {
    // 1. Get document config
    final config = documentTypeFields[documentType];
    if (config == null) {
      throw Exception('Invalid document type: $documentType');
    }

    // 2. Validate all required fields are present
    for (var field in config.required) {
      final value = formData[field]?.trim();
      if (value == null || value.isEmpty) {
        throw Exception('Missing required field: $field');
      }
    }

    // 3. Get prompt template
    final prompts = documentPrompts[documentType];
    if (prompts == null) {
      throw Exception('No prompt template for: $documentType');
    }

    final systemPrompt = prompts['system']!;
    var userPrompt = prompts['user']!;

    // 4. Replace placeholders with actual data
    formData.forEach((key, value) {
      userPrompt = userPrompt.replaceAll('{$key}', value);
    });
    userPrompt = userPrompt.replaceAll('{language}', language);

    // 5. Handle empty optional fields
    userPrompt = userPrompt.replaceAll(RegExp(r'\{[^}]+\}'), '[Not Provided]');

    // 6. Call AI service with proper parameters
    try {
      final response = await _aiService.generateText(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: 0.3, // Low temperature for precise legal documents
      );

      if (response.isEmpty) {
        throw Exception('Empty response from AI service');
      }

      return response;
    } catch (e) {
      throw Exception('Document generation failed: $e');
    }
  }

  /// Get required fields for a document type
  List<String> getRequiredFields(String documentType) {
    final config = documentTypeFields[documentType];
    if (config == null) {
      throw Exception('Invalid document type: $documentType');
    }
    return config.required;
  }

  /// Get optional fields for a document type
  List<String> getOptionalFields(String documentType) {
    final config = documentTypeFields[documentType];
    if (config == null) {
      throw Exception('Invalid document type: $documentType');
    }
    return config.optional;
  }

  /// Get all fields (required + optional) for a document type
  List<String> getAllFields(String documentType) {
    final config = documentTypeFields[documentType];
    if (config == null) {
      throw Exception('Invalid document type: $documentType');
    }
    return [...config.required, ...config.optional];
  }

  /// Get document description
  String getDocumentDescription(String documentType) {
    final config = documentTypeFields[documentType];
    if (config == null) {
      throw Exception('Invalid document type: $documentType');
    }
    return config.description;
  }

  /// Get document category
  String getDocumentCategory(String documentType) {
    final config = documentTypeFields[documentType];
    if (config == null) {
      throw Exception('Invalid document type: $documentType');
    }
    return config.category;
  }

  /// Check if a field is required for a document type
  bool isFieldRequired(String documentType, String fieldKey) {
    final config = documentTypeFields[documentType];
    if (config == null) {
      throw Exception('Invalid document type: $documentType');
    }
    return config.required.contains(fieldKey);
  }

  /// Validate form data for a document type
  Map<String, String> validateFormData(
    String documentType,
    Map<String, String> formData,
  ) {
    final errors = <String, String>{};
    final requiredFields = getRequiredFields(documentType);

    for (var field in requiredFields) {
      final value = formData[field]?.trim();
      if (value == null || value.isEmpty) {
        errors[field] = '$field is required';
      }
    }

    return errors;
  }
}
