import 'package:flutter/material.dart';
import '../models/form_section_definition.dart';
import 'section_renderer.dart';

typedef OnFieldChanged = void Function(String fieldId, dynamic value);
typedef OnRepeatableItemChanged = void Function(
    String sectionId, int index, String fieldId, dynamic value);

class ConditionalSectionRenderer extends StatelessWidget {
  final ConditionalSectionDefinition section;
  final Map<String, dynamic> formValues;
  final Map<String, String> errors;
  final OnFieldChanged onFieldChanged;
  final OnRepeatableItemChanged onRepeatableItemChanged;

  const ConditionalSectionRenderer({
    super.key,
    required this.section,
    required this.formValues,
    required this.errors,
    required this.onFieldChanged,
    required this.onRepeatableItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!section.isVisible(formValues)) {
      return const SizedBox.shrink();
    }
    return SectionRenderer(
      section: section,
      formValues: formValues,
      errors: errors,
      onFieldChanged: onFieldChanged,
      onRepeatableItemChanged: onRepeatableItemChanged,
    );
  }
}
