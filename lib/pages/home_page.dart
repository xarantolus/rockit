import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/pages/article_listing.dart';
import 'package:rockit/pages/credits_page.dart';
import 'package:rockit/pages/news_search.dart';
import 'package:rockit/pages/event_details.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/pages/subscription_listing.dart';
import 'package:rockit/pages/upcoming_events_listing.dart';
import 'package:rockit/pages/upcoming_launches_listing.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/floating_nav_bar.dart';
import 'package:rockit/widgets/addons/launch_event_search.dart';
import 'package:rockit/widgets/image.dart';

class RockItHomePage extends StatefulWidget {
  const RockItHomePage(this.appPayload, {super.key, required this.title});

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

    unawaited(_warmOtherTabs());
  }

  /// Loads the tabs the user is not looking at yet.
  ///
  /// A `TabBarView` only builds the tab on screen, so these sat untouched until
  /// first opened and then made the user wait out a ten-second request. Late
  /// and one at a time, so the visible tab gets the network first. Costs a
  /// second Launch Library request per start, out of fifteen an hour.
  Future<void> _warmOtherTabs() async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final events = await LaunchLibraryAPI().upcomingEvents();
      await warmImages(events.data.results.map((e) => e.image?.imageUrl));
    } catch (e) {
      debugPrint("Could not warm the events tab: $e");
    }

    try {
      final articles = await SpaceFlightNewsAPI().articles();
      await warmImages(articles.data.map((a) => a.imageUrl));
    } catch (e) {
      debugPrint("Could not warm the news tab: $e");
    }
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

      // An update notification lands on the same page, but opened on the
      // updates rather than at the top.
      final fromUpdate =
          action == BackgroundHandler.actionLaunchUpdate ||
          action == BackgroundHandler.actionEventUpdate;

      switch (action) {
        case BackgroundHandler.actionLaunchDetails:
        case BackgroundHandler.actionLaunchUpdate:
          // If we received a notification about a launch, we 99% sure have that launch cached
          final launch = await LaunchLibraryAPI().launch(data, true);
          if (!mounted) {
            return;
          }

          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  LaunchDetailsPage(launch.data, openUpdates: fromUpdate),
            ),
          );
          break;
        case BackgroundHandler.actionEventDetails:
        case BackgroundHandler.actionEventUpdate:
          final event = await LaunchLibraryAPI().event(int.parse(data), true);
          if (!mounted) {
            return;
          }

          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  EventDetailsPage(event.data, openUpdates: fromUpdate),
            ),
          );
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
    if (ok != true || !mounted) {
      return;
    }

    launchURL(context, "https://github.com/xarantolus/rockit/releases/latest");
  }

  /// Opens whichever search belongs to the tab being looked at.
  ///
  /// News gets its own, because the two are nothing alike underneath: the
  /// launches one filters what is already cached and must not spend a Launch
  /// Library request, while the news API can simply be asked.
  void _showSearch(BuildContext context) {
    final label = AppLocalizations.of(context)!.search;
    final colour = Theme.of(context).textTheme.bodyLarge?.color;

    if (DefaultTabController.of(context).index == _newsTab) {
      final news = NewsSearchDelegate(
        searchLabel: label,
        searchTextColor: colour,
      );

      unawaited(news.loadCachedLinks());
      unawaited(
        showSearch(
          context: context,
          delegate: news,
          query: '',
        ).whenComplete(news.dispose),
      );

      return;
    }

    final delegate = LaunchEventSearchDelegate(
      searchLabel: label,
      searchTextColor: colour,
    );

    unawaited(delegate.indexCachedPages());
    unawaited(showSearch(context: context, delegate: delegate, query: ''));
  }

  static const _newsTab = 2;

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
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CreditPage()));
          },
        ),
      ],
    );
  }

  /// The tab bar is a plain [TabBar], which — unlike a Material
  /// `NavigationBar` — applies no window insets of its own. Edge-to-edge means
  /// the gesture pill and 3-button navigation draw over it, so pad it out of
  /// their way and paint the surface behind, otherwise the labels sit under the
  /// pill.
  Widget _buildNavigationBar(BuildContext context, ImageIcon appIcon) {
    return FloatingNavBar(
      destinations: [
        NavDestination(
          icon: appIcon,
          label: AppLocalizations.of(context)!.launches,
        ),
        NavDestination(
          icon: const Icon(Icons.event),
          label: AppLocalizations.of(context)!.events,
        ),
        NavDestination(
          icon: const Icon(Icons.article_outlined),
          label: AppLocalizations.of(context)!.news,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const appIcon = ImageIcon(
      AssetImage("assets/rocket-white-small.png"),
      color: Colors.white,
    );

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
            // Builder, so the callback gets a context *below* the
            // DefaultTabController and can read which tab is showing. The
            // state's own context sits above it.
            : Builder(
                builder: (context) => FloatingActionButton(
                  onPressed: () => _showSearch(context),
                  tooltip: AppLocalizations.of(context)!.search,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ),
        appBar: _buildAppBar(context, appIcon),
        // The bar floats, so the body runs underneath it and every scrollable
        // inside has to clear it. Adding the allowance to the inset here means
        // `bottomSystemBarPadding` keeps working unchanged further down.
        extendBody: true,
        bottomNavigationBar: _buildNavigationBar(context, menuRocketIcon),
        body: Builder(
          builder: (context) {
            final media = MediaQuery.of(context);

            return MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(
                  bottom: media.padding.bottom + FloatingNavBar.allowance,
                ),
              ),
              child: TabBarView(
                children: [
                  UpcomingLaunchesPage(),
                  UpcomingEventsPage(),
                  ArticleListingPage(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
