import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_filter/playRecordedVideo.dart';

class Video extends StatefulWidget {
  @override
  _VideoState createState() => _VideoState();
}

class _VideoState extends State<Video> {
  late CameraController controller;
  List<CameraDescription>? cameras;
  bool cameraInit = false;

  Future<void> initCamera() async {
    availableCameras().then((value) {
      cameras = value;
      controller = CameraController(cameras![1], ResolutionPreset.ultraHigh);
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          cameraInit = true;
        });
      });
    }).catchError((onError) {
      print(onError);
    });
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!cameraInit) {
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [CircularProgressIndicator()],
        ),
      );
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        children: [
          CameraPreview(controller),
          Positioned(
            bottom: 15,
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RecordButton(
                    controller: controller,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecordButton extends StatefulWidget {
  final CameraController controller;
  RecordButton({required this.controller});
  @override
  _RecordButtonState createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with TickerProviderStateMixin {
  double percentage = 0.0;
  double newPercentage = 0.0;
  double videoTime = 0.0;
  String? videoPath;
  Timer? timer;

  late AnimationController percentageAnimationController;
  bool _isRecordingInProgress = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      percentage = 0.0;
    });
    percentageAnimationController = new AnimationController(
        vsync: this, duration: new Duration(milliseconds: 1000))
      ..addListener(() {
        setState(() {
          percentage = lerpDouble(
              percentage, newPercentage, percentageAnimationController.value)!;
        });
      });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void onVideoRecordButtonPressed() async {
    await startVideoRecording();
  }

  Future<void> startVideoRecording() async {
    if (!widget.controller.value.isInitialized) {
      return null;
    }

    if (widget.controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await widget.controller.startVideoRecording();
      dev.log("Video is recording");
    } on CameraException catch (e) {
      dev.log("Camera error due to " + e.toString());
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (!widget.controller.value.isRecordingVideo) {
      dev.log("No recording in progress, nothing to stop.");
      return null;
    }

    try {
      XFile file = await widget.controller.stopVideoRecording();
      dev.log(file.path.toString());
      return file;
    } on CameraException catch (e) {
      dev.log("Recording issue due to " + e.toString());
    }
    dev.log("Function got here");

    return null;
  }

  playVideo(XFile? file) async {
    if (file != null) {
      File videoFile = File(file.path);
      dev.log("Raw video" + videoFile.path.toString());
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => PlayRecordedVideo(
            path: videoFile.path,
          ),
        ),
      );
    } else {
      dev.log("No video found");
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Container(
        height: 120.0,
        width: 120.0,
        child: new CustomPaint(
          foregroundPainter: new RecordButtonPainter(
              lineColor: Colors.black12,
              completeColor: Color(0xFFee5253),
              completePercent: percentage,
              width: 8.0),
          child: new Padding(
            padding: const EdgeInsets.all(15.0),
            child: GestureDetector(
              onLongPress: () async {
                await startVideoRecording();
                timer = new Timer.periodic(
                  Duration(milliseconds: 1),
                  (Timer t) => setState(() {
                    percentage = newPercentage;
                    newPercentage += 1;

                    percentageAnimationController.forward(from: 0.0);
                    // print((t.tick / 1000).toStringAsFixed(0));
                  }),
                );
                if (newPercentage > 9390.0) {
                  percentage = 0.0;
                  newPercentage = 0.0;
                  timer?.cancel();
                  XFile? file = await stopVideoRecording();
                  playVideo(file);
                }
              },
              onLongPressEnd: (e) async {
                percentage = 0.0;
                newPercentage = 0.0;
                timer?.cancel();
                await stopVideoRecording().then((value) {
                  playVideo(value);
                });
              },
              child: Container(
                child: Center(
                  child: new Text(
                    "Hold",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFee5253),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RecordButtonPainter extends CustomPainter {
  Color lineColor;
  Color completeColor;
  double completePercent;
  double width;
  RecordButtonPainter({
    required this.lineColor,
    required this.completeColor,
    required this.completePercent,
    required this.width,
  });
  @override
  void paint(Canvas canvas, Size size) {
    Paint line = new Paint()
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    Paint complete = new Paint()
      ..color = completeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    Offset center = new Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, line);
    double arcAngle = 2 * pi * (completePercent / 9390);
    canvas.drawArc(new Rect.fromCircle(center: center, radius: radius), -pi / 2,
        arcAngle, false, complete);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
