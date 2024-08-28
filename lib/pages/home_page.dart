import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/pages/article_listing.dart';
import 'package:rockit/pages/credits_page.dart';
import 'package:rockit/pages/event_details.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/pages/subscription_listing.dart';
import 'package:rockit/pages/upcoming_events_listing.dart';
import 'package:rockit/pages/upcoming_launches_listing.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/launch_event_search.dart';
import 'package:rockit/widgets/addons/overline_tab_indicator.dart';

class RockItHomePage extends StatefulWidget {
  const RockItHomePage(this.appPayload, {Key? key, required this.title}) : super(key: key);

  final ValueNotifier<String> appPayload;

  final String title;

  @override
  State<RockItHomePage> createState() => _RockItHomePageState();
}

class _RockItHomePageState extends State<RockItHomePage> with UrlLauncher {
  @override
  void initState() {
    super.initState();

    unawaited(pushPayloadPage());
    widget.appPayload.addListener(pushPayloadPage);
  }

  // pushPayloadPage is called when the app is opened via a notification.
  // It checks if we have a payload and then opens the appropriate details page
  Future<void> pushPayloadPage() async {
    try {
      String payload = widget.appPayload.value;
      if (payload.isEmpty) {
        return;
      }

      final splitPayload = payload.split("::");
      if (splitPayload.length < 2) {
        return;
      }

      final action = splitPayload[0];
      final data = splitPayload.sublist(1).join("::");

      switch (action) {
        case BackgroundHandler.actionLaunchDetails:
          // If we received a notification about a launch, we 99% sure have that launch cached
          final launch = await LaunchLibraryAPI().launch(data, true);

          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => LaunchDetailsPage(launch.data),
          ));
          break;
        case BackgroundHandler.actionEventDetails:
          final event = await LaunchLibraryAPI().event(data, true);

          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => EventDetailsPage(event.data),
          ));
          break;
      }
    } catch (e) {
      debugPrint("Error while pushing initial page: $e");
    }
  }

  Future<void> _openAppDownloadLink() async {
    var ok = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.downloadApp),
        content: Text(AppLocalizations.of(context)!.downloadAppDescription),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.openWebsite),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    launchURL(context, "https://github.com/xarantolus/rockit/releases/latest");
  }

  bool isLoadingSearch = false;

  Future<void> _showSearch(void Function(void Function()) setState) async {
    if (isLoadingSearch) {
      return;
    }
    setState(() {
      isLoadingSearch = true;
    });

    final delegate = await LaunchEventSearchDelegate.searchLaunchesAndEvents(context);

    delegate.maybeShowSnack(context);

    await showSearch(
      context: context,
      delegate: delegate.data,
      query: '',
    );

    setState(() {
      isLoadingSearch = false;
    });
  }

  AppBar _buildAppBar(BuildContext context, ImageIcon appIcon) {
    return CustomAppBar.create(
      context,
      title: widget.title,
      titleStyle: const TextStyle(fontWeight: FontWeight.w900),
      icon: appIcon,
      actions: [
        if (kIsWeb)
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: AppLocalizations.of(context)!.downloadApp,
            onPressed: () async {
              await _openAppDownloadLink();
            },
          ),
        if (!kIsWeb)
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            tooltip: AppLocalizations.of(context)!.subscriptions,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionListingPage(),
                ),
              );
            },
          ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          tooltip: AppLocalizations.of(context)!.sources,
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CreditPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  TabBar _buildNavigationBar(BuildContext context, ImageIcon appIcon) {
    return TabBar(
      labelColor: Theme.of(context).textTheme.bodyMedium!.color,
      automaticIndicatorColorAdjustment: true,
      indicator: OverlineTabIndicator(
        borderSide: BorderSide(
          color: Theme.of(context).textTheme.bodyMedium!.color!,
          width: 3,
        ),
      ),
      tabs: [
        Tab(
          icon: appIcon,
          text: AppLocalizations.of(context)!.launches,
        ),
        Tab(
          icon: const Icon(Icons.event),
          text: AppLocalizations.of(context)!.events,
        ),
        Tab(
          icon: const Icon(Icons.article_outlined),
          text: AppLocalizations.of(context)!.news,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const appIcon = ImageIcon(AssetImage("assets/rocket-white-small.png"), color: Colors.white);

    final lightTheme = Theme.of(context).brightness == Brightness.light;
    final menuRocketIcon = ImageIcon(
      lightTheme
          ? const AssetImage("assets/rocket-black-small.png")
          : const AssetImage("assets/rocket-white-small.png"),
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: kIsWeb
            ? null
            : StatefulBuilder(
                builder: (context, state) {
                  return FloatingActionButton(
                    onPressed: () => _showSearch(state),
                    child: isLoadingSearch
                        ? CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : const Icon(Icons.search),
                    tooltip: AppLocalizations.of(context)!.search,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
        appBar: _buildAppBar(context, appIcon),
        bottomNavigationBar: _buildNavigationBar(context, menuRocketIcon),
        body: TabBarView(
          children: [
            UpcomingLaunchesPage(),
            UpcomingEventsPage(),
            ArticleListingPage(),
          ],
        ),
      ),
    );
  }
}
