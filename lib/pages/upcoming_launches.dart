import 'package:flutter/material.dart';
import 'package:rockit/launch_library/api.dart';
import 'package:rockit/launch_library/json_convert.dart';
import 'package:rockit/widgets/launch.dart';

class UpcomingLaunchesPage extends StatefulWidget {
  UpcomingLaunchesPage({Key? key}) : super(key: key);

  final service = LaunchLibraryAPI();

  @override
  _UpcomingLaunchesPageState createState() => _UpcomingLaunchesPageState();
}

class _UpcomingLaunchesPageState extends State<UpcomingLaunchesPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<UpcomingResponse>(
        future: widget.service.upcomingLaunches(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final results = snapshot.data!.results;
            if (results?.isEmpty ?? true) {
              return const Center(
                child: Text("There are no items"),
              );
            } else {
              return ListView.builder(
                itemCount: results!.length,
                itemBuilder: (context, index) {
                  return LaunchWidget(results[index]);
                },
              );
            }
          } else if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
