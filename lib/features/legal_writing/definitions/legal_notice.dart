import '../models/document_definition.dart';
import '_definition_builder.dart';

DocumentDefinition get legalNoticeDefinition => buildMinimalDocumentDefinition(
      id: 'legal_notice',
      title: 'Legal Notice',
      description: 'Formal legal notice for dispute resolution',
      promptHint: 'Describe the dispute, amount involved, and relief sought',
      category: DocumentCategoryType.complaintsNotices,
      requiredKeys: const [
        'senderName',
        'senderAddress',
        'senderPhone',
        'recipientName',
        'recipientAddress',
        'issueDescription',
        'legalViolation',
        'demands',
        'complianceDeadline',
      ],
      optionalKeys: const ['previousNotices', 'evidenceList'],
    );
