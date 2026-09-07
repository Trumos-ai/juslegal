import '../models/document_definition.dart';
import '_definition_builder.dart';

DocumentDefinition get resignationLetterDefinition => buildMinimalDocumentDefinition(
      id: 'resignation_letter',
      title: 'Resignation Letter',
      description: 'Professional resignation letter from employment',
      promptHint: 'Position, last working day, reason (if any), handover',
      category: DocumentCategoryType.hrEmployment,
      requiredKeys: const [
        'employeeName',
        'employeeAddress',
        'companyName',
        'HRContact',
        'position',
        'department',
        'joiningDate',
        'lastWorkingDay',
      ],
      optionalKeys: const [
        'employeeEmail',
        'noticePeriod',
        'reasonForResignation',
        'transitionHelp',
        'knowledgeTransferPlan',
        'finalTasks',
        'gratitudeStatement',
        'learnings',
      ],
    );

DocumentDefinition get terminationLetterDefinition => buildMinimalDocumentDefinition(
      id: 'termination_letter',
      title: 'Termination Letter',
      description: 'Formal employment termination letter',
      promptHint: 'Employee, designation, last working day, reason (optional)',
      category: DocumentCategoryType.hrEmployment,
      requiredKeys: const [
        'companyName',
        'companyAddress',
        'employeeName',
        'employeeAddress',
        'designation',
        'department',
        'terminationDate',
        'lastWorkingDay',
      ],
      optionalKeys: const [
        'reasonForTermination',
        'finalSettlement',
        'settlementDetails',
        'itemsToReturn',
        'returnDate',
        'referenceLetterStatus',
        'serviceCertificateStatus',
      ],
    );

DocumentDefinition get experienceLetterDefinition => buildMinimalDocumentDefinition(
      id: 'experience_letter',
      title: 'Experience Letter',
      description: 'Employment experience / relieving letter',
      promptHint: 'Employee name, role, tenure, responsibilities, conduct',
      category: DocumentCategoryType.hrEmployment,
      requiredKeys: const [
        'companyName',
        'companyAddress',
        'employeeName',
        'employeeAddress',
        'designation',
        'employmentPeriod',
      ],
      optionalKeys: const [
        'jobTitle',
        'responsibilities',
        'skills',
        'performance',
        'conduct',
        'achievements',
        'recommendation',
        'referenceContact',
      ],
    );

DocumentDefinition get offerLetterDefinition => buildMinimalDocumentDefinition(
      id: 'offer_letter',
      title: 'Offer Letter / Appointment',
      description: 'Job offer / appointment letter',
      promptHint: 'Role, salary, benefits, joining date, terms',
      category: DocumentCategoryType.hrEmployment,
      requiredKeys: const [
        'companyName',
        'companyAddress',
        'candidateName',
        'candidateAddress',
        'jobTitle',
        'department',
        'workLocation',
        'joiningDate',
        'salary',
      ],
      optionalKeys: const [
        'reportingStructure',
        'responsibilities',
        'keyObjectives',
        'benefits',
        'employmentType',
        'probationPeriod',
        'workingHours',
        'travelRequirement',
      ],
    );
