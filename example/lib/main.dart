import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:pedometer/pedometer_bindings_generated.dart' as pd;

const _dylibPath = '/System/Library/Frameworks/CoreMotion.framework/CoreMotion';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int steps;

  @override
  void initState() {
    print('initState');
    super.initState();
    steps = 0;
  }

  @override
  Widget build(BuildContext context) {
    final lib = pd.PedometerBindings(DynamicLibrary.open(_dylibPath));
    final lib2 = pd.PedometerBindings(DynamicLibrary.process());
    final pedometer = pd.CMPedometer.castFrom(pd.CMPedometer.alloc(lib).init());

    if (pd.CMPedometer.isStepCountingAvailable(lib)) {
      print('Step counting is available.');
      lib2.startPedometer();
    } else {
      print('Step counting is not available.');
    }

    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Native Packages',
          style: TextStyle(),
        ),
      ),
      body: Center(child: Text('You walked this many steps: $steps')),
    ));
  }
}
