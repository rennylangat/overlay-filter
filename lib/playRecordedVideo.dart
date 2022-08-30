import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart' as PackagageVideoPlayer;

class PlayRecordedVideo extends StatefulWidget {
  final String path;
  PlayRecordedVideo({required this.path});
  @override
  _PlayRecordedVideoState createState() => _PlayRecordedVideoState();
}

class _PlayRecordedVideoState extends State<PlayRecordedVideo> {
  late FlutterFFmpeg fFmpeg;
  late PackagageVideoPlayer.VideoPlayerController _controller;
  bool grey = true;
  File? fileInfo;
  final spinkit = SpinKitChasingDots(
    color: Colors.white,
    size: 50.0,
  );
  void getVideo() async {
    fileInfo = File(widget.path);
    _controller = PackagageVideoPlayer.VideoPlayerController.file(fileInfo!)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _controller.setLooping(true);
        });
      });
  }

  @override
  void initState() {
    super.initState();
    getVideo();
    fFmpeg = new FlutterFFmpeg();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      child: _controller == null
          ? spinkit
          : _controller.value.isInitialized
              ? GestureDetector(
                  onTap: () {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  },
                  child: Container(
                    width: _controller.value.size.aspectRatio,
                    height: _controller.value.size.aspectRatio,
                    child: Stack(
                      children: [
                        PackagageVideoPlayer.VideoPlayer(
                          _controller,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: OutlinedButton(
                              onPressed: () async {
                                final Directory extDir =
                                    await getApplicationDocumentsDirectory();
                                final String dirPath =
                                    '${extDir.path}/Oyindori/Filtered';
                                await Directory(dirPath)
                                    .create(recursive: true);
                                final String filePath =
                                    '$dirPath/${DateTime.now().millisecondsSinceEpoch.toString()}';
                                await fFmpeg
                                    .execute('-i ' +
                                        widget.path +
                                        ' -vf hue=s=0 ' +
                                        filePath +
                                        '-output.mp4')
                                    .then((value) {
                                  log(value.toString());
                                  log("Video Filtered Location: " +
                                      filePath +
                                      "-output.mp4");
                                });

                                // await fFmpeg
                                //     .execute('-i ' +
                                //         widget.path +
                                //         ' -i /data/user/0/com.example.video_filter/cache/REC6840151975487480678.mp4 -filter_complex "[0:0][1:0]overlay[out]" -shortest -map [out] -map 0:1 -pix_fmt yuv420p -c:a copy -c:v libx264 -crf 18 ' +
                                //         filePath +
                                //         '-output.mp4')
                                //     .then((value) {
                                //   log(value.toString());
                                //   log("Video Filtered Location: " +
                                //       filePath +
                                //       "-output.mp4");
                                // });
                                bool fileExists =
                                    File(filePath + "-output.mp4").existsSync();
                                if (fileExists) {
                                  _controller = PackagageVideoPlayer
                                          .VideoPlayerController
                                      .file(File(filePath + '-output.mp4'))
                                    ..initialize().then((_) {
                                      setState(() {
                                        _controller.play();
                                        _controller.setLooping(true);
                                        grey = !grey;
                                      });
                                    });
                                } else {
                                  log("Filter has not been applied");
                                }
                                // log("Grey Scale added");
                                // }
                              },
                              child: Text(
                                "Apply Gray Scale Filter",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: OutlinedButton(
                              onPressed: () async {
                                final Directory extDir =
                                    await getApplicationDocumentsDirectory();
                                final String dirPath =
                                    '${extDir.path}/Oyindori/Filtered';
                                await Directory(dirPath)
                                    .create(recursive: true);
                                final String filePath =
                                    '$dirPath/${DateTime.now().millisecondsSinceEpoch.toString()}';

                                await fFmpeg
                                    .execute(
                                        '-i /data/user/0/com.example.video_filter/cache/REC7385720016327570251.mp4 -i ' +
                                            widget.path +
                                            ' -filter_complex \"[1:v]scale=iw/2:-1[cam];[0:v][cam]overlay=main_w-overlay_w-5:main_h-overlay_h-5;[0:a][1:a]amix\" ' +
                                            filePath +
                                            '-output.mp4')
                                    .then((value) {
                                  log(value.toString());
                                  log("Video Filtered Location: " +
                                      filePath +
                                      "-output.mp4");
                                });
                                // await fFmpeg
                                //     .execute('-i ' +
                                //         widget.path +
                                //         ' -i /data/user/0/com.example.video_filter/cache/REC6840151975487480678.mp4 -filter_complex "[0:0][1:0]overlay[out]" -shortest -map [out] -map 0:1 -pix_fmt yuv420p -c:a copy -c:v libx264 -crf 18 ' +
                                //         filePath +
                                //         '-output.mp4')
                                //     .then((value) {
                                //   log(value.toString());
                                //   log("Video Filtered Location: " +
                                //       filePath +
                                //       "-output.mp4");
                                // });
                                bool fileExists =
                                    File(filePath + "-output.mp4").existsSync();
                                if (fileExists) {
                                  _controller = PackagageVideoPlayer
                                          .VideoPlayerController
                                      .file(File(filePath + '-output.mp4'))
                                    ..initialize().then((_) {
                                      setState(() {
                                        _controller.play();
                                        _controller.setLooping(true);
                                        grey = !grey;
                                      });
                                    });
                                } else {
                                  log("Filter has not been applied");
                                }
                              },
                              child: Text(
                                "Apply Overlay Filter",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : spinkit,
    );
  }
}
