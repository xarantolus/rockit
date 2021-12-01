import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/widgets/article.dart';

mixin ProgramRenderer {
  static const titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  List<Widget> titledList(String title, Iterable<Widget> widgets) {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: titleStyle,
        ),
      ),
      ...widgets,
    ];
  }

  List<Widget> renderProgramInfo(BuildContext context, List<Program> programs) {
    return titledList(
      programs.length == 1
          ? AppLocalizations.of(context)!.program
          : AppLocalizations.of(context)!.programs,
      programs.map((program) {
        return ArticleCardWidget(
          title: program.name,
          summary: program.description,
          imageUrl: program.imageUrl,
          link: program.infoUrl ?? program.wikiUrl,
          fullImage: true,
        );
      }),
    );
  }
}
