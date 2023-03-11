import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimatedGear extends StatefulWidget {
  const AnimatedGear({super.key});

  @override
  State<AnimatedGear> createState() => _AnimatedGearState();
}

class _AnimatedGearState extends State<AnimatedGear> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((elapsed) {
      setState(() {
        _angle = (_angle + 5 * pi / 180) % (2 * pi);
      });
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _angle,
      child: const Icon(
        Icons.settings,
        size: 100,
        color: Colors.blue,
      ),
    );
  }
}
