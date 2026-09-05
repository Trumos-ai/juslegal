import 'package:flutter_test/flutter_test.dart';
import 'package:juslegal/providers/ai_provider.dart';

void main() {
  group('AnalysisPayloadNormalizer', () {
    late AnalysisPayloadNormalizer normalizer;

    setUp(() {
      normalizer = AnalysisPayloadNormalizer();
    });

    group('normalize', () {
      test('returns a new map without mutating the original', () {
        final original = <String, dynamic>{'case_summary': '  Summary  '};
        final result = normalizer.normalize(original);
        expect(identical(original, result), isFalse);
      });
    });

    group('applyFieldAliases', () {
      test('maps camelCase aliases to canonical snake_case keys', () {
        final result = normalizer.applyFieldAliases({
          'caseSummary': 'Something happened',
          'legalPosition': {'standing': 'good'},
        });
        expect(result['case_summary'], 'Something happened');
        expect(result['legal_position'], {'standing': 'good'});
      });

      test('does not override canonical keys when both are present', () {
        final result = normalizer.applyFieldAliases({
          'case_summary': 'canonical',
          'caseSummary': 'alias',
        });
        expect(result['case_summary'], 'canonical');
      });
    });

    group('sanitizeTextFields', () {
      test('strips markdown artifacts and collapses whitespace', () {
        final result = normalizer.sanitizeTextFields({
          'case_summary': '**Bold** `code` # heading\nmulti   line',
        });
        expect(result['case_summary'], 'Bold code heading multi line');
      });

      test('nulls out whitespace-only values', () {
        final result = normalizer.sanitizeTextFields({
          'disclaimer': '   ',
        });
        expect(result['disclaimer'], isNull);
      });

      test('falls back legal_analysis to law_summary and vice versa', () {
        final result = normalizer.sanitizeTextFields({
          'law_summary': 'The CPA applies.',
        });
        expect(result['legal_analysis'], 'The CPA applies.');
      });
    });

    group('sanitizeListFields', () {
      test('splits multi-line strings into clean list items', () {
        final result = normalizer.sanitizeListFields({
          'steps': '1. Collect invoice\n2. File complaint',
        });
        expect(result['steps'], ['Collect invoice', 'File complaint']);
      });

      test('nulls empty lists', () {
        final result = normalizer.sanitizeListFields({'risk_factors': []});
        expect(result['risk_factors'], isNull);
      });

      test('cross-fills recommended_actions from steps', () {
        final result =
            normalizer.sanitizeListFields({'steps': ['Send notice']});
        expect(result['recommended_actions'], ['Send notice']);
      });
    });

    group('normalizeStrength / _asStrengthScore', () {
      test('clamps scores above 10 down to the 1-10 band', () {
        final result = normalizer.normalizeStrength({'strength': 85});
        expect(result['strength'], inInclusiveRange(1, 10));
      });

      test('clamps out-of-range low scores to MIN_CONFIDENCE_SCORE', () {
        final result = normalizer.normalizeStrength({'strength': 0});
        expect(result['strength'], MIN_CONFIDENCE_SCORE);
      });

      test('clamps out-of-range high scores to MAX_CONFIDENCE_SCORE', () {
        final result = normalizer.normalizeStrength({'strength': 99});
        expect(result['strength'], MAX_CONFIDENCE_SCORE);
      });

      test('maps textual strengths to scores', () {
        expect(normalizer.normalizeStrength({'strength': 'Strong case'})['strength'],
            greaterThan(6));
        expect(
            normalizer.normalizeStrength({'strength': 'Moderate chance'})['strength'],
            5);
        expect(normalizer.normalizeStrength({'strength': 'Weak claim'})['strength'],
            lessThan(4));
      });

      test('falls back to confidence when strength is missing', () {
        final result = normalizer.normalizeStrength({'confidence': 7});
        expect(result['strength'], 7);
      });
    });

    group('normalizeLegalPosition', () {
      test('promotes a text standing into a full map', () {
        final result = normalizer.normalizeLegalPosition({
          'legal_position': 'You may file a complaint.',
          'strength': 8,
        });
        expect(result['legal_position'], isA<Map>());
        final position = result['legal_position'] as Map;
        expect(position['standing'], 'You may file a complaint.');
        expect(position['strength'], 'Strong');
        expect(position['explanation'], '');
      });

      test('sanitizes each field of an existing map', () {
        final result = normalizer.normalizeLegalPosition({
          'legal_position': {
            'standing': '**standing**',
            'strength': null,
            'explanation': 'why',
          },
          'strength': 3,
        });
        final position = result['legal_position'] as Map;
        expect(position['standing'], 'standing');
        expect(position['strength'], 'Weak');
        expect(position['explanation'], 'why');
      });
    });

    group('normalizeAuthorities', () {
      test('normalizes authority name/description/website', () {
        final result = normalizer.normalizeAuthorities({
          'authorities': [
            {
              'name': 'National Consumer Helpline',
              'why_relevant': 'handles complaints',
              'website': 'consumerhelpline.gov.in',
            }
          ],
        });
        final detailed = result['authorities_detailed'] as List;
        expect(detailed, isNotEmpty);
        expect(detailed.first['name'], 'National Consumer Helpline');
        expect(detailed.first['official_website'], 'consumerhelpline.gov.in');
      });

      test('nulls empty authority lists', () {
        final result = normalizer.normalizeAuthorities({'authorities': []});
        expect(result['authorities'], isNull);
      });
    });

    group('normalizeEvidenceChecklist', () {
      test('coerces scalar entries into string lists', () {
        final result = normalizer.normalizeEvidenceChecklist({
          'evidence_checklist': {
            'available': ['Invoice'],
            'recommended': 'Screenshot',
          },
        });
        final checklist = result['evidence_checklist'] as Map;
        expect(checklist['available'], ['Invoice']);
        expect(checklist['recommended'], ['Screenshot']);
      });

      test('produces empty lists when checklist is missing', () {
        final result = normalizer.normalizeEvidenceChecklist({});
        final checklist = result['evidence_checklist'] as Map;
        expect(checklist['available'], isEmpty);
        expect(checklist['recommended'], isEmpty);
      });
    });

    group('buildEvidenceChecklistFallback', () {
      test('combines split available/recommended keys', () {
        final result = normalizer.buildEvidenceChecklistFallback({
          'evidence_available': ['Invoice'],
          'evidence_recommended': ['Photos'],
        });
        expect(result['evidence_checklist'], {
          'available': ['Invoice'],
          'recommended': ['Photos'],
        });
      });

      test('leaves existing checklist untouched', () {
        final result = normalizer.buildEvidenceChecklistFallback({
          'evidence_checklist': {'available': ['A'], 'recommended': []},
          'evidence_available': ['B'],
        });
        expect((result['evidence_checklist'] as Map)['available'], ['A']);
      });
    });

    group('applyRawTextSections / parseSectionsFromText', () {
      test('parses headings from raw prose', () {
        final result = normalizer.applyRawTextSections({
          'analysis': '''
Case Summary: The phone was defective.
Next Steps: Collect invoice
File complaint
Disclaimer: Not legal advice.
''',
        });
        expect(result['case_summary'], contains('phone was defective'));
        expect(result['recommended_actions'], ['Collect invoice', 'File complaint']);
        expect(result['disclaimer'], 'Not legal advice.');
      });

      test('ignores non-string raw payloads', () {
        final result = normalizer.applyRawTextSections({'analysis': 42});
        expect(result.containsKey('case_summary'), isFalse);
      });
    });

    group('constants', () {
      test('confidence bounds and history limits are sane', () {
        expect(MIN_CONFIDENCE_SCORE, 1);
        expect(MAX_CONFIDENCE_SCORE, 10);
        expect(CHAT_HISTORY_LIMIT, 100);
        expect(API_CONTEXT_WINDOW, 10);
      });
    });
  });
}
