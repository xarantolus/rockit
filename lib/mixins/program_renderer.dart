import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/widgets/article.dart';

mixin ProgramRenderer {
  /// See [UpdateRenderer.renderUpdateList] — the caller's section supplies the
  /// heading, so these return only the entries.
  List<Widget> renderProgramInfo(BuildContext context, List<Program> programs) {
    return programs
        .map(
          (program) => ArticleCardWidget(
            title: program.name,
            summary: program.description,
            imageUrl: program.image?.imageUrl,
            link: program.infoUrl ?? program.wikiUrl,
            fullImage: true,
          ),
        )
        .toList();
  }
}
