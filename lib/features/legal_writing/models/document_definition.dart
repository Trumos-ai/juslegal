import 'package:flutter/material.dart';
import 'form_section_definition.dart';

enum DocumentCategoryType {
  complaintsNotices,
  agreementsContracts,
  affidavitsDeclarations,
  courtLegalFilings,
  personalProperty,
  hrEmployment,
}

extension DocumentCategoryTypeExtension on DocumentCategoryType {
  String get label {
    switch (this) {
      case DocumentCategoryType.complaintsNotices:
        return 'Complaints & Notices';
      case DocumentCategoryType.agreementsContracts:
        return 'Agreements & Contracts';
      case DocumentCategoryType.affidavitsDeclarations:
        return 'Affidavits & Declarations';
      case DocumentCategoryType.courtLegalFilings:
        return 'Court & Legal Filings';
      case DocumentCategoryType.personalProperty:
        return 'Personal & Property';
      case DocumentCategoryType.hrEmployment:
        return 'HR & Employment';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentCategoryType.complaintsNotices:
        return Icons.campaign_outlined;
      case DocumentCategoryType.agreementsContracts:
        return Icons.handshake_outlined;
      case DocumentCategoryType.affidavitsDeclarations:
        return Icons.verified_outlined;
      case DocumentCategoryType.courtLegalFilings:
        return Icons.account_balance_outlined;
      case DocumentCategoryType.personalProperty:
        return Icons.home_outlined;
      case DocumentCategoryType.hrEmployment:
        return Icons.work_outline;
    }
  }
}

class DocumentDefinition {
  final String id;
  final String title;
  final String description;
  final String promptHint;
  final DocumentCategoryType category;
  final List<FormSectionDefinition> sections;
  final String promptId;
  final List<String> supportedLanguages;
  final bool multiStep;

  const DocumentDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.promptHint,
    required this.category,
    required this.sections,
    required this.promptId,
    this.supportedLanguages = const ['en', 'hi'],
    this.multiStep = true,
  });

  DocumentDefinition copyWith({
    String? id,
    String? title,
    String? description,
    String? promptHint,
    DocumentCategoryType? category,
    List<FormSectionDefinition>? sections,
    String? promptId,
    List<String>? supportedLanguages,
    bool? multiStep,
  }) {
    return DocumentDefinition(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      promptHint: promptHint ?? this.promptHint,
      category: category ?? this.category,
      sections: sections ?? this.sections,
      promptId: promptId ?? this.promptId,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      multiStep: multiStep ?? this.multiStep,
    );
  }
}
