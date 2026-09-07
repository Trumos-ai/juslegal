import 'package:flutter_test/flutter_test.dart';
import 'package:juslegal/constants/document_fields.dart';
import 'package:juslegal/features/legal_writing/definitions/document_registry.dart';
import 'package:juslegal/features/legal_writing/models/document_form_data.dart';
import 'package:juslegal/features/legal_writing/prompts/prompt_builder.dart';

const _documentIds = <String>{
  'sale_agreement',
  'partnership_deed',
  'mou_term_sheet',
  'general_affidavit',
  'address_proof_affidavit',
  'name_change_affidavit',
  'income_affidavit',
  'consumer_court_complaint',
  'vakalatnama',
  'bail_application',
};

void main() {
  test('documents 11-20 have a complete, non-overlapping field schema', () {
    for (final documentId in _documentIds) {
      final config = documentTypeFields[documentId]!;
      expect(config.required, isNotEmpty, reason: documentId);
      expect(config.required.toSet().length, config.required.length,
          reason: '$documentId required fields');
      expect(config.optional.toSet().length, config.optional.length,
          reason: '$documentId optional fields');
      expect(config.required.toSet().intersection(config.optional.toSet()),
          isEmpty,
          reason: '$documentId field roles');
    }
  });

  test('documents 11-20 put every supplied form value in the prompt', () {
    for (final documentId in _documentIds) {
      final config = documentTypeFields[documentId]!;
      final values = <String, String>{
        for (final key in [...config.required, ...config.optional])
          key: '$documentId-$key-value',
      };
      final prompt = const PromptBuilder().build(
        definition: getDocumentDefinitionById(documentId)!,
        formData: DocumentFormData(
          documentId: documentId,
          values: values,
        ),
      );

      expect(prompt.systemPrompt, contains('Do not invent facts'));
      expect(prompt.userPrompt, isNot(contains(RegExp(r'\{[^}]+\}'))));
      expect(prompt.userPrompt, isNot(contains('null')));
      expect(prompt.userPrompt, isNot(contains('undefined')));
      expect(prompt.userPrompt, isNot(contains('N/A')));
      for (final value in values.values) {
        expect(prompt.userPrompt, contains(value),
            reason: '$documentId value');
      }
    }
  });
}
