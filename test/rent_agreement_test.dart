import 'package:flutter_test/flutter_test.dart';
import 'package:juslegal/features/legal_writing/definitions/rent_agreement.dart';
import 'package:juslegal/features/legal_writing/engine/form_validator.dart';
import 'package:juslegal/features/legal_writing/models/document_form_data.dart';

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
}
