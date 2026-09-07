import '../models/document_definition.dart';
import '_definition_builder.dart';

DocumentDefinition get generalAffidavitDefinition => buildMinimalDocumentDefinition(
      id: 'general_affidavit',
      title: 'General Affidavit',
      description: 'Sworn affidavit for any general purpose',
      promptHint: 'Factual statements to be sworn',
      category: DocumentCategoryType.affidavitsDeclarations,
      requiredKeys: const [
        'deponentName',
        'deponentAddress',
        'deponentAge',
        'deponentOccupation',
        'affidavitPurpose',
        'swornStatements',
        'swornDate',
        'place',
      ],
      optionalKeys: const [
        'personalDetails',
        'supportingInformation',
        'witnessDetails',
      ],
    );

DocumentDefinition get addressProofAffidavitDefinition => buildMinimalDocumentDefinition(
      id: 'address_proof_affidavit',
      title: 'Address Proof Affidavit',
      description: 'Affidavit for address verification',
      promptHint: 'Current address, history, and verification',
      category: DocumentCategoryType.affidavitsDeclarations,
      requiredKeys: const [
        'deponentName',
        'deponentDOB',
        'deponentAddress',
        'residenceDuration',
        'addressPurpose',
        'previousAddress',
        'declarationStatement',
        'place',
        'date',
      ],
      optionalKeys: const [
        'proofSupportingInformation',
        'witnessDetails',
        'notaryDetails',
      ],
    );

DocumentDefinition get nameChangeAffidavitDefinition => buildMinimalDocumentDefinition(
      id: 'name_change_affidavit',
      title: 'Name Change Affidavit',
      description: 'Affidavit for legal name change',
      promptHint: 'Old name, new name, and reason for change',
      category: DocumentCategoryType.affidavitsDeclarations,
      requiredKeys: const [
        'deponentName',
        'newName',
        'deponentDOB',
        'deponentFatherName',
        'deponentAddress',
        'reasonForChange',
        'declarationStatement',
        'place',
        'date',
      ],
      optionalKeys: const [
        'maritalStatus',
        'witnessDetails',
        'notaryDetails',
      ],
    );

DocumentDefinition get incomeAffidavitDefinition => buildMinimalDocumentDefinition(
      id: 'income_affidavit',
      title: 'Income Affidavit',
      description: 'Affidavit for income declaration',
      promptHint: 'Employment, income sources, amounts',
      category: DocumentCategoryType.affidavitsDeclarations,
      requiredKeys: const [
        'deponentName',
        'deponentAddress',
        'deponentOccupation',
        'employerOrBusiness',
        'incomeSource',
        'monthlyOrAnnualIncome',
        'financialDetails',
        'purpose',
        'place',
        'date',
      ],
      optionalKeys: const [
        'dependents',
        'otherIncome',
        'assetDetails',
        'liabilityDetails',
      ],
    );

DocumentDefinition get declarationStatementDefinition => buildMinimalDocumentDefinition(
      id: 'declaration_statement',
      title: 'Declaration Statement',
      description: 'Sworn declaration for any statutory purpose',
      promptHint: 'Statements you wish to declare on oath',
      category: DocumentCategoryType.affidavitsDeclarations,
      requiredKeys: const [
        'decedentName',
        'decedentAddress',
        'declarationSubject',
        'declarationStatements',
        'place',
        'date',
      ],
      optionalKeys: const ['witnessDetails', 'notaryDetails'],
    );
