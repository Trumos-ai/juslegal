class DocumentFormData {
  final String documentId;
  final Map<String, dynamic> values;
  final String languageCode;
  final String tone;

  const DocumentFormData({
    required this.documentId,
    this.values = const {},
    this.languageCode = 'en',
    this.tone = 'Formal',
  });

  DocumentFormData copyWith({
    String? documentId,
    Map<String, dynamic>? values,
    String? languageCode,
    String? tone,
  }) {
    return DocumentFormData(
      documentId: documentId ?? this.documentId,
      values: values ?? Map<String, dynamic>.unmodifiable(this.values),
      languageCode: languageCode ?? this.languageCode,
      tone: tone ?? this.tone,
    );
  }

  dynamic getValue(String key, {dynamic defaultValue}) {
    return values[key] ?? defaultValue;
  }

  DocumentFormData setValue(String key, dynamic value) {
    final newValues = Map<String, dynamic>.from(values);
    newValues[key] = value;
    return copyWith(values: newValues);
  }

  List<Map<String, dynamic>> getRepeatable(String key) {
    final value = values[key];
    if (value is List) {
      return value.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  DocumentFormData setRepeatableItem(String key, int index, Map<String, dynamic> item) {
    final list = List<Map<String, dynamic>>.from(getRepeatable(key));
    while (list.length <= index) {
      list.add({});
    }
    list[index] = item;
    return setValue(key, list);
  }

  DocumentFormData addRepeatableItem(String key) {
    final list = List<Map<String, dynamic>>.from(getRepeatable(key));
    list.add({});
    return setValue(key, list);
  }

  DocumentFormData removeRepeatableItem(String key, int index) {
    final list = List<Map<String, dynamic>>.from(getRepeatable(key));
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
    }
    return setValue(key, list);
  }
}
