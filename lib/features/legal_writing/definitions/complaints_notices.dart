import '../models/document_definition.dart';
import '_definition_builder.dart';

DocumentDefinition get consumerComplaintDefinition => buildMinimalDocumentDefinition(
      id: 'consumer_complaint',
      title: 'Consumer Complaint',
      description: 'Consumer forum complaint against goods/services',
      promptHint: 'Describe the product/service issue and what you want',
      category: DocumentCategoryType.complaintsNotices,
      requiredKeys: const [
        'complainantName',
        'complainantAddress',
        'complainantPhone',
        'oppositePartyName',
        'oppositePartyAddress',
        'complaintCategory',
        'purchaseDate',
        'amountPaid',
        'complaintDetails',
        'reliefSought',
      ],
      optionalKeys: const ['complainantEmail', 'previousComplaints'],
    );

DocumentDefinition get policeComplaintDefinition => buildMinimalDocumentDefinition(
      id: 'police_complaint',
      title: 'Police Complaint',
      description: 'FIR registration for criminal offense',
      promptHint: 'Describe the incident with date, place, and persons involved',
      category: DocumentCategoryType.complaintsNotices,
      requiredKeys: const [
        'complainantName',
        'complainantAddress',
        'complainantPhone',
        'accusedName',
        'accusedAddress',
        'incidentDate',
        'incidentPlace',
        'incidentDescription',
        'crimeType',
      ],
      optionalKeys: const [
        'complainantEmail',
        'evidenceList',
        'witnessDetails',
      ],
    );

DocumentDefinition get ceaseDesistDefinition => buildMinimalDocumentDefinition(
      id: 'cease_desist',
      title: 'Cease & Desist',
      description: 'Cease and desist notice for unlawful activity',
      promptHint: 'Describe the activity you want stopped and why',
      category: DocumentCategoryType.complaintsNotices,
      requiredKeys: const [
        'senderName',
        'senderAddress',
        'senderPhone',
        'recipientName',
        'recipientAddress',
        'unlawfulActivity',
        'legalBasis',
        'demandAction',
        'deadlineDays',
      ],
      optionalKeys: const ['previousWarnings', 'evidenceList'],
    );

DocumentDefinition get demandLetterDefinition => buildMinimalDocumentDefinition(
      id: 'demand_letter',
      title: 'Demand Letter',
      description: 'Formal demand for payment or performance',
      promptHint: 'Describe what you are demanding and the basis',
      category: DocumentCategoryType.complaintsNotices,
      requiredKeys: const [
        'senderName',
        'senderAddress',
        'senderPhone',
        'recipientName',
        'recipientAddress',
        'demandAmount',
        'demandReason',
        'legalBasis',
        'paymentDeadline',
      ],
      optionalKeys: const ['previousDemands', 'supportingDocuments'],
    );
