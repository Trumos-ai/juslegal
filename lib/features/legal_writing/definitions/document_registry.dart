import '../../../constants/document_fields.dart';
import '../models/document_definition.dart';
import 'rent_agreement.dart';
import 'legal_notice.dart';
import 'complaints_notices.dart';
import 'agreements_contracts.dart';
import 'affidavits_declarations.dart';
import 'court_legal_filings.dart';
import 'personal_property.dart';
import 'hr_employment.dart';
import '_definition_builder.dart';

final Map<String, DocumentDefinition> legalDocumentDefinitions = {
  'rent_agreement': rentAgreementDefinition,
  'legal_notice': legalNoticeDefinition,
  'consumer_complaint': consumerComplaintDefinition,
  'police_complaint': policeComplaintDefinition,
  'cease_desist': ceaseDesistDefinition,
  'demand_letter': demandLetterDefinition,
  'sale_agreement': saleAgreementDefinition,
  'partnership_deed': partnershipDeedDefinition,
  'mou_term_sheet': mouTermSheetDefinition,
  'service_agreement': serviceAgreementDefinition,
  'nda_confidentiality': ndaConfidentialityDefinition,
  'employment_contract': employmentContractDefinition,
  'freelance_contract': freelanceContractDefinition,
  'general_affidavit': generalAffidavitDefinition,
  'address_proof_affidavit': addressProofAffidavitDefinition,
  'name_change_affidavit': nameChangeAffidavitDefinition,
  'income_affidavit': incomeAffidavitDefinition,
  'declaration_statement': declarationStatementDefinition,
  'consumer_court_complaint': consumerCourtComplaintDefinition,
  'vakalatnama': vakalatnamaDefinition,
  'bail_application': bailApplicationDefinition,
  'appeal_letter': appealLetterDefinition,
  'rti_application': rtiApplicationDefinition,
  'will_testament': willTestamentDefinition,
  'power_of_attorney': powerOfAttorneyDefinition,
  'gift_deed': giftDeedDefinition,
  'relinquishment_deed': relinquishmentDeedDefinition,
  'property_transfer_letter': propertyTransferLetterDefinition,
  'resignation_letter': resignationLetterDefinition,
  'termination_letter': terminationLetterDefinition,
  'experience_letter': experienceLetterDefinition,
  'offer_letter': offerLetterDefinition,
};

DocumentDefinition? getDocumentDefinitionById(String id) {
  return legalDocumentDefinitions[id] ??
      _buildFallbackDefinition(id);
}

DocumentDefinition _buildFallbackDefinition(String id) {
  final config =
      documentTypeFields[id] ?? documentTypeFields[id.replaceAll('_', '')];
  return buildMinimalDocumentDefinition(
    id: id,
    title: config?.description ?? _humanize(id),
    description: 'Generate legal document',
    promptHint:
        'Enter the relevant details and we will prepare your document.',
    category: DocumentCategoryType.complaintsNotices,
    requiredKeys: config?.required ?? const [],
    optionalKeys: config?.optional ?? const [],
    promptId: id,
  );
}

String _humanize(String key) => key
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
    .join(' ');
