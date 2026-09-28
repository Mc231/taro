import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

/// The `Clock` contract (02 §5, rule 5): [Clock.now] is UTC and does not
/// go backwards; [Clock.nowLocal] is a local wall-clock time whose offset
/// from UTC is a real zone offset (a multiple of 15 min within ±14 h).
void runClockContract(Clock Function() create) {
  group('Clock contract', () {
    late Clock clock;

    setUp(() => clock = create());

    test('now is UTC and monotonic', () {
      final a = clock.now();
      final b = clock.now();
      expect(a.isUtc, isTrue);
      expect(b.isBefore(a), isFalse);
    });

    test('nowLocal is local wall-clock time at a real offset', () {
      final utc = clock.now();
      final local = clock.nowLocal();
      expect(local.isUtc, isFalse);
      final wall = DateTime.utc(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
        local.second,
      );
      final offsetMin =
          (wall.difference(utc).inSeconds / Duration.secondsPerMinute).round();
      expect(offsetMin % 15, 0, reason: 'offset $offsetMin min');
      expect(offsetMin.abs(), lessThanOrEqualTo(14 * 60));
    });
  });
}

/// The `TimezoneProvider` contract (02 §5): an IANA zone name.
void runTimezoneProviderContract(TimezoneProvider Function() create) {
  group('TimezoneProvider contract', () {
    test('reports an IANA zone name', () async {
      final iana = await create().currentIana();
      expect(
        iana,
        matches(RegExp(r'^(UTC|[A-Z][A-Za-z_]+(/[A-Za-z0-9_+-]+)+)$')),
      );
    });
  });
}

/// The `RandomSource` contract (02 §4.1, PR7, 06 §2.1): values in range,
/// every value reachable, both booleans. Statistical checks use a fixed
/// sample size; a correct source fails them with negligible probability.
void runRandomSourceContract(RandomSource Function() create) {
  group('RandomSource contract', () {
    late RandomSource random;

    setUp(() => random = create());

    test('nextInt(1) is always 0', () {
      for (var i = 0; i < 20; i++) {
        expect(random.nextInt(1), 0);
      }
    });

    test('nextInt stays in [0, max) up to 2^32', () {
      for (final max in [2, 3, 7, 78, 1000, 1 << 31, (1 << 32) - 1, 1 << 32]) {
        for (var i = 0; i < 200; i++) {
          final v = random.nextInt(max);
          expect(v, inInclusiveRange(0, max - 1), reason: 'max $max');
        }
      }
    });

    test('every value of a small range is reached', () {
      final seen = <int>{};
      for (var i = 0; i < 2000; i++) {
        seen.add(random.nextInt(78));
      }
      expect(seen, hasLength(78));
    });

    test('draws are spread evenly', () {
      final counts = List.filled(6, 0);
      const n = 6000;
      for (var i = 0; i < n; i++) {
        counts[random.nextInt(6)]++;
      }
      for (final c in counts) {
        expect(c, inInclusiveRange(800, 1200));
      }
    });

    test('nextBool yields both values', () {
      final values = {for (var i = 0; i < 200; i++) random.nextBool()};
      expect(values, {true, false});
    });
  });
}

/// The `IdGenerator` contract (RC41, RC42): canonical lowercase UUIDv4s,
/// never repeated.
void runIdGeneratorContract(IdGenerator Function() create) {
  group('IdGenerator contract', () {
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('issues distinct canonical UUIDv4s', () {
      final ids = create();
      final issued = [for (var i = 0; i < 1000; i++) ids.uuidV4()];
      for (final id in issued) {
        expect(id, matches(uuidV4));
      }
      expect(issued.toSet(), hasLength(issued.length));
    });
  });
}

/// The `Logger` contract (RC41): every level accepts an optional error and
/// stack, and children are loggers too. Logging never throws.
void runLoggerContract(Logger Function() create) {
  group('Logger contract', () {
    test('logs at every level, with and without an error', () {
      final logger = create();
      final stack = StackTrace.current;
      logger
        ..fine('fine')
        ..info('info')
        ..warning('warning', error: StateError('x'))
        ..severe('severe', error: 'e', stack: stack);
    });

    test('children log too', () {
      final child = create().child('sync').child('balance');
      expect(child, isA<Logger>());
      child.info('from a child');
    });
  });
}
