import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:infinite_widgets/infinite_widgets.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/pages/event_details.dart';
import 'package:rockit/widgets/event.dart';

class UpcomingEventsPage extends StatefulWidget {
  UpcomingEventsPage({Key? key}) : super(key: key);

  final service = LaunchLibraryAPI();

  @override
  _UpcomingEventsPageState createState() => _UpcomingEventsPageState();
}

class _UpcomingEventsPageState extends State<UpcomingEventsPage>
    with AutomaticKeepAliveClientMixin {
  // Make sure this page is cached, else it would reload often when switching between tabs
  @override
  bool get wantKeepAlive => true;

  late Future<ErrorDetails<UpcomingEventsResponse>> upcomingEventsFuture =
      widget.service.upcomingEvents();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Center(
      child: FutureBuilder<ErrorDetails<UpcomingEventsResponse>>(
        future: upcomingEventsFuture,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const CircularProgressIndicator();
            default:
              if (snapshot.hasError) {
                return GestureDetector(
                  child: ErrorWidget(
                      "${snapshot.error!}\n${AppLocalizations.of(context)!.tapToTryAgain}"),
                  onTap: () => setState(() {
                    upcomingEventsFuture = widget.service.upcomingEvents();
                  }),
                );
              } else {
                snapshot.data!.maybeShowSnack(context);

                final results = snapshot.data!.data.results;
                if (results?.isEmpty ?? true) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noEvents),
                  );
                } else {
                  return EventsList(
                    results!,
                    snapshot.data!.data.next,
                    widget.service,
                  );
                }
              }
          }
        },
      ),
    );
  }
}

class EventsList extends StatefulWidget {
  const EventsList(this.initialEvents, this.initialNextURL, this.service,
      {Key? key})
      : super(key: key);

  final LaunchLibraryAPI service;

  final List<Event> initialEvents;
  final String? initialNextURL;

  @override
  _EventsListState createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
  late List<Event> events = widget.initialEvents;
  late String? nextURL = widget.initialNextURL;

  bool _currentlyLoading = false;

  Future<bool> _updateEvents([bool? refresh]) async {
    if (_currentlyLoading) {
      return true;
    }
    _currentlyLoading = true;

    var error;

    List<Event> newList = [];
    try {
      var _nextURL = refresh == true ? null : nextURL;

      var _newEvents = await widget.service.upcomingEvents(_nextURL);

      _newEvents.maybeShowSnack(context);

      newList = _newEvents.data.results ?? [];

      setState(() {
        // Refresh? => replace
        if (refresh == true) {
          events = newList;
        } else {
          // When we cache responses, it can happen that a page further down the
          // list has been cached, but contains events that were on the previous (non-cached)
          // page. By removing all known events, we make sure this doesn't show up in the UI
          newList.removeWhere(
              (newEvent) => events.any((_evt) => newEvent.id == _evt.id));

          events.addAll(newList);
        }

        nextURL = _newEvents.data.next;
      });
    } catch (e) {
      error = e;
    } finally {
      _currentlyLoading = false;
    }

    if (error != null) {
      throw error;
    }

    return true;
  }

  Future<bool> _loadMore() async {
    try {
      return await _updateEvents(false);
    } catch (_) {
      return false;
    }
  }

  void _openEventDetails(BuildContext context, int index) async {
    void scrollToIndex(int idx, [bool animated = false]) {
      // Scroll the list view to the currently viewed launch. If the user now leaves this view
      // the list will have scrolled to the last viewed item, which is nice

      final wheight = EventWidget.calculateHeight(context);
      final isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
      final targetOffset = max(
          wheight * (isLandscape ? idx / 2 : idx) -
              (isLandscape && idx % 2 == 0 ? 0 : wheight) / 2,
          0.0);

      if (animated) {
        _eventListController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      } else {
        _eventListController.jumpTo(targetOffset);
      }
    }

    scrollToIndex(index, true);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          var pc = PageController(
            initialPage: index,
            // Prevent pages from being cached, else we would sometimes have
            // two hero animations going back to the list, which is really ugly
            keepPage: false,
          );

          var pv = PageView.custom(
            physics: const BouncingScrollPhysics(),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, idx) {
                if (idx >= events.length) {
                  return null;
                }
                return EventDetailsPage(events[idx]);
              },
            ),
            controller: pc,
            onPageChanged: (idx) async {
              // If we are close to the end of currently loaded events, we load the next ones
              if (nextURL != null && idx > events.length - 10) {
                await _loadMore();
              }

              // Always adjust the current scroll position of the list
              scrollToIndex(idx);
            },
          );

          return pv;
        },
      ),
    );
  }

  final ScrollController _eventListController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _updateEvents(true);
      },
      child: InfiniteGridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              MediaQuery.of(context).orientation == Orientation.landscape
                  ? 2
                  : 1,
          mainAxisExtent: EventWidget.calculateHeight(context),
        ),
        hasNext: nextURL != null,
        nextData: _loadMore,
        physics: const BouncingScrollPhysics(),
        controller: _eventListController,
        itemCount: events.length,
        // We pre-load up to 5 screens of info, that way images load already
        cacheExtent: MediaQuery.of(context).size.height * 5,
        itemBuilder: (context, index) {
          return GestureDetector(
            child: EventWidget(events[index]),
            onTap: () => _openEventDetails(context, index),
          );
        },
      ),
    );
  }
}
