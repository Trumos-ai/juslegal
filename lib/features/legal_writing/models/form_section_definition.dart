import 'form_field_definition.dart';

typedef SectionVisibilityCondition = bool Function(Map<String, dynamic> formValues);

class FormSectionDefinition {
  final String id;
  final String title;
  final String? description;
  final List<FormFieldDefinition> fields;

  const FormSectionDefinition({
    required this.id,
    required this.title,
    this.description,
    this.fields = const [],
  });
}

class RepeatableSectionDefinition extends FormSectionDefinition {
  final int minItems;
  final int maxItems;
  final String addButtonLabel;
  final String removeButtonLabel;
  final String itemTitlePrefix;

  const RepeatableSectionDefinition({
    required super.id,
    required super.title,
    super.description,
    required super.fields,
    this.minItems = 1,
    this.maxItems = 10,
    this.addButtonLabel = 'Add Item',
    this.removeButtonLabel = 'Remove',
    this.itemTitlePrefix = 'Item',
  });
}

class ConditionalSectionDefinition extends FormSectionDefinition {
  final SectionVisibilityCondition visibilityCondition;

  const ConditionalSectionDefinition({
    required super.id,
    required super.title,
    super.description,
    super.fields,
    required this.visibilityCondition,
  });

  bool isVisible(Map<String, dynamic> formValues) {
    return visibilityCondition(formValues);
  }
}
