import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'package:pedometer/pedometer_bindings_generated.dart' as pd;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  DateTime? lastUpdated;
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
      if (data != null) {
        final result = ffi.Pointer<pd.ObjCObject>.fromAddress(data as int);
        final pedometerData =
            pd.CMPedometerData.castFromPointer(lib, result, release: true);
        final stepCount = pedometerData.numberOfSteps?.intValue ?? 0;
        final startHour =
            hourFormatter.stringFromDate_(pedometerData.startDate!).toString();

        print("$startHour: $stepCount");
        // Append the new data to the list.
        setState(() {
          hourlySteps.add(PedometerResults(startHour, stepCount));
        });
      }
    });
  }

  @override
  void initState() {
    // Create a new CMPedometer instance.
    client = pd.CMPedometer.new1(lib);

    // Setting the formatter for date strings.
    formatter =
        pd.NSDateFormatter.castFrom(pd.NSDateFormatter.alloc(lib).init());
    formatter.dateFormat = pd.NSString(lib, "$formatString zzz");
    hourFormatter =
        pd.NSDateFormatter.castFrom(pd.NSDateFormatter.alloc(lib).init());
    hourFormatter.dateFormat = pd.NSString(lib, "HH");

    recieveSteps();
    runPedometer();
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

  // Run the pedometer.
  void runPedometer() async {
    final now = DateTime.now();
    if (nativePort != null) {
      setState(() {
        lastUpdated = now;
        hourlySteps = [];
      });

      // Loop through every hour since midnight.
      for (var h = 0; h <= now.hour; h++) {
        final start = dateConverter(DateTime(now.year, now.month, now.day, h));
        final end =
            dateConverter(DateTime(now.year, now.month, now.day, h + 1));
        pd.PedometerHelper.startPedometerWithPort_pedometer_start_end_(
            lib2, nativePort, client, start, end);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    var barGroups = hourlySteps
        .map((e) => BarChartGroupData(x: int.parse(e.startHour), barRods: [
              BarChartRodData(
                  color: Colors.blue[900], toY: e.steps.toDouble() / 100)
            ]))
        .toList();

    return Scaffold(
        body: Stack(
      children: [
        ClipPath(
            clipper: RoundClipper(),
            child: FractionallySizedBox(
                heightFactor: 0.55,
                widthFactor: 1,
                child: Container(color: Colors.blue[300]))),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(80.0),
            child: Column(children: [
              lastUpdated != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50.0),
                      child: Text(
                          DateFormat.yMMMMd('en_US').format(lastUpdated!),
                          style: textTheme.titleLarge!
                              .copyWith(color: Colors.blue[900])),
                    )
                  : const SizedBox(height: 0),
              Text(
                hourlySteps.fold(0, (t, e) => t + e.steps).toString(),
                style: textTheme.displayMedium!.copyWith(color: Colors.white),
              ),
              Text(
                'steps',
                style: textTheme.titleLarge!.copyWith(color: Colors.white),
              )
            ]),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: runPedometer,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
            child: AspectRatio(
                aspectRatio: 1.2,
                child: Container(
                  child: BarChart(
                    BarChartData(
                      titlesData: FlTitlesData(
                          show: true,
                          // Top titles are null
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                            showTitles: false,
                          )),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: getBottomTitles,
                            ),
                          )),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: barGroups,
                      gridData: FlGridData(show: false),
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                    ),
                  ),
                )),
          ),
        ),
      ],
    ));
  }
}

// Axis labels for bottom of chart
Widget getBottomTitles(double value, TitleMeta meta) {
  String text;
  switch (value.toInt()) {
    case 0:
      text = '12AM';
      break;
    case 6:
      text = '6AM';
      break;
    case 12:
      text = '12PM';
      break;
    case 18:
      text = '6PM';
      break;
    default:
      text = '';
  }
  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 4,
    child: Text(text, style: TextStyle(fontSize: 14, color: Colors.blue[900])),
  );
}
