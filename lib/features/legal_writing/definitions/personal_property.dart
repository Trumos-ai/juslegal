import '../models/document_definition.dart';
import '_definition_builder.dart';

DocumentDefinition get willTestamentDefinition => buildMinimalDocumentDefinition(
      id: 'will_testament',
      title: 'Will / Testament',
      description: 'Last Will and Testament for disposition of assets',
      promptHint: 'Testator details, beneficiaries, assets, distribution',
      category: DocumentCategoryType.personalProperty,
      requiredKeys: const [
        'testatorName',
        'testatorAddress',
        'testatorAge',
        'familyOrLegalHeirs',
        'executorName',
        'beneficiaries',
        'assetsList',
        'distributionScheme',
        'place',
        'date',
      ],
      optionalKeys: const [
        'alternateExecutor',
        'specificGifts',
        'liabilities',
        'witnessDetails',
      ],
    );

DocumentDefinition get powerOfAttorneyDefinition => buildMinimalDocumentDefinition(
      id: 'power_of_attorney',
      title: 'Power of Attorney',
      description: 'General or Special Power of Attorney',
      promptHint: 'Principal, agent, powers granted, scope, duration',
      category: DocumentCategoryType.personalProperty,
      requiredKeys: const [
        'principalName',
        'principalAddress',
        'agentOrAttorneyName',
        'agentOrAttorneyAddress',
        'purpose',
        'powersGranted',
        'scopeOfAuthority',
        'duration',
        'effectiveDate',
      ],
      optionalKeys: const [
        'propertyOrTransaction',
        'limitationsOrRestrictions',
        'revocationTerms',
        'consideration',
        'witnessDetails',
      ],
    );

DocumentDefinition get giftDeedDefinition => buildMinimalDocumentDefinition(
      id: 'gift_deed',
      title: 'Gift Deed',
      description: 'Deed for gifting property or asset',
      promptHint: 'Donor, donee, asset/property details, voluntary nature',
      category: DocumentCategoryType.personalProperty,
      requiredKeys: const [
        'donorName',
        'donorAddress',
        'doneeName',
        'doneeAddress',
        'relationship',
        'propertyDescription',
        'assetDetails',
        'location',
        'ownershipDetails',
      ],
      optionalKeys: const [
        'giftValue',
        'voluntaryDeclaration',
        'acceptanceStatement',
        'encumbranceInfo',
        'witnessDetails',
      ],
    );

DocumentDefinition get relinquishmentDeedDefinition => buildMinimalDocumentDefinition(
      id: 'relinquishment_deed',
      title: 'Relinquishment Deed',
      description: 'Relinquish share/rights in property',
      promptHint: 'Grantor, beneficiary, property, rights waived',
      category: DocumentCategoryType.personalProperty,
      requiredKeys: const [
        'grantorName',
        'grantorAddress',
        'beneficiaryName',
        'beneficiaryAddress',
        'propertyType',
        'propertyDescription',
        'originalOwner',
        'rightsRelinquished',
        'reason',
      ],
      optionalKeys: const [
        'voluntaryDeclaration',
        'noCoercionDeclaration',
        'consideration',
        'waiverOfClaims',
        'witnessDetails',
      ],
    );

DocumentDefinition get propertyTransferLetterDefinition => buildMinimalDocumentDefinition(
      id: 'property_transfer_letter',
      title: 'Property Transfer Letter',
      description: 'Formal letter for property transfer intent',
      promptHint: 'Buyer, seller, property details, consideration',
      category: DocumentCategoryType.personalProperty,
      requiredKeys: const [
        'sellerName',
        'sellerAddress',
        'buyerName',
        'buyerAddress',
        'propertyDescription',
        'propertyLocation',
        'considerationAmount',
        'transferDate',
        'paymentSchedule',
      ],
      optionalKeys: const [
        'advancePayment',
        'possessionDate',
        'documentsList',
      ],
    );
