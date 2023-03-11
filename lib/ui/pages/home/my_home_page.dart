import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/fib_calculator.dart';
import 'components/animated_gear.dart';
import 'components/section.dart';

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text(title),
    );

    return FutureBuilder(
      future: FibCalculator.create(),
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (data == null) {
          return Scaffold(
            appBar: appBar,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Provider(
          create: (context) => data,
          builder: (context, child) => StatefulBuilder(
            builder: (context, setState) {
              var runHeavyTaskKey = UniqueKey();
              var runHeavyTaskWithArgsKey = UniqueKey();
              var runHeavyTaskWithArgsStreamKey = UniqueKey();

              return Scaffold(
                appBar: appBar,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AnimatedGear(),
                      FutureBuilder(
                        key: runHeavyTaskKey,
                        future: context.read<FibCalculator>().findFib(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.toString() ?? '';

                          return Section(title: 'Calc 40th fib:', result: data);
                        },
                      ),
                      FutureBuilder(
                        key: runHeavyTaskWithArgsKey,
                        future: context.read<FibCalculator>().findFibTo(42),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.toString() ?? '';

                          return Section(title: 'Calc 42nd fib:', result: data);
                        },
                      ),
                      StreamBuilder(
                        key: runHeavyTaskWithArgsStreamKey,
                        stream: context.read<FibCalculator>().findAllFibTo(42),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.toString() ?? '';

                          return Section(title: 'Calc all 42nd fibs:', result: data);
                        },
                      ),
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      runHeavyTaskKey = UniqueKey();
                      runHeavyTaskWithArgsKey = UniqueKey();
                      runHeavyTaskWithArgsStreamKey = UniqueKey();
                    });
                  },
                  child: const Icon(Icons.replay),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
