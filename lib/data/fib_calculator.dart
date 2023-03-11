// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:isolate';

import 'package:stream_channel/isolate_channel.dart';
import 'package:uuid/uuid.dart';

class FibCalculator {
  final _uuid = const Uuid();
  late Isolate _isolate;
  late ReceivePort _port;
  late IsolateChannel _channel;
  late Stream _stream;

  FibCalculator._();

  static Future<FibCalculator> create() async {
    final instance = FibCalculator._();
    await instance._initialize();
    return instance;
  }

  Future<int> findFib() => _execute('findFib');

  Future<int> findFibTo(int argument) => _execute('findFibTo', argument);

  Stream<int> findAllFibTo(int argument) => _executeStream('findAllFibTo', argument);

  void dispose() {
    _port.close();
    _isolate.kill();
  }

  Future<void> _initialize() async {
    final port = ReceivePort();
    _port = port;
    _channel = IsolateChannel.connectReceive(port);
    _stream = _channel.stream.asBroadcastStream();
    _isolate = await Isolate.spawn(_entryPoint, port.sendPort);
  }

  static void _entryPoint(SendPort port) {
    final fibCalculator = _FibCalculator();
    final channel = IsolateChannel.connectSend(port);

    final handlers = {
      'findFib': (dynamic data) async {
        try {
          final users = await fibCalculator.findFib();
          channel.sink.add([data[0] as String, true, users]);
        } catch (error, stackTrace) {
          channel.sink.add([data[0] as String, true, error, stackTrace]);
        }
      },
      'findFibTo': (dynamic data) async {
        try {
          final posts = await fibCalculator.findFibTo(data[2] as int);
          channel.sink.add([data[0] as String, true, posts]);
        } catch (error, stackTrace) {
          channel.sink.add([data[0] as String, true, error, stackTrace]);
        }
      },
      'findAllFibTo': (dynamic data) async {
        fibCalculator.findAllFibTo(data[2] as int).listen(
          (event) {
            channel.sink.add([data[0] as String, false, event]);
          },
          onError: (error, stackTrace) {
            channel.sink.add([data[0] as String, false, error, stackTrace]);
          },
          onDone: () {
            channel.sink.add([data[0] as String, true]);
          },
        );
      },
    };

    channel.stream.listen((data) async {
      handlers[data[1] as String]!.call(data);
    });
  }

  Future<T> _execute<T>(String method, [dynamic params]) async {
    final id = _uuid.v4();
    final completer = Completer<T>();

    late StreamSubscription subscription;
    subscription = _stream.listen(
      (event) {
        if (event[0] as String == id) {
          if (event[2] is Exception) {
            completer.completeError(event[2] as Object, event[3] as StackTrace);
            subscription.cancel();
          } else {
            completer.complete(event[2] as T);
            subscription.cancel();
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        completer.completeError(error, stackTrace);
        subscription.cancel();
      },
      onDone: () {
        completer.completeError(Exception('Isolate closed'));
        subscription.cancel();
      },
    );

    _channel.sink.add([id, method, params]);

    return completer.future;
  }

  Stream<T> _executeStream<T>(String method, [dynamic params]) async* {
    final id = _uuid.v4();
    final controller = StreamController<T>();

    late StreamSubscription subscription;
    subscription = _stream.listen(
      (event) {
        if (event[0] as String == id) {
          if (event[1] as bool) {
            controller.close();
            subscription.cancel();
          } else {
            if (event[2] is Exception) {
              controller.addError(event[2] as Object, event[3] as StackTrace);
            } else {
              controller.add(event[2] as T);
            }
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        controller
          ..addError(error, stackTrace)
          ..close();
        subscription.cancel();
      },
      onDone: () {
        controller
          ..addError(Exception('Isolate closed'))
          ..close();
        subscription.cancel();
      },
    );

    _channel.sink.add([id, method, params]);

    yield* controller.stream;
  }
}

class _FibCalculator {
  Future<int> findFib() async {
    return _slowFib(40);
  }

  Future<int> findFibTo(int argument) async {
    return _slowFib(argument);
  }

  Stream<int> findAllFibTo(int argument) async* {
    for (var i = 0; i <= argument; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield _slowFib(i);
    }
  }

  int _slowFib(int n) => n <= 1 ? 1 : _slowFib(n - 1) + _slowFib(n - 2);
}
