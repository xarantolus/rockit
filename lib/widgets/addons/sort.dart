import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';

DateTime? getDate(dynamic d) {
  if (d is Launch) {
    return DateTime.tryParse(d.net ?? d.windowStart ?? "")?.toLocal();
  }

  return (d as Event).date;
}

List<dynamic> sortLaunchesAndEvents(List<dynamic> list) {
  list.sort((a, b) {
    final ad = getDate(a);
    final bd = getDate(b);
    if (ad == null || bd == null) {
      return 0;
    }
    return ad.compareTo(bd);
  });

  return list;
}
