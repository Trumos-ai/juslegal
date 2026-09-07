import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juslegal/core/core.dart';
import '../models/document_category_model.dart';
import '../models/document_type_model.dart';
import '../services/legal_writing_handler.dart';
import '../constants/document_fields.dart';
import '../widgets/legal_writing/category_step.dart';
import '../features/legal_writing/definitions/document_registry.dart';
import '../features/legal_writing/engine/document_form_screen.dart';
import '../features/legal_writing/models/document_definition.dart';
import '../features/legal_writing/models/form_field_definition.dart';
import '../features/legal_writing/models/form_section_definition.dart';

class LegalWritingScreen extends ConsumerStatefulWidget {
  const LegalWritingScreen({super.key});

  @override
  ConsumerState<LegalWritingScreen> createState() => _LegalWritingScreenState();
}

class _LegalWritingScreenState extends ConsumerState<LegalWritingScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectType(DocumentCategory category, DocumentType type) {
    final definition = getDocumentDefinitionById(type.id)!;
    final docDef = documentTypeFields[type.id];
    final effectiveDefinition = definition.copyWith(
      sections: _sectionsWithConfiguredFields(
        definition,
        type,
        docDef,
      ),
    );
    ref.read(legalWritingProvider.notifier).selectType(category, type);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentFormScreen(
          definition: effectiveDefinition,
          categoryIcon: category.icon,
          categoryLabel: category.label,
          onBackToSelection: () {
            ref.read(legalWritingProvider.notifier).resetToCategory();
          },
        ),
      ),
    );
  }

  List<FormSectionDefinition> _sectionsWithConfiguredFields(
    DocumentDefinition definition,
    DocumentType type,
    DocumentTypeConfig? config,
  ) {
    if (definition.sections.length > 1 || definition.id == 'rent_agreement') {
      return definition.sections;
    }
    return [
      FormSectionDefinition(
        id: 'details',
        title: 'Document Details',
        description: 'Fill in the required and optional details below',
        fields: [
          ..._buildFields(config?.required ?? type.requiredFields, required: true),
          ..._buildFields(config?.optional ?? type.optionalFields, required: false),
        ],
      ),
      const FormSectionDefinition(
        id: 'review',
        title: 'Review',
        description: 'Review and generate your document',
        fields: [],
      ),
    ];
  }

  List<FormFieldDefinition> _buildFields(List<String> keys, {required bool required}) {
    return keys.map((key) {
      final label = documentFieldLabels[key] ??
          key
              .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
              .replaceAll('_', ' ')
              .trim();
      FormFieldType fieldType = FormFieldType.text;
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
        fieldType = FormFieldType.textarea;
      } else if (lower.contains('amount') ||
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
        fieldType = FormFieldType.currency;
      } else if (lower.contains('date')) {
        fieldType = FormFieldType.date;
      } else if (lower.contains('number') ||
          lower.contains('duration') ||
          lower.contains('days') ||
          lower.contains('period') ||
          lower.contains('age') ||
          lower.contains('ratio') ||
          lower.contains('rating')) {
        fieldType = FormFieldType.number;
      }
      return FormFieldDefinition(
        id: key,
        label: label,
        hint: 'Enter $label',
        required: required,
        type: fieldType,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Legal Writing'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: CategoryStep(
            onTypeSelected: _selectType,
          ),
        ),
      ),
    );
  }
}
