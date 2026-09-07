import '../../../constants/document_fields.dart';
import '../models/document_definition.dart';
import '../models/form_field_definition.dart';
import '../models/form_section_definition.dart';

FormSectionDefinition _buildBasicSection({
  required String sectionId,
  required String sectionTitle,
  required List<String> requiredKeys,
  required List<String> optionalKeys,
}) {
  List<FormFieldDefinition> fields = [];

  for (final key in requiredKeys) {
    final label = documentFieldLabels[key] ?? _humanize(key);
    fields.add(FormFieldDefinition(
      id: key,
      label: label,
      hint: 'Enter $label',
      required: true,
      type: _fieldTypeFor(key),
    ));
  }

  for (final key in optionalKeys) {
    final label = documentFieldLabels[key] ?? _humanize(key);
    fields.add(FormFieldDefinition(
      id: key,
      label: label,
      hint: 'Enter $label',
      required: false,
      type: _fieldTypeFor(key),
    ));
  }

  return FormSectionDefinition(
    id: sectionId,
    title: sectionTitle,
    description: 'Fill in the required and optional details below',
    fields: fields,
  );
}

FormFieldType _fieldTypeFor(String key) {
  final lower = key.toLowerCase();
  if (lower.contains('detail') ||
      lower.contains('description') ||
      lower.contains('scope') ||
      lower.contains('term') ||
      lower.contains('clause') ||
      lower.contains('evidence') ||
      lower.contains('content') ||
      lower.contains('facts') ||
      lower.contains('ground') ||
      lower.contains('prayer') ||
      lower.contains('declaration') ||
      lower.contains('responsibilit') ||
      lower.contains('assets') ||
      lower.contains('beneficiar') ||
      lower.contains('powers') ||
      lower.contains('property')) {
    return FormFieldType.textarea;
  }
  if (lower.contains('amount') ||
      lower.contains('price') ||
      lower.contains('rent') ||
      lower.contains('salary') ||
      lower.contains('fee') ||
      lower.contains('deposit') ||
      lower.contains('compensation') ||
      lower.contains('refund') ||
      lower.contains('paid') ||
      lower.contains('value') ||
      lower.contains('income') ||
      lower.contains('bonus') ||
      lower.contains('settlement') ||
      lower.contains('gratuity') ||
      lower.contains('encashment') ||
      lower.contains('cost') ||
      lower.contains('advance') ||
      lower.contains('balance') ||
      lower.contains('contribution') ||
      lower.contains('consideration') ||
      lower.contains('maintenance') ||
      lower.contains('sharing') ||
      lower.contains('rate') ||
      lower.contains('investment')) {
    return FormFieldType.currency;
  }
  if (lower.contains('date')) {
    return FormFieldType.date;
  }
  if (lower.contains('number') ||
      lower.contains('duration') ||
      lower.contains('days') ||
      lower.contains('period') ||
      lower.contains('age') ||
      lower.contains('ratio') ||
      lower.contains('rating')) {
    return FormFieldType.number;
  }
  return FormFieldType.text;
}

String _humanize(String key) => key
    .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
    .replaceAllMapped(RegExp(r'([A-Z]+)([A-Z][a-z])'), (m) => '${m[1]} ${m[2]}')
    .replaceAll('_', ' ')
    .trim();

DocumentDefinition buildMinimalDocumentDefinition({
  required String id,
  required String title,
  required String description,
  required String promptHint,
  required DocumentCategoryType category,
  required List<String> requiredKeys,
  required List<String> optionalKeys,
  String? promptId,
}) {
  return DocumentDefinition(
    id: id,
    title: title,
    description: description,
    promptHint: promptHint,
    category: category,
    promptId: promptId ?? id,
    multiStep: true,
    sections: [
      _buildBasicSection(
        sectionId: 'details',
        sectionTitle: 'Document Details',
        requiredKeys: requiredKeys,
        optionalKeys: optionalKeys,
      ),
      const FormSectionDefinition(
        id: 'review',
        title: 'Review',
        description: 'Review and generate your document',
        fields: [],
      ),
    ],
  );
}
