class DocumentTypeConfig {
  final String category;
  final List<String> required;
  final List<String> optional;
  final String description;

  const DocumentTypeConfig({
    required this.category,
    required this.required,
    required this.optional,
    required this.description,
  });
}

const Map<String, DocumentTypeConfig> documentTypeFields = {
  // COMPLAINTS & NOTICES
  'legal_notice': DocumentTypeConfig(
    category: 'Complaints & Notices',
    required: [
      'senderName',
      'senderAddress',
      'senderPhone',
      'recipientName',
      'recipientAddress',
      'issueDescription',
      'legalViolation',
      'demands',
      'complianceDeadline'
    ],
    optional: ['previousNotices', 'evidenceList'],
    description: 'Formal legal notice for dispute resolution',
  ),
  'consumer_complaint': DocumentTypeConfig(
    category: 'Complaints & Notices',
    required: [
      'complainantName',
      'complainantAddress',
      'complainantPhone',
      'oppositePartyName',
      'oppositePartyAddress',
      'complaintCategory',
      'purchaseDate',
      'amountPaid',
      'complaintDetails',
      'reliefSought'
    ],
    optional: ['complainantEmail', 'previousComplaints'],
    description: 'Consumer forum complaint against goods/services',
  ),
  'police_complaint': DocumentTypeConfig(
    category: 'Complaints & Notices',
    required: [
      'complainantName',
      'complainantAddress',
      'complainantPhone',
      'accusedName',
      'accusedAddress',
      'incidentDate',
      'incidentPlace',
      'incidentDescription',
      'crimeType'
    ],
    optional: ['complainantEmail', 'evidenceList', 'witnessDetails'],
    description: 'FIR registration for criminal offense',
  ),
  'cease_desist': DocumentTypeConfig(
    category: 'Complaints & Notices',
    required: [
      'senderName',
      'senderAddress',
      'senderPhone',
      'recipientName',
      'recipientAddress',
      'unlawfulActivity',
      'legalBasis',
      'demandAction',
      'deadlineDays'
    ],
    optional: ['previousWarnings', 'evidenceList'],
    description: 'Cease and desist notice for unlawful activity',
  ),
  'demand_letter': DocumentTypeConfig(
    category: 'Complaints & Notices',
    required: [
      'senderName',
      'senderAddress',
      'senderPhone',
      'recipientName',
      'recipientAddress',
      'demandAmount',
      'demandReason',
      'legalBasis',
      'paymentDeadline'
    ],
    optional: ['previousDemands', 'supportingDocuments'],
    description: 'Formal demand for payment or performance',
  ),

  // AGREEMENTS & CONTRACTS
  'rent_agreement': DocumentTypeConfig(
    category: 'Agreements & Contracts',
    required: [
      'landlordName',
      'landlordAddress',
      'landlordPhone',
      'tenantName',
      'tenantAddress',
      'tenantPhone',
      'propertyAddress',
      'propertyType',
      'monthlyRent',
      'leaseDuration',
      'startDate',
      'securityDeposit'
    ],
    optional: ['maintenanceResponsibility', 'specialClauses'],
    description: 'Residential or commercial rental agreement',
  ),
  'service_agreement': DocumentTypeConfig(
    category: 'Agreements & Contracts',
    required: [
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
      'terminationNotice'
    ],
    optional: ['deliverables', 'milestones'],
    description: 'Service provider agreement',
  ),
  'nda_confidentiality': DocumentTypeConfig(
    category: 'Agreements & Contracts',
    required: [
      'disclosingParty',
      'disclosingPartyAddress',
      'receivingParty',
      'receivingPartyAddress',
      'confidentialInformation',
      'purposeOfDisclosure',
      'termOfAgreement',
      'jurisdiction'
    ],
    optional: ['exceptions', 'returnOfMaterials'],
    description: 'Non-disclosure agreement for confidential information',
  ),
  'employment_contract': DocumentTypeConfig(
    category: 'Agreements & Contracts',
    required: [
      'employerName',
      'employerAddress',
      'employeeName',
      'employeeAddress',
      'position',
      'startDate',
      'salary',
      'workHours',
      'jobDescription',
      'terminationNotice'
    ],
    optional: ['benefits', 'probationPeriod', 'nonCompeteClause'],
    description: 'Employment contract between employer and employee',
  ),
  'freelance_contract': DocumentTypeConfig(
    category: 'Agreements & Contracts',
    required: [
      'clientName',
      'clientAddress',
      'freelancerName',
      'freelancerAddress',
      'projectDescription',
      'deliverables',
      'timeline',
      'paymentTerms',
      'totalFee'
    ],
    optional: ['milestones', 'revisionPolicy', 'intellectualProperty'],
    description: 'Freelance project contract',
  ),
  'sale_agreement': DocumentTypeConfig(
    category: 'Agreements & Contracts',
    required: [
      'sellerName',
      'sellerAddress',
      'buyerName',
      'buyerAddress',
      'itemDescription',
      'salePrice',
      'paymentMethod',
      'deliveryDate',
      'conditionOfItem'
    ],
    optional: ['warranty', 'inspectionPeriod', 'defaultClause'],
    description: 'Sale/purchase agreement for goods or property',
  ),
  'partnership_deed': DocumentTypeConfig(
    category: 'Agreements & Contracts',
    required: [
      'firmName',
      'businessAddress',
      'partner1Name',
      'partner1Address',
      'partner2Name',
      'partner2Address',
      'businessNature',
      'capitalContribution',
      'profitSharingRatio',
      'commencementDate'
    ],
    optional: ['additionalPartners', 'decisionMaking', 'dissolutionClause'],
    description: 'Partnership deed for business formation',
  ),
  'mou_term_sheet': DocumentTypeConfig(
    category: 'Agreements & Contracts',
    required: [
      'party1Name',
      'party1Address',
      'party2Name',
      'party2Address',
      'purposeOfCollaboration',
      'termDuration',
      'responsibilities',
      'confidentiality',
      'governingLaw'
    ],
    optional: ['financialTerms', 'intellectualProperty', 'termination'],
    description: 'Memorandum of understanding or term sheet',
  ),

  // AFFIDAVITS & DECLARATIONS
  'general_affidavit': DocumentTypeConfig(
    category: 'Affidavits & Declarations',
    required: [
      'deponentName',
      'deponentAddress',
      'deponentAge',
      'affirmationContent',
      'purpose',
      'place',
      'date'
    ],
    optional: ['supportingDocuments', 'notaryDetails'],
    description: 'General purpose affidavit',
  ),
  'address_proof_affidavit': DocumentTypeConfig(
    category: 'Affidavits & Declarations',
    required: [
      'deponentName',
      'deponentAddress',
      'deponentAge',
      'currentAddress',
      'durationAtAddress',
      'purpose',
      'place',
      'date'
    ],
    optional: ['previousAddress', 'landlordDetails'],
    description: 'Affidavit for address proof',
  ),
  'name_change_affidavit': DocumentTypeConfig(
    category: 'Affidavits & Declarations',
    required: [
      'deponentName',
      'deponentAddress',
      'deponentAge',
      'oldName',
      'newName',
      'reasonForChange',
      'place',
      'date'
    ],
    optional: ['fatherName', 'motherName', 'supportingDocuments'],
    description: 'Affidavit for name change',
  ),
  'income_affidavit': DocumentTypeConfig(
    category: 'Affidavits & Declarations',
    required: [
      'deponentName',
      'deponentAddress',
      'deponentAge',
      'annualIncome',
      'incomeSource',
      'purpose',
      'place',
      'date'
    ],
    optional: ['employmentDetails', 'otherIncomeSources'],
    description: 'Affidavit declaring income for official purposes',
  ),

  // COURT & LEGAL FILINGS
  'consumer_court_complaint': DocumentTypeConfig(
    category: 'Court & Legal Filings',
    required: [
      'complainantName',
      'complainantAddress',
      'complainantPhone',
      'oppositePartyName',
      'oppositePartyAddress',
      'district',
      'state',
      'complaintCategory',
      'purchaseDate',
      'amountPaid',
      'complaintDetails',
      'reliefSought'
    ],
    optional: ['complainantEmail', 'previousComplaints', 'evidenceList'],
    description: 'Consumer court complaint filing',
  ),
  'vakalatnama': DocumentTypeConfig(
    category: 'Court & Legal Filings',
    required: [
      'clientName',
      'clientAddress',
      'advocateName',
      'advocateAddress',
      'caseNumber',
      'courtName',
      'caseType',
      'place',
      'date'
    ],
    optional: ['advocatePhone', 'advocateEnrollmentNumber'],
    description: 'Vakalatnama - power to advocate to represent in court',
  ),
  'bail_application': DocumentTypeConfig(
    category: 'Court & Legal Filings',
    required: [
      'applicantName',
      'applicantAddress',
      'accusedName',
      'accusedAddress',
      'firNumber',
      'policeStation',
      'offense',
      'courtName',
      'bailType',
      'groundsForBail'
    ],
    optional: ['suretyDetails', 'previousBailApplications'],
    description: 'Bail application for accused person',
  ),
  'appeal_letter': DocumentTypeConfig(
    category: 'Court & Legal Filings',
    required: [
      'appellantName',
      'appellantAddress',
      'respondentName',
      'respondentAddress',
      'judgmentDate',
      'courtName',
      'caseNumber',
      'groundsOfAppeal',
      'reliefSought'
    ],
    optional: ['appellantPhone', 'legalProvisions'],
    description: 'Appeal letter against court judgment',
  ),

  // PERSONAL & PROPERTY
  'will_testament': DocumentTypeConfig(
    category: 'Personal & Property',
    required: [
      'testatorName',
      'testatorAddress',
      'testatorAge',
      'beneficiaries',
      'assetsDistribution',
      'executorName',
      'executorAddress',
      'place',
      'date'
    ],
    optional: ['guardianForMinors', 'funeralWishes', 'witnessDetails'],
    description: 'Last will and testament',
  ),
  'power_of_attorney': DocumentTypeConfig(
    category: 'Personal & Property',
    required: [
      'principalName',
      'principalAddress',
      'agentName',
      'agentAddress',
      'powersGranted',
      'duration',
      'revocationClause',
      'place',
      'date'
    ],
    optional: ['specificPowers', 'registrationDetails'],
    description: 'Power of attorney document',
  ),
  'gift_deed': DocumentTypeConfig(
    category: 'Personal & Property',
    required: [
      'donorName',
      'donorAddress',
      'doneeName',
      'doneeAddress',
      'propertyDescription',
      'giftReason',
      'consideration',
      'place',
      'date'
    ],
    optional: ['propertyValue', 'witnessDetails'],
    description: 'Gift deed for property transfer',
  ),
  'relinquishment_deed': DocumentTypeConfig(
    category: 'Personal & Property',
    required: [
      'relinquisherName',
      'relinquisherAddress',
      'beneficiaryName',
      'beneficiaryAddress',
      'propertyDescription',
      'shareRelinquished',
      'reason',
      'place',
      'date'
    ],
    optional: ['propertyValue', 'otherCoOwners'],
    description: 'Relinquishment deed for property share',
  ),

  // HR & EMPLOYMENT
  'resignation_letter': DocumentTypeConfig(
    category: 'HR & Employment',
    required: [
      'employeeName',
      'employeeAddress',
      'employerName',
      'employerAddress',
      'position',
      'lastWorkingDay',
      'reasonForResignation',
      'noticePeriod'
    ],
    optional: ['handoverDetails', 'contactInformation'],
    description: 'Formal resignation letter',
  ),
  'termination_letter': DocumentTypeConfig(
    category: 'HR & Employment',
    required: [
      'employerName',
      'employerAddress',
      'employeeName',
      'employeeAddress',
      'position',
      'terminationDate',
      'reasonForTermination',
      'noticePeriod',
      'finalSettlement'
    ],
    optional: ['severancePackage', 'returnOfProperty'],
    description: 'Employment termination letter',
  ),
  'experience_letter': DocumentTypeConfig(
    category: 'HR & Employment',
    required: [
      'employerName',
      'employerAddress',
      'employeeName',
      'employeeDesignation',
      'employmentStartDate',
      'employmentEndDate',
      'performanceSummary'
    ],
    optional: ['employeePhone', 'skills', 'projects'],
    description: 'Experience/employment certificate',
  ),
  'offer_letter': DocumentTypeConfig(
    category: 'HR & Employment',
    required: [
      'employerName',
      'employerAddress',
      'candidateName',
      'candidateAddress',
      'position',
      'startDate',
      'salary',
      'workLocation',
      'reportingTo'
    ],
    optional: ['benefits', 'probationDetails', 'bonusStructure'],
    description: 'Job offer letter',
  ),
};
