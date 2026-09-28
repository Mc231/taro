import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'model_fixtures.dart';

void main() {
  group('ReadingContent', () {
    test('maps the 03 §9.1 wire object (RC30)', () {
      final wire = {
        'title': 'A turning point',
        'overview': 'Overview',
        'cards': [
          for (final p in ['past', 'present', 'future'])
            {
              'positionId': p,
              'cardId': 'major_16',
              'reversed': false,
              'interpretation': '${p[0].toUpperCase()}${p.substring(1)} text',
            },
        ],
        'synthesis': 'Synthesis',
        'reflectionPrompts': ['What changes?', 'What stays?'],
      };
      expect(ReadingContent.fromWire(wire), content);
    });

    test('domain JSON round trip', () {
      final json = content.toJson();
      expect(json['summary'], 'Overview');
      expect((json['positions']! as List).first, {
        'positionId': 'past',
        'text': 'Past text',
      });
      expect(ReadingContent.fromJson(json), content);
    });

    test('textFor and copyWith', () {
      expect(content.textFor(const PositionId('future')), 'Future text');
      expect(content.textFor(const PositionId('nope')), isNull);
      expect(content.copyWith(title: 'x'), isNot(content));
      expect(
        content.positions.first.copyWith(text: 'y').text,
        'y',
      );
    });

    test('rejects malformed wire input', () {
      expect(
        () => ReadingContent.fromWire({'title': 'x'}),
        throwsFormatException,
      );
    });
  });

  group('SafetyInfo', () {
    test('parses a declined safety object (03 §9.1)', () {
      final info = SafetyInfo.fromJson({
        'category': 'self_harm',
        'messageKey': 'safetyDeclinedSelfHarm',
        'crisisResources': [
          {
            'name': 'Telefonseelsorge',
            'phone': '0800 111 0 111',
            'url': 'https://www.telefonseelsorge.de',
            'hours': '24/7',
            'languages': ['de'],
            'verifiedAt': '2026-09-01T00:00:00Z',
          },
        ],
        'canRephrase': false,
      });
      expect(info.category, RefusalCategory.selfHarm);
      expect(info.canRephrase, isFalse);
      expect(info.crisisResources.single.hours, '24/7');
      expect(SafetyInfo.fromJson(info.toJson()), info);
    });

    test('defaults messageKey and resources; unknown category is other', () {
      final info = SafetyInfo.fromJson({
        'category': 'brand_new',
        'canRephrase': true,
      });
      expect(info.category, RefusalCategory.other);
      expect(info.messageKey, 'refusalGeneric');
      expect(info.crisisResources, isEmpty);
      expect(info.copyWith(canRephrase: false), isNot(info));
    });
  });

  group('ReadingStatus', () {
    const failure = Failure.aiUnavailable();
    final table = <ReadingStatus, (String, bool)>{
      const ReadingStatus.pending(): ('pending', false),
      const ReadingStatus.complete(): ('complete', true),
      const ReadingStatus.refused(): ('refused', true),
      const ReadingStatus.failed(failure): ('failed', false),
      const ReadingStatus.classic(): ('classic', true),
    };
    for (final MapEntry(key: status, value: expected) in table.entries) {
      test('${expected.$1}: wire and exportability', () {
        expect(status.wire, expected.$1);
        expect(status.isExportable, expected.$2);
      });
    }

    test('failed carries the failure and refund flag', () {
      const status = ReadingStatus.failed(failure, refunded: true);
      expect(status, isA<ReadingStatusFailed>());
      const failed = status as ReadingStatusFailed;
      expect(failed.failure, failure);
      expect(failed.refunded, isTrue);
      const plain = ReadingStatus.failed(failure) as ReadingStatusFailed;
      expect(plain.refunded, isFalse);
      expect(status, isNot(plain));
    });

    test('refused carries optional safety info', () {
      const info = SafetyInfo(
        category: RefusalCategory.health,
        messageKey: 'safetyDeclinedHealth',
        canRephrase: true,
      );
      const status = ReadingStatus.refused(safety: info);
      expect((status as ReadingStatusRefused).safety, info);
      expect(status, isNot(const ReadingStatus.refused()));
    });
  });

  group('RatingReason', () {
    test('wire names', () {
      expect(RatingReason.values.map((r) => r.wire), [
        'too_generic',
        'mismatch',
        'tone',
        'other',
      ]);
      expect(RatingReason.fromWire('too_generic'), RatingReason.tooGeneric);
      expect(RatingReason.fromWire('nope'), isNull);
    });
  });

  group('Reading', () {
    test('defaults, accessors and equality', () {
      final reading = completeReading();
      expect(reading.spreadId, const SpreadId('three_ppf'));
      expect(reading.cards, hasLength(3));
      expect(reading.isExportable, isTrue);
      expect(reading.reported, isFalse);
      expect(reading.chargeSource, isNull);
      expect(reading, completeReading());
      expect(reading.copyWith(note: 'longer note'), isNot(reading));
      final bare = Reading(
        id: const ReadingId('r'),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        localDate: '2026-01-01',
        draw: threeCardDraw(),
        status: const ReadingStatus.pending(),
        contentLocale: 'en',
      );
      expect(bare.favourite, isFalse);
      expect(bare.deliveryAcked, isFalse);
    });

    test('backup JSON matches the schema shape', () {
      final json = completeReading().toBackupJson();
      expect(json.keys, [
        'id',
        'createdAt',
        'updatedAt',
        'localDate',
        'spreadId',
        'question',
        'cards',
        'status',
        'content',
        'contentLocale',
        'promptVersion',
        'note',
        'favourite',
        'rating',
        'ratingReason',
      ]);
      expect(json['createdAt'], '2026-09-25T08:00:00Z');
      expect(json['status'], 'complete');
      expect(json['rating'], 'up');
      expect(json['ratingReason'], isNull);
    });

    test('backup round trip keeps every exported field', () {
      final original = completeReading().copyWith(
        rating: Rating.down,
        ratingReason: RatingReason.tone,
        modelId: 'device-only',
        chargeSource: ChargeSource.paid,
      );
      final restored = Reading.fromBackupJson(original.toBackupJson());
      expect(
        restored,
        original.copyWith(modelId: null, chargeSource: null),
      );
    });

    test('classic and refused readings round trip without content', () {
      for (final status in const [
        ReadingStatus.classic(),
        ReadingStatus.refused(),
      ]) {
        final reading = completeReading(status: status).copyWith(
          content: null,
          promptVersion: null,
          rating: null,
        );
        expect(Reading.fromBackupJson(reading.toBackupJson()), reading);
      }
    });

    test('pending and failed readings are not exportable', () {
      for (final status in const [
        ReadingStatus.pending(),
        ReadingStatus.failed(Failure.network()),
      ]) {
        expect(
          () => completeReading(status: status).toBackupJson(),
          throwsStateError,
        );
      }
    });

    test('fromBackupJson rejects bad values', () {
      Map<String, Object?> with_(String key, Object? value) =>
          completeReading().toBackupJson()..[key] = value;
      for (final (key, value) in [
        ('status', 'pending'),
        ('rating', 'sideways'),
        ('ratingReason', 'boring'),
        ('localDate', '25.09.2026'),
        ('createdAt', 'yesterday'),
        ('favourite', 'yes'),
      ]) {
        expect(
          () => Reading.fromBackupJson(with_(key, value)),
          throwsFormatException,
          reason: key,
        );
      }
    });

    test('fromBackupJson uses the given spread version', () {
      final json = completeReading().toBackupJson();
      expect(
        Reading.fromBackupJson(json, spreadVersion: 3).draw.spreadVersion,
        3,
      );
    });
  });
}
