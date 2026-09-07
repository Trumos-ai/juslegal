enum FormFieldType {
  text,
  textarea,
  number,
  currency,
  date,
  dropdown,
  radio,
  multiSelect,
  toggle,
}

class FieldOption {
  final String value;
  final String label;

  const FieldOption({
    required this.value,
    required this.label,
  });
}

typedef FieldVisibilityCondition = bool Function(Map<String, dynamic> formValues);

class ValidationRule {
  final String type;
  final dynamic param;
  final String message;

  const ValidationRule({
    required this.type,
    this.param,
    required this.message,
  });

  static const String required = 'required';
  static const String minLength = 'minLength';
  static const String maxLength = 'maxLength';
  static const String min = 'min';
  static const String max = 'max';
  static const String pattern = 'pattern';
  static const String email = 'email';
  static const String phone = 'phone';
}

class FormFieldDefinition {
  final String id;
  final String label;
  final String? hint;
  final bool required;
  final FormFieldType type;
  final List<FieldOption>? options;
  final List<ValidationRule> validationRules;
  final dynamic defaultValue;
  final FieldVisibilityCondition? visibilityCondition;
  final bool isNested;

  const FormFieldDefinition({
    required this.id,
    required this.label,
    this.hint,
    this.required = false,
    this.type = FormFieldType.text,
    this.options,
    this.validationRules = const [],
    this.defaultValue,
    this.visibilityCondition,
    this.isNested = false,
  });

  FormFieldDefinition copyWith({
    String? id,
    String? label,
    String? hint,
    bool? required,
    FormFieldType? type,
    List<FieldOption>? options,
    List<ValidationRule>? validationRules,
    dynamic defaultValue,
    FieldVisibilityCondition? visibilityCondition,
    bool? isNested,
  }) {
    return FormFieldDefinition(
      id: id ?? this.id,
      label: label ?? this.label,
      hint: hint ?? this.hint,
      required: required ?? this.required,
      type: type ?? this.type,
      options: options ?? this.options,
      validationRules: validationRules ?? this.validationRules,
      defaultValue: defaultValue ?? this.defaultValue,
      visibilityCondition: visibilityCondition ?? this.visibilityCondition,
      isNested: isNested ?? this.isNested,
    );
  }

  bool isVisible(Map<String, dynamic> formValues) {
    if (visibilityCondition == null) return true;
    return visibilityCondition!(formValues);
  }
}
