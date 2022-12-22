import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'package:pedometer/pedometer_bindings_generated.dart' as pd;
import 'dart:typed_data';

const _dylibPath = '/System/Library/Frameworks/CoreMotion.framework/CoreMotion';
// Bindings for the CMPedometer class
final lib = pd.PedometerBindings(ffi.DynamicLibrary.open(_dylibPath));
// Bindings for the helper function
final lib2 = pd.PedometerBindings(ffi.DynamicLibrary.process());

void main() {
  // Contains the Dart API helper functions
  final dylib = ffi.DynamicLibrary.open("pedometer.framework/pedometer");

  // Initialize the Dart API
  final initializeApi = dylib.lookupFunction<
      ffi.IntPtr Function(ffi.Pointer<ffi.Void>),
      int Function(ffi.Pointer<ffi.Void>)>('Dart_InitializeApiDL');
  assert(initializeApi(ffi.NativeApi.initializeApiDLData) == 0);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class RoundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final diameter = size.shortestSide * 1.5;
    final x = -(diameter - size.width) / 2;
    final y = size.height - diameter;
    final rect = Offset(x, y) & Size(diameter, diameter);
    return Path()..addOval(rect);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}

// Class to hold the information needed to make an API call to the pedometer
class PedometerCall {
  // String name;
  pd.NSString start;
  pd.NSString end;

  PedometerCall(this.start, this.end);
}

// Class to hold the information needed for the chart
class PedometerResults {
  int startHour;
  int steps;

  // Add total method

  PedometerResults(this.startHour, this.steps);
}

class Home extends StatefulWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late pd.CMPedometer client;
  late pd.NSDateFormatter formatter;
  var totalSteps = 0;

  // late DateTime lastUpdated;

  // Handles the data received from native side
  // Open up a port to receive data from native side
  static final receivePort = ReceivePort()..listen(handler);
  static final nativePort = receivePort.sendPort.nativePort;
  static void handler(data) {
    print("receiving data $data");
    final result = ffi.Pointer<pd.ObjCObject>.fromAddress(data as int);
    final pedometerData = pd.CMPedometerData.castFromPointer(lib, result);
    // setState(() {
    //   totalSteps = pedometerData.numberOfSteps;
    // });
    final stepCount = pedometerData.numberOfSteps;
    // print("This is the pointer $stepCount.");
    receivePort.close();
  }

  @override
  void initState() {
    client = pd.CMPedometer.new1(lib);
    // Create a list of all the start and end calls
    // update();

    // Setting the formatter
    final formatter =
        pd.NSDateFormatter.castFrom(pd.NSDateFormatter.alloc(lib).init());
    formatter.dateFormat = pd.NSString(lib, "yyyy-MM-dd HH:mm:ss zzz");
    formatter.locale = pd.NSLocale.alloc(lib)
        .initWithLocaleIdentifier_(pd.NSString(lib, "en_US"));
    super.initState();
  }

  pd.NSDate dateConverter(DateTime dartDate) {
    final nString = pd.NSString(lib, dartDate.toString());
    return formatter.dateFromString_(nString);
  }

  // Next try feeding in the pedometer too
  void runPedometer() async {
    print("Running pedometer");
    final start = dateConverter(DateTime.now().subtract(Duration(hours: 24)));
    final end = dateConverter(DateTime.now());

//    final start = DateTime.now().subtract(Duration(hours: 24));
//    final end = DateTime.now();
    pd.PedometerHelper.startPedometerWithPort_pedometer_start_end_(
        lib2, nativePort, client, start, end);
  }

// Update the timestamps and refresh the pedometer
  // void update() {
  //   var local_calls = [];
  //   final start = new DateTime.now().subtract(new Duration(hours: 24));
  //   final end = new DateTime.now();
  // Generate 24 calls, each with a start date 1 hour apart
  // for (var i = 0; i < 24; i++) {
  //   final _start = start.subtract(new Duration(hours: 24 - i));
  //   final _end = start.subtract(new Duration(hours: 23 - i));
  //   local_calls.add(PedometerCall(
  //       _start.hour.toString(),
  //       pd.NSString(lib, _start.toString()),
  //       pd.NSString(lib, _end.toString())));
  // }}
  //  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          ClipPath(
            clipper: RoundClipper(),
            child: FractionallySizedBox(
              heightFactor: 0.5,
              widthFactor: 1,
              child: Container(
                color: Colors.blue[300],
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalSteps.toString(),
                        style: textTheme.displayMedium!
                            .copyWith(color: Colors.white),
                      ),
                      Text(
                        'steps',
                        style:
                            textTheme.titleSmall!.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => runPedometer(),
                  child: const Text('Refresh using Native Ports!'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
