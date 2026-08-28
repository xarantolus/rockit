import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/widgets/image.dart';

/// The decode size is part of Flutter's image cache key, so it has to be stable
/// as a box changes size — otherwise a hero flight, which interpolates its box
/// on every frame, decodes the photo again for each one. That is the whole
/// reason these are buckets rather than exact numbers, and it is not something
/// a screenshot would ever show, so it is pinned here.
void main() {
  int bucket(double px) => decodeBucketFor(px);

  group('decode buckets', () {
    test('a box gets at least twice its longest edge', () {
      // The bound is a square the image is scaled to fit inside, so the
      // headroom is what keeps it covering the box afterwards.
      for (final px in [100.0, 264.0, 500.0, 700.0]) {
        expect(bucket(px), greaterThanOrEqualTo(px * 2));
      }
    });

    test('a box that changes a little keeps the same bucket', () {
      // The launch card is 373dp wide and the detail hero is 393dp; at 2.75x
      // that is 1026 to 1081 physical pixels, interpolated across the flight.
      final across = [1026.0, 1040.0, 1055.0, 1070.0, 1081.0].map(bucket);

      expect(across.toSet(), hasLength(1));
    });

    test('the card and the page share one decode', () {
      expect(bucket(1026), bucket(1081));
    });

    test('a full-width box lands above anything the APIs serve', () {
      // 1920x1280 is the largest either API returns, so these are never
      // resized — allowUpscaling is off, so the bound simply does not bite.
      expect(bucket(1081), greaterThanOrEqualTo(1920));
    });

    test('a small box still gets a real reduction', () {
      // The news row is 96dp, or 264 physical pixels on this emulator. Before
      // bucketing it decoded the full 1920-wide press photo.
      expect(bucket(264), lessThan(1920));
      expect(bucket(264), greaterThanOrEqualTo(528));
    });

    test('is monotonic, so a bigger box never decodes smaller', () {
      var previous = 0;

      for (var px = 10.0; px < 3000; px += 37) {
        final value = bucket(px);
        expect(value, greaterThanOrEqualTo(previous));
        previous = value;
      }
    });

    test('is bounded at both ends', () {
      expect(bucket(0), greaterThan(0));
      expect(bucket(0.5), greaterThan(0));
      expect(bucket(100000), 2048);
    });

    test('only ever returns whole buckets', () {
      for (var px = 1.0; px < 2000; px += 13) {
        expect(bucket(px) % 256, 0);
      }
    });
  });
}
