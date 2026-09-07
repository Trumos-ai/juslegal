import 'package:flutter_test/flutter_test.dart';
import 'package:juslegal/features/legal_writing/definitions/rent_agreement.dart';
import 'package:juslegal/features/legal_writing/engine/form_validator.dart';
import 'package:juslegal/features/legal_writing/models/document_form_data.dart';
import 'package:juslegal/features/legal_writing/prompts/prompt_builder.dart';
import 'package:juslegal/services/pdf/legal_pdf_models.dart';
import 'package:juslegal/services/pdf/legal_pdf_service.dart';

void main() {
  test('residential tenancy end date is calculated inclusively', () {
    expect(
        calculateResidentialTenancyEndDate('01 Jan 2026', 11), '30 Nov 2026');
    expect(calculateResidentialTenancyEndDate('31 Jan 2026', 1), '27 Feb 2026');
    expect(calculateResidentialTenancyEndDate('bad date', 11), isNull);
  });

  test('residential rent agreement validates repeatable parties', () {
    final values = <String, dynamic>{
      'agreementType': 'residential',
      'agreementDate': '01 Jan 2026',
      'executionCity': 'Pune',
      'executionState': 'Maharashtra',
      'propertyAddress': '1 Example Road',
      'tenancyStartDate': '01 Jan 2026',
      'tenancyPeriodMonths': '11',
      'monthlyRent': '25000',
      'rentDueDay': '5',
      'securityDeposit': '50000',
      'landlords': [
        <String, dynamic>{
          'partyType': 'individual',
          'fullName': 'A Landlord',
          'idType': 'pan',
          'idNumber': 'ABCDE1234F',
          'currentAddress': 'Pune'
        }
      ],
      'tenants': [
        <String, dynamic>{
          'partyType': 'individual',
          'fullName': 'A Tenant',
          'idType': 'pan',
          'idNumber': 'ABCDE1234F',
          'currentAddress': 'Pune'
        }
      ],
    };
    expect(
        const FormValidator().validateDocument(
            definition: rentAgreementDefinition,
            formData:
                DocumentFormData(documentId: 'rent_agreement', values: values)),
        isEmpty);
  });

  test('commercial rent agreement validates and uses the commercial prompt',
      () {
    final values = <String, dynamic>{
      'agreementType': 'commercial',
      'agreementDate': '01 Jan 2026',
      'executionCity': 'Pune',
      'executionState': 'Maharashtra',
      'propertyAddress': '1 Example Road',
      'commercialPropertyType': 'office',
      'permittedUse': 'Software services office',
      'tenancyStartDate': '01 Jan 2026',
      'tenancyPeriodMonths': '12',
      'tenancyEndDate': '31 Dec 2026',
      'monthlyRent': '50000',
      'rentDueDay': '5',
      'securityDeposit': '100000',
      'landlords': [_party('A Landlord')],
      'tenants': [_party('A Tenant')],
    };
    final formData =
        DocumentFormData(documentId: 'rent_agreement', values: values);
    expect(
        const FormValidator().validateDocument(
            definition: rentAgreementDefinition, formData: formData),
        isEmpty);

    final prompt = const PromptBuilder()
        .build(definition: rentAgreementDefinition, formData: formData);
    expect(prompt.userPrompt, contains('commercial rent agreement'));
    expect(prompt.userPrompt,
        contains('Permitted business use: Software services office'));
    expect(prompt.systemPrompt, contains('For commercial premises'));
    expect(prompt.systemPrompt, contains('Never invent user-specific facts'));
  });

  test('rent agreement PDF renders through the dedicated legal layout',
      () async {
    final bytes = await LegalPdfService.generateBytes(
      RentAgreementDocument(
        title: 'Rent Agreement',
        content: 'RENT AGREEMENT\n\n1. Term\nThe tenancy begins as supplied.',
        landlords: const ['A Landlord'],
        tenants: const ['A Tenant'],
      ),
      'en',
    );
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

Map<String, dynamic> _party(String name) => <String, dynamic>{
      'partyType': 'individual',
      'fullName': name,
      'idType': 'pan',
      'idNumber': 'ABCDE1234F',
      'currentAddress': 'Pune',
    };
