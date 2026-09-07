import '../models/document_definition.dart';
import '_definition_builder.dart';

DocumentDefinition get serviceAgreementDefinition => buildMinimalDocumentDefinition(
      id: 'service_agreement',
      title: 'Service Agreement',
      description: 'Service provider agreement',
      promptHint: 'Services to be provided, payment, timelines',
      category: DocumentCategoryType.agreementsContracts,
      requiredKeys: const [
        'providerName',
        'providerAddress',
        'providerPhone',
        'clientName',
        'clientAddress',
        'clientPhone',
        'serviceDescription',
        'serviceDuration',
        'fee',
        'paymentSchedule',
        'terminationNotice',
      ],
      optionalKeys: const ['deliverables', 'milestones'],
    );

DocumentDefinition get ndaConfidentialityDefinition => buildMinimalDocumentDefinition(
      id: 'nda_confidentiality',
      title: 'NDA / Confidentiality',
      description: 'Non-disclosure agreement for confidential information',
      promptHint: 'What information is confidential and duration of NDA',
      category: DocumentCategoryType.agreementsContracts,
      requiredKeys: const [
        'disclosingParty',
        'disclosingPartyAddress',
        'receivingParty',
        'receivingPartyAddress',
        'confidentialInformation',
        'purposeOfDisclosure',
        'termOfAgreement',
        'jurisdiction',
      ],
      optionalKeys: const ['exceptions', 'returnOfMaterials'],
    );

DocumentDefinition get employmentContractDefinition => buildMinimalDocumentDefinition(
      id: 'employment_contract',
      title: 'Employment Contract',
      description: 'Agreement between employer and employee',
      promptHint: 'Role, salary, benefits, notice period, terms',
      category: DocumentCategoryType.agreementsContracts,
      requiredKeys: const [
        'employerName',
        'employerAddress',
        'employeeName',
        'employeeAddress',
        'position',
        'startDate',
        'salary',
        'workHours',
        'jobDescription',
        'terminationNotice',
      ],
      optionalKeys: const ['benefits', 'probationPeriod', 'nonCompeteClause'],
    );

DocumentDefinition get freelanceContractDefinition => buildMinimalDocumentDefinition(
      id: 'freelance_contract',
      title: 'Freelance Contract',
      description: 'Contract for freelance or consulting work',
      promptHint: 'Project scope, deliverables, payment, IP ownership',
      category: DocumentCategoryType.agreementsContracts,
      requiredKeys: const [
        'clientName',
        'clientAddress',
        'freelancerName',
        'freelancerAddress',
        'projectDescription',
        'deliverables',
        'timeline',
        'paymentTerms',
        'totalFee',
      ],
      optionalKeys: const ['milestones', 'revisionPolicy', 'intellectualProperty'],
    );

DocumentDefinition get saleAgreementDefinition => buildMinimalDocumentDefinition(
      id: 'sale_agreement',
      title: 'Sale Agreement',
      description: 'Agreement for sale of goods or property',
      promptHint: 'What is being sold, price, payment terms, delivery',
      category: DocumentCategoryType.agreementsContracts,
      requiredKeys: const [
        'sellerName',
        'sellerAddress',
        'buyerName',
        'buyerAddress',
        'itemDescription',
        'salePrice',
        'paymentMethod',
        'deliveryDate',
        'conditionOfItem',
      ],
      optionalKeys: const [
        'propertyOrGoodsLocation',
        'advanceAmount',
        'balanceAmount',
        'possessionOrDeliveryTerms',
        'titleOrOwnershipRepresentations',
        'documentsToBeProvided',
        'taxesAndCharges',
        'terminationTerms',
        'disputeResolution',
        'otherTerms',
      ],
    );

DocumentDefinition get partnershipDeedDefinition => buildMinimalDocumentDefinition(
      id: 'partnership_deed',
      title: 'Partnership Deed',
      description: 'Deed for business partnership',
      promptHint: 'Partners, capital contribution, profit sharing, roles',
      category: DocumentCategoryType.agreementsContracts,
      requiredKeys: const [
        'firmName',
        'businessAddress',
        'partner1Name',
        'partner1Address',
        'partner2Name',
        'partner2Address',
        'businessNature',
        'capitalContribution',
        'profitSharingRatio',
        'commencementDate',
      ],
      optionalKeys: const [
        'partnerContactDetails',
        'dutiesAndResponsibilities',
        'drawings',
        'bankingArrangements',
        'accountingArrangements',
        'admissionRetirement',
      ],
    );

DocumentDefinition get mouTermSheetDefinition => buildMinimalDocumentDefinition(
      id: 'mou_term_sheet',
      title: 'MOU / Term Sheet',
      description: 'Memorandum of understanding between parties',
      promptHint: 'Purpose, key terms, obligations of each party',
      category: DocumentCategoryType.agreementsContracts,
      requiredKeys: const [
        'party1Name',
        'party1Address',
        'party2Name',
        'party2Address',
        'purposeOfCollaboration',
        'termDuration',
        'responsibilities',
        'confidentiality',
        'governingLaw',
      ],
      optionalKeys: const [
        'commercialTerms',
        'paymentOrInvestment',
        'bindingNature',
        'signatoryDetails',
      ],
    );
