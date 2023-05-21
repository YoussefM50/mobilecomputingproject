import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<double>? _userAccelerometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';
  var temp = "0";
  var temp2 = "0";
  int time = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 30), (timer) {
      setState(() {
        temp2 = '$_steps';
      });
    });
    Timer.periodic(Duration(seconds: 30), (timer) {
      time += 30;
      print('time increased to $time');
    });
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          setState(() {
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      print(event.steps);
      if (temp == "0") {
        temp = event.steps.toString();
      }
      _steps = (double.parse(event.steps.toString()) - double.parse(temp))
          .toString();

      print(temp);
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  // ignore: non_constant_identifier_names
  String StatusValue(userAccelerometer) {
    double ass = userAccelerometer == null
        ? 0
        : sqrt(pow(double.parse(userAccelerometer[0]), 2) +
            pow(double.parse(userAccelerometer[1]), 2) +
            pow(double.parse(userAccelerometer[2]), 2));

    sleep(const Duration(milliseconds: 200));
    if (ass > 2.5) {
      if (ass > 6) {
        return "Running";
      } else {
        return "Walking";
      }
    } else {
      return "Stop";
    }
  }

  Future<void> initPlatformState() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      _pedestrianStatusStream
          .listen(onPedestrianStatusChanged)
          .onError(onPedestrianStatusError);

      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
    } else {}
    if (!mounted) return;
  }

  Widget build(BuildContext context) {
    final userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Activity"),
          backgroundColor: Colors.red,
        ),
        body: Center(
            child: ListView(
          children: [
            CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 10.0,
              percent: _steps != "?"
                  ? double.parse(temp2) < 100
                      ? double.parse(temp2) / 100
                      : 1
                  : 0,
              backgroundColor: Colors.grey,
              progressColor: Colors.red,
              header: const Text(
                "Steps",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              center: const Icon(
                Icons.directions_walk_outlined,
                size: 50,
              ),
              footer: Text(
                "Total Steps in $time secends : $temp2",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
                child: Text(
              "Status",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            )),
            Icon(
              StatusValue(userAccelerometer) == "Running"
                  ? Icons.directions_run
                  : StatusValue(userAccelerometer) == "Walking"
                      ? Icons.directions_walk
                      : StatusValue(userAccelerometer) == "Stop"
                          ? Icons.accessibility_outlined
                          : Icons.error,
              size: 100,
            ),
            Center(
              child: Text(
                StatusValue(userAccelerometer),
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            TextButton(
                onPressed: () {
                  setState(() {
                    _steps = "0";
                    temp = "0";
                    temp2 = "0";
                    time = 0;
                  });
                },
                child: const Text(
                  "Reset",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ))
          ],
        )),
      ),
    );
  }
}
