import 'package:flutter/material.dart';

class Section extends StatelessWidget {
  final String title;
  final String result;

  const Section({
    super.key,
    required this.title,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: style,
        ),
        const SizedBox(width: 4),
        Text(
          result,
          style: style,
        ),
      ],
    );
  }
}
