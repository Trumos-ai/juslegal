import '../models/form_field_definition.dart';
import '../models/form_section_definition.dart';
import '../models/document_definition.dart';
import '../models/document_form_data.dart';

class FormValidator {
  const FormValidator();

  Map<String, String> validateField(
    FormFieldDefinition field,
    Map<String, dynamic> formValues,
  ) {
    final errors = <String, String>{};
    final value = formValues[field.id];

    if (!field.isVisible(formValues)) {
      return errors;
    }

    if (field.required) {
      if (value == null || value.toString().trim().isEmpty) {
        errors[field.id] = '${field.label} is required';
        return errors;
      }
    }

    for (final rule in field.validationRules) {
      switch (rule.type) {
        case ValidationRule.required:
          if (value == null || value.toString().trim().isEmpty) {
            errors[field.id] = rule.message;
          }
          break;
        case ValidationRule.minLength:
          final str = value?.toString() ?? '';
          final min = rule.param as int? ?? 0;
          if (str.isNotEmpty && str.length < min) {
            errors[field.id] = rule.message;
          }
          break;
        case ValidationRule.maxLength:
          final str = value?.toString() ?? '';
          final max = rule.param as int? ?? 999999;
          if (str.length > max) {
            errors[field.id] = rule.message;
          }
          break;
        case ValidationRule.min:
          final numValue = num.tryParse(value?.toString() ?? '');
          final minNum = num.tryParse(rule.param.toString());
          if (numValue != null && minNum != null && numValue < minNum) {
            errors[field.id] = rule.message;
          }
          break;
        case ValidationRule.max:
          final numValue = num.tryParse(value?.toString() ?? '');
          final maxNum = num.tryParse(rule.param.toString());
          if (numValue != null && maxNum != null && numValue > maxNum) {
            errors[field.id] = rule.message;
          }
          break;
        case ValidationRule.pattern:
          final str = value?.toString() ?? '';
          final pattern = rule.param as String? ?? '';
          if (str.isNotEmpty && pattern.isNotEmpty) {
            final regex = RegExp(pattern);
            if (!regex.hasMatch(str)) {
              errors[field.id] = rule.message;
            }
          }
          break;
        case ValidationRule.email:
          final str = value?.toString() ?? '';
          if (str.isNotEmpty) {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(str)) {
              errors[field.id] = rule.message;
            }
          }
          break;
        case ValidationRule.phone:
          final str = value?.toString() ?? '';
          if (str.isNotEmpty) {
            final phoneRegex = RegExp(r'^\d{10}$');
            if (!phoneRegex.hasMatch(str.replaceAll(RegExp(r'[\s\-]'), ''))) {
              errors[field.id] = rule.message;
            }
          }
          break;
      }
    }

    return errors;
  }

  Map<String, String> validateSection(
    FormSectionDefinition section,
    Map<String, dynamic> formValues,
  ) {
    final errors = <String, String>{};

    if (section is ConditionalSectionDefinition &&
        !section.isVisible(formValues)) {
      return errors;
    }

    for (final field in section.fields) {
      errors.addAll(validateField(field, formValues));
    }

    return errors;
  }

  Map<String, String> validateRepeatableSection(
    RepeatableSectionDefinition section,
    Map<String, dynamic> formValues,
  ) {
    final errors = <String, String>{};
    final items = formValues[section.id];

    if (items is List) {
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item is Map<String, dynamic>) {
          for (final field in section.fields) {
            final fieldErrors = validateField(field, item);
            fieldErrors.forEach((key, value) {
              errors['${section.id}_${i}_$key'] = value;
            });
          }
        }
      }
    }

    if (items == null || (items is List && items.length < section.minItems)) {
      errors[section.id] =
          'At least ${section.minItems} ${section.itemTitlePrefix}(s) required';
    }

    return errors;
  }

  Map<String, String> validateDocument({
    required DocumentDefinition definition,
    required DocumentFormData formData,
  }) {
    final errors = <String, String>{};
    final values = formData.values;

    for (final section in definition.sections) {
      if (section is RepeatableSectionDefinition) {
        errors.addAll(validateRepeatableSection(section, values));
      } else if (section is ConditionalSectionDefinition) {
        if (section.isVisible(values)) {
          errors.addAll(validateSection(section, values));
        }
      } else {
        errors.addAll(validateSection(section, values));
      }
    }

    return errors;
  }

  bool isValid({
    required DocumentDefinition definition,
    required DocumentFormData formData,
  }) {
    return validateDocument(
          definition: definition,
          formData: formData,
        ).isEmpty;
  }
}
