import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/cache_janitor.dart';

/// The stores bound themselves by object count and never by bytes, which is
/// how a cache of 96 dp news thumbnails reached a gigabyte — the originals run
/// to 16 MB each. This is the part that actually bounds it.
void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('janitor');
  });

  tearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  /// Files are picked oldest-first, so age has to be controllable.
  File write(String name, int bytes, {required int minutesOld}) {
    final file = File('${dir.path}/$name')
      ..writeAsBytesSync(List.filled(bytes, 0));
    file.setLastModifiedSync(
      DateTime.now().subtract(Duration(minutes: minutesOld)),
    );

    return file;
  }

  int totalBytes() => dir.listSync().whereType<File>().fold(
    0,
    (sum, f) => sum + f.lengthSync(),
  );

  test('leaves a store that is already under budget alone', () async {
    write('a', 100, minutesOld: 90);
    write('b', 100, minutesOld: 10);

    expect(await CacheJanitor.trim(dir, 1000), 0);
    expect(dir.listSync().length, 2);
  });

  test('deletes the oldest files first', () async {
    final oldest = write('oldest', 400, minutesOld: 300);
    final middle = write('middle', 400, minutesOld: 200);
    final newest = write('newest', 400, minutesOld: 10);

    await CacheJanitor.trim(dir, 800);

    expect(oldest.existsSync(), isFalse);
    expect(middle.existsSync(), isTrue);
    expect(newest.existsSync(), isTrue);
  });

  test('stops as soon as it fits, rather than emptying the store', () async {
    for (var i = 0; i < 10; i++) {
      write('f$i', 100, minutesOld: 100 - i);
    }

    final freed = await CacheJanitor.trim(dir, 600);

    expect(totalBytes(), lessThanOrEqualTo(600));
    expect(totalBytes(), greaterThan(0));
    expect(freed, 400);
  });

  test('one oversized file is removed even when it is the only one', () async {
    write('huge', 5000, minutesOld: 5);

    await CacheJanitor.trim(dir, 1000);

    expect(totalBytes(), 0);
  });

  test('a missing directory is not an error', () async {
    final gone = Directory('${dir.path}/nope');

    expect(await CacheJanitor.trim(gone, 100), 0);
  });

  group('expiry', () {
    test('drops responses older than the age limit, budget or not', () async {
      final old = write('old', 10, minutesOld: 60 * 24 * 8);
      final fresh = write('fresh', 10, minutesOld: 60);

      // Far under budget: only age can be doing this.
      await CacheJanitor.trim(dir, 1000, maxAge: const Duration(days: 7));

      expect(old.existsSync(), isFalse);
      expect(fresh.existsSync(), isTrue);
    });

    test('keeps everything when nothing has aged out', () async {
      write('a', 10, minutesOld: 60 * 24 * 6);

      final freed = await CacheJanitor.trim(
        dir,
        1000,
        maxAge: const Duration(days: 7),
      );

      expect(freed, 0);
      expect(dir.listSync().length, 1);
    });

    test('without an age limit, age alone deletes nothing', () async {
      write('ancient', 10, minutesOld: 60 * 24 * 400);

      expect(await CacheJanitor.trim(dir, 1000), 0);
      expect(dir.listSync().length, 1);
    });

    test('applies the age limit and the budget together', () async {
      write('old', 500, minutesOld: 60 * 24 * 9);
      write('big1', 500, minutesOld: 120);
      write('big2', 500, minutesOld: 60);

      await CacheJanitor.trim(dir, 600, maxAge: const Duration(days: 7));

      // The aged one goes for being old, then one more to fit the budget.
      expect(totalBytes(), lessThanOrEqualTo(600));
      expect(File('${dir.path}/old').existsSync(), isFalse);
      expect(File('${dir.path}/big2').existsSync(), isTrue);
    });
  });
}
