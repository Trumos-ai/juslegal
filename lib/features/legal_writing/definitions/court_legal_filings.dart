import '../models/document_definition.dart';
import '_definition_builder.dart';

DocumentDefinition get consumerCourtComplaintDefinition => buildMinimalDocumentDefinition(
      id: 'consumer_court_complaint',
      title: 'Consumer Court Complaint',
      description: 'Structured complaint for District/State/National Consumer Commission',
      promptHint: 'Parties, facts, jurisdiction, documents, and reliefs',
      category: DocumentCategoryType.courtLegalFilings,
      requiredKeys: const [
        'complainantName',
        'complainantAddress',
        'oppositePartyName',
        'oppositePartyAddress',
        'causeOfAction',
        'allegations',
        'documentsList',
        'reliefSought',
        'place',
        'date',
      ],
      optionalKeys: const [
        'pecuniaryJurisdiction',
        'territorialJurisdiction',
        'compensationOrDamages',
        'mentalHarassment',
        'advocateDetails',
      ],
    );

DocumentDefinition get vakalatnamaDefinition => buildMinimalDocumentDefinition(
      id: 'vakalatnama',
      title: 'Vakalatnama',
      description: 'Authority letter to engage advocate for a case',
      promptHint: 'Court, case, parties, and authority scope',
      category: DocumentCategoryType.courtLegalFilings,
      requiredKeys: const [
        'clientName',
        'clientAddress',
        'advocateName',
        'advocateDetails',
        'courtOrTribunal',
        'caseParties',
        'authorizationScope',
        'feesOrCharges',
        'place',
        'date',
      ],
      optionalKeys: const [
        'caseNumber',
        'advocateFeesAndExpenses',
        'signatures',
      ],
    );

DocumentDefinition get bailApplicationDefinition => buildMinimalDocumentDefinition(
      id: 'bail_application',
      title: 'Bail Application',
      description: 'Regular / Anticipatory / Interim bail application',
      promptHint: 'Accused/applicant, FIR/case details, alleged sections, grounds',
      category: DocumentCategoryType.courtLegalFilings,
      requiredKeys: const [
        'applicantOrAccused',
        'respondentOrState',
        'courtName',
        'firOrCaseDetails',
        'policeStation',
        'allegedOffencesOrSections',
        'custodyOrArrestDetails',
        'factualBackground',
        'groundsForBail',
        'personalCircumstances',
      ],
      optionalKeys: const [
        'prioraCases',
        'proposedSureties',
        'otherConditions',
        'advocateDetails',
      ],
    );

DocumentDefinition get appealLetterDefinition => buildMinimalDocumentDefinition(
      id: 'appeal_letter',
      title: 'Appeal Letter / Petition',
      description: 'Appeal against an order, decision, or judgment',
      promptHint: 'Impugned order, grounds, and relief sought',
      category: DocumentCategoryType.courtLegalFilings,
      requiredKeys: const [
        'appellantName',
        'appellantAddress',
        'respondentName',
        'respondentAddress',
        'courtOrAuthority',
        'impugnedOrder',
        'relevantFacts',
        'groundsOfAppeal',
        'reliefOrPrayer',
        'place',
        'date',
      ],
      optionalKeys: const [
        'caseOrOrderNumber',
        'delayOrLimitation',
        'supportingDocuments',
        'advocateOrSignatory',
      ],
    );

DocumentDefinition get rtiApplicationDefinition => buildMinimalDocumentDefinition(
      id: 'rti_application',
      title: 'RTI Application',
      description: 'RTI application seeking information under RTI Act',
      promptHint: 'PIO, authority, questions/documents, period, fee',
      category: DocumentCategoryType.courtLegalFilings,
      requiredKeys: const [
        'applicantName',
        'applicantAddress',
        'department',
        'informationSought',
        'timePeriod',
        'feeMethod',
        'preferredFormat',
        'applicantPhone',
      ],
      optionalKeys: const [
        'applicantEmail',
        'supportingDocuments',
        'previousApplications',
        'publicAuthority',
        'PIOAddress',
      ],
    );
