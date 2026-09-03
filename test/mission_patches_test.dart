import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/pages/launch_details.dart';

MissionPatch patch({String? url}) => MissionPatch(
  name: 'Patch',
  image: url == null ? null : ApiImage(imageUrl: url),
);

void main() {
  group('renderablePatches', () {
    test('keeps patches that have artwork', () {
      final patches = LaunchDetailsPage.renderablePatches([
        patch(url: 'https://example.invalid/a.png'),
        patch(url: 'https://example.invalid/b.png'),
      ]);

      expect(patches, hasLength(2));
    });

    test('drops patches with no image at all', () {
      // The section count is derived from this, so an unfiltered count would
      // advertise "1" and then expand to nothing.
      expect(LaunchDetailsPage.renderablePatches([patch()]), isEmpty);
    });

    test('drops patches whose image carries no url', () {
      final patches = LaunchDetailsPage.renderablePatches([
        const MissionPatch(name: 'Patch', image: ApiImage(thumbnailUrl: null)),
      ]);

      expect(patches, isEmpty);
    });

    test('keeps only the renderable ones from a mixed list', () {
      final patches = LaunchDetailsPage.renderablePatches([
        patch(),
        patch(url: 'https://example.invalid/a.png'),
        patch(),
      ]);

      expect(patches, hasLength(1));
    });

    test('an empty list stays empty', () {
      expect(LaunchDetailsPage.renderablePatches(const []), isEmpty);
    });
  });
}
