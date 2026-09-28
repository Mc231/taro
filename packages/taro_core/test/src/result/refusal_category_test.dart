import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

void main() {
  group('RefusalCategory', () {
    const table = <String, (RefusalCategory, String)>{
      'self_harm': (RefusalCategory.selfHarm, 'safetyDeclinedSelfHarm'),
      'harm_to_others': (
        RefusalCategory.harmToOthers,
        'safetyDeclinedHarmToOthers',
      ),
      'health': (RefusalCategory.health, 'safetyDeclinedHealth'),
      'pregnancy': (RefusalCategory.pregnancy, 'safetyDeclinedPregnancy'),
      'death': (RefusalCategory.death, 'safetyDeclinedDeath'),
      'legal': (RefusalCategory.legal, 'safetyDeclinedLegal'),
      'financial': (RefusalCategory.financial, 'safetyDeclinedFinancial'),
      'gambling': (RefusalCategory.gambling, 'safetyDeclinedGambling'),
      'sexual_minors': (
        RefusalCategory.sexualMinors,
        'safetyDeclinedSexualMinors',
      ),
      'hate_or_harassment': (
        RefusalCategory.hateOrHarassment,
        'safetyDeclinedHateOrHarassment',
      ),
    };

    test('has the 03 §9.4 categories plus other', () {
      expect(RefusalCategory.values, hasLength(table.length + 1));
    });

    table.forEach((wire, expected) {
      final (category, messageKey) = expected;
      test('$wire <-> ${category.name}', () {
        expect(RefusalCategory.fromWire(wire), category);
        expect(category.wire, wire);
        expect(category.messageKey, messageKey);
      });
    });

    test('unknown wire values and model refusals map to other', () {
      expect(RefusalCategory.fromWire('brand_new'), RefusalCategory.other);
      expect(RefusalCategory.fromWire('other'), RefusalCategory.other);
      expect(RefusalCategory.other.messageKey, 'refusalGeneric');
    });

    test('crisis resources only for self_harm and harm_to_others', () {
      expect(
        RefusalCategory.values.where((c) => c.showsCrisisResources).toSet(),
        {RefusalCategory.selfHarm, RefusalCategory.harmToOthers},
      );
    });

    test(
      'moderation blocked only for sexual_minors and hate_or_harassment',
      () {
        expect(
          RefusalCategory.values.where((c) => c.isModerationBlocked).toSet(),
          {RefusalCategory.sexualMinors, RefusalCategory.hateOrHarassment},
        );
      },
    );
  });
}
