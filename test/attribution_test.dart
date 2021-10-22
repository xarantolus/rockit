// Import the test package and Counter class
import 'package:test/test.dart';
import 'package:rockit/mixins/attribution.dart';

class SourceAttributionTest with SourceAttribution {}

void main() {
  test('Make sure all website domains are lowercase', () {
    for (var key in SourceAttribution.specialHostFuncs.keys) {
      expect(key.toLowerCase(), key);
    }
  });

  test('Link hosts are extracted correctly', () {
    var sa = SourceAttributionTest();

    expect(sa.urlHost(null), null);
    expect(sa.urlHost(""), null);

    expect(sa.urlHost("https://nasa.gov"), "nasa.gov");
    expect(sa.urlHost("https://www.nasa.gov"), "nasa.gov");
    expect(sa.urlHost("https://mars.nasa.gov"), "mars.nasa.gov");

    expect(sa.urlHost("https://twitter.com/status/example/102385913859?s=25"),
        "twitter.com");
  });
}
