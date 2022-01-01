import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class PlanetLoadingAnimation extends StatelessWidget {
  const PlanetLoadingAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final animSize = min(size.width, size.height) / 2;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: animSize,
        maxWidth: animSize,
      ),
      child: const RiveAnimation.asset(
        "assets/animations/One_Planet.riv",
      ),
    );
  }
}
