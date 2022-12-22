import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'package:pedometer/pedometer_bindings_generated.dart' as pd;
import 'package:intl/intl.dart';

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

// Class to hold the information needed for the chart
class PedometerResults {
  String startHour;
  int steps;

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
  late pd.NSDateFormatter hourFormatter;
  late DateTime lastUpdated;
  late int nativePort;
  var hourlySteps = <PedometerResults>[];
  final formatString = "yyyy-MM-dd HH:mm:ss";

  // Open up a port to receive data from native side.
  void recieveSteps() {
    final receivePort = ReceivePort();
    setState(() {
      nativePort = receivePort.sendPort.nativePort;
    });

    // Handle the data received from native side.
    receivePort.listen((data) {
      final result = ffi.Pointer<pd.ObjCObject>.fromAddress(data as int);
      final pedometerData =
          pd.CMPedometerData.castFromPointer(lib, result, release: true);
      final stepCount = pedometerData.numberOfSteps?.intValue ?? 0;
      final startHour =
          hourFormatter.stringFromDate_(pedometerData.startDate!).toString();

      // Append the new data to the list.
      setState(() {
        hourlySteps.add(PedometerResults(startHour, stepCount));
      });
    });
  }

  // var totalSteps = [].reduce((a.steps, b.steps) => a + b);

  @override
  void initState() {
    // Create a new CMPedometer instance.
    client = pd.CMPedometer.new1(lib);

    // Setting the formatter for date strings.
    formatter =
        pd.NSDateFormatter.castFrom(pd.NSDateFormatter.alloc(lib).init());
    formatter.dateFormat = pd.NSString(lib, "$formatString zzz");
    // formatter.locale = pd.NSLocale.alloc(lib)
    //     .initWithLocaleIdentifier_(pd.NSString(lib, "en_US"));

    hourFormatter =
        pd.NSDateFormatter.castFrom(pd.NSDateFormatter.alloc(lib).init());
    hourFormatter.dateFormat = pd.NSString(lib, "HH");

    recieveSteps();
    super.initState();
  }

  pd.NSDate dateConverter(DateTime dartDate) {
    // Format dart date to string.
    final formattedDate = DateFormat(formatString).format(dartDate);
    // Get current timezone.
    final tz = dartDate.timeZoneName;
    // Create a new NSString with the formatted date and timezone.
    final nString = pd.NSString(lib, "$formattedDate $tz");
    // Convert the NSString to NSDate.
    return formatter.dateFromString_(nString);
  }

  // Next try feeding in the pedometer too
  void runPedometer() async {
    // Convert start and end date.
    final start = dateConverter(DateTime.now().subtract(Duration(hours: 24)));
    final end = dateConverter(DateTime.now());

    if (nativePort != null) {
      setState(() {
        lastUpdated = DateTime.now();
        hourlySteps = [];
      });
      // For loop for every hour in the past 24 hours.
      for (var i = 0; i < 24; i++) {
        final _start = dateConverter(DateTime.now()
            .subtract(Duration(hours: 24 - i))
            .subtract(Duration(
                hours: 1))); // Subtract 1 hour to get the start of the hour
        final _end = dateConverter(DateTime.now()
            .subtract(Duration(hours: 24 - i))); // End of the hour
        // Start the pedometer with the start and end date.
        pd.PedometerHelper.startPedometerWithPort_pedometer_start_end_(
            lib2, nativePort, client, _start, _end);
      }
    }
  }

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
                        hourlySteps.fold(0, (t, e) => t + e.steps).toString(),
                        style: textTheme.displayMedium!
                            .copyWith(color: Colors.white),
                      ),
                      Text(
                        'steps',
                        style:
                            textTheme.titleSmall!.copyWith(color: Colors.white),
                      ),
                      // If there are less than 24 hours then show a spinner.
                      if (hourlySteps.length < 24)
                        const CircularProgressIndicator()
                      else
                        // Else show the hourly steps.
                        ListView(
                          shrinkWrap: true,
                          children: hourlySteps
                              .map((e) => Text(
                                    e.startHour.toString() +
                                        ": " +
                                        e.steps.toString(),
                                    style: textTheme.titleSmall!
                                        .copyWith(color: Colors.white),
                                  ))
                              .toList(),
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
