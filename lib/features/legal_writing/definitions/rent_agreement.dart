import '../models/document_definition.dart';
import '../models/form_field_definition.dart';
import '../models/form_section_definition.dart';

DocumentDefinition get rentAgreementDefinition => DocumentDefinition(
      id: 'rent_agreement',
      title: 'Rent Agreement',
      description: 'Residential or commercial rental agreement',
      promptHint: 'Property details, rent amount, duration, terms',
      category: DocumentCategoryType.agreementsContracts,
      promptId: 'rent_agreement',
      multiStep: true,
      sections: [
        FormSectionDefinition(
          id: 'agreement',
          title: 'Agreement Details',
          description: 'Basic agreement type and general information',
          fields: [
            FormFieldDefinition(
              id: 'agreement_type',
              label: 'Agreement Type',
              hint: 'Select Residential or Commercial',
              required: true,
              type: FormFieldType.radio,
              options: const [
                FieldOption(value: 'residential', label: 'Residential'),
                FieldOption(value: 'commercial', label: 'Commercial'),
              ],
              defaultValue: 'residential',
            ),
            FormFieldDefinition(
              id: 'startDate',
              label: 'Start Date',
              hint: 'Agreement start date',
              required: true,
              type: FormFieldType.date,
            ),
            FormFieldDefinition(
              id: 'leaseDuration',
              label: 'Lease Duration',
              hint: 'e.g. 11 months',
              required: true,
              type: FormFieldType.text,
            ),
          ],
        ),
        FormSectionDefinition(
          id: 'property',
          title: 'Property Details',
          description: 'Information about the rented property',
          fields: [
            FormFieldDefinition(
              id: 'propertyAddress',
              label: 'Property Address',
              hint: 'Complete property address',
              required: true,
              type: FormFieldType.textarea,
            ),
            FormFieldDefinition(
              id: 'propertyType',
              label: 'Property Type',
              hint: 'e.g. Apartment, House, Shop, Office',
              required: true,
              type: FormFieldType.text,
            ),
          ],
        ),
        ConditionalSectionDefinition(
          id: 'commercial_terms',
          title: 'Commercial Terms',
          description: 'Additional terms for commercial properties',
          visibilityCondition: (values) =>
              values['agreement_type'] == 'commercial',
          fields: [
            FormFieldDefinition(
              id: 'business_nature',
              label: 'Nature of Business',
              hint: 'Type of business to be conducted',
              required: false,
              type: FormFieldType.text,
            ),
            FormFieldDefinition(
              id: 'gst_applicable',
              label: 'GST Applicable',
              hint: 'Is GST applicable on rent?',
              required: false,
              type: FormFieldType.toggle,
              defaultValue: false,
            ),
            FormFieldDefinition(
              id: 'common_area_maintenance',
              label: 'CAM Charges',
              hint: 'Common area maintenance charges',
              required: false,
              type: FormFieldType.currency,
            ),
          ],
        ),
        FormSectionDefinition(
          id: 'terms_rent',
          title: 'Terms & Rent',
          description: 'Financial and operational terms',
          fields: [
            FormFieldDefinition(
              id: 'monthlyRent',
              label: 'Monthly Rent',
              hint: 'Monthly rent amount',
              required: true,
              type: FormFieldType.currency,
            ),
            FormFieldDefinition(
              id: 'securityDeposit',
              label: 'Security Deposit',
              hint: 'Security deposit amount',
              required: true,
              type: FormFieldType.currency,
            ),
            FormFieldDefinition(
              id: 'maintenanceResponsibility',
              label: 'Maintenance Responsibility',
              hint: 'Who is responsible for maintenance?',
              required: false,
              type: FormFieldType.text,
            ),
            FormFieldDefinition(
              id: 'specialClauses',
              label: 'Special Clauses',
              hint: 'Any other special terms or conditions',
              required: false,
              type: FormFieldType.textarea,
            ),
          ],
        ),
        RepeatableSectionDefinition(
          id: 'landlords',
          title: 'Landlords',
          description: 'Landlord / Owner party details',
          itemTitlePrefix: 'Landlord',
          addButtonLabel: 'Add Landlord',
          removeButtonLabel: 'Remove Landlord',
          minItems: 1,
          maxItems: 10,
          fields: [
            FormFieldDefinition(
              id: 'landlordName',
              label: 'Landlord Name',
              hint: 'Full name of landlord',
              required: true,
              type: FormFieldType.text,
            ),
            FormFieldDefinition(
              id: 'landlordAddress',
              label: 'Landlord Address',
              hint: 'Landlord address',
              required: true,
              type: FormFieldType.textarea,
            ),
            FormFieldDefinition(
              id: 'landlordPhone',
              label: 'Landlord Phone',
              hint: 'Contact phone number',
              required: true,
              type: FormFieldType.text,
              validationRules: const [
                ValidationRule(
                  type: ValidationRule.phone,
                  message: 'Enter valid 10-digit phone number',
                ),
              ],
            ),
          ],
        ),
        RepeatableSectionDefinition(
          id: 'tenants',
          title: 'Tenants',
          description: 'Tenant / Lessee party details',
          itemTitlePrefix: 'Tenant',
          addButtonLabel: 'Add Tenant',
          removeButtonLabel: 'Remove Tenant',
          minItems: 1,
          maxItems: 10,
          fields: [
            FormFieldDefinition(
              id: 'tenantName',
              label: 'Tenant Name',
              hint: 'Full name of tenant',
              required: true,
              type: FormFieldType.text,
            ),
            FormFieldDefinition(
              id: 'tenantAddress',
              label: 'Tenant Address',
              hint: 'Tenant address',
              required: true,
              type: FormFieldType.textarea,
            ),
            FormFieldDefinition(
              id: 'tenantPhone',
              label: 'Tenant Phone',
              hint: 'Contact phone number',
              required: true,
              type: FormFieldType.text,
              validationRules: const [
                ValidationRule(
                  type: ValidationRule.phone,
                  message: 'Enter valid 10-digit phone number',
                ),
              ],
            ),
          ],
        ),
        FormSectionDefinition(
          id: 'review',
          title: 'Review',
          description: 'Review and generate your document',
          fields: const [],
        ),
      ],
    );
