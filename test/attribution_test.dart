import 'package:rockit/mixins/attribution.dart';
import 'package:test/test.dart';

class SourceAttributionTest with SourceAttribution {}

/// The name a source link shows instead of a bare domain.
void main() {
  String? name(String url) =>
      SourceAttribution.nameForHost(Uri.parse(url).host);

  test('Make sure all website domains are lowercase', () {
    for (final key in [
      ...SourceAttribution.specialHostFuncs.keys,
      ...SourceAttribution.hostNames.keys,
    ]) {
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
    expect(
      sa.urlHost("https://blogs.nasa.gov/artemis/2022/02/02/artemis-i-update/"),
      "blogs.nasa.gov",
    );

    expect(
      sa.urlHost("https://twitter.com/status/example/102385913859?s=25"),
      "twitter.com",
    );
  });

  test('Domains cover their subdomains', () {
    // The API puts announcements on press rooms, investor pages and blogs
    // constantly, and listing every subdomain was a losing game.
    expect(name('https://science.nasa.gov/mission'), 'NASA');
    expect(name('https://blogs.nasa.gov/artemis/'), 'NASA');
    expect(name('https://investors.rocketlabcorp.com/news'), 'Rocket Lab');
    expect(name('https://newsroom.arianespace.com/x'), 'Arianespace');
    expect(name('https://www.spaceforce.mil/News/x'), 'U.S. Space Force');
    expect(name('https://other.faa.gov/x'), 'FAA');
    expect(name('https://global.jaxa.jp/x'), 'JAXA');
  });

  test('Both Rocket Lab domains are covered', () {
    // The API uses the old and the new one, and both appear on their investor
    // subdomains too.
    expect(name('https://rocketlabcorp.com/updates'), 'Rocket Lab');
    expect(name('https://www.rocketlabusa.com/updates'), 'Rocket Lab');
    expect(name('https://investors.rocketlabusa.com/x'), 'Rocket Lab');
  });

  test('The longest match wins', () {
    // Both are in the list; the forum must not read as the news site.
    expect(
      name('https://forum.nasaspaceflight.com/index.php?topic=1'),
      'NASASpaceFlight Forum',
    );
    expect(name('https://www.nasaspaceflight.com/article'), 'NASASpaceFlight');
  });

  test('A subdomain that says more than its domain wins', () {
    // "U.S. Space Force" says nothing about a launch weather forecast, and
    // this is the most linked host in the survey after the providers.
    expect(
      name('https://45thweathersquadron.nebula.spaceforce.mil/x'),
      '45th Weather Squadron',
    );
    expect(name('https://ssc.spaceforce.mil/x'), 'Space Systems Command');
    expect(name('https://notams.aim.faa.gov/x'), 'FAA NOTAM');
    expect(name('https://fly.faa.gov/adv/x'), 'FAA Advisory');

    // ...and the parent still answers for anything else under it.
    expect(name('https://www.spaceforce.mil/News/x'), 'U.S. Space Force');
    expect(name('https://other.faa.gov/x'), 'FAA');
  });

  test('An unknown host keeps its own domain', () {
    // News outlets are deliberately absent: their domain reads perfectly well
    // as a source, and there is no end to them.
    expect(name('https://arstechnica.com/space/x'), isNull);
    expect(name('https://example.invalid/x'), isNull);
  });

  test('A domain that merely ends the same way is not a match', () {
    expect(name('https://notnasa.gov/x'), isNull);
    expect(name('https://fakespacex.com/x'), isNull);
  });

  test('A bucket is named without naming its host', () {
    // amazonaws.com is not NASA, but this bucket is.
    expect(name('https://nasa-public-data.s3.amazonaws.com/x'), 'NASA');
    expect(name('https://something-else.s3.amazonaws.com/x'), isNull);
  });
}
