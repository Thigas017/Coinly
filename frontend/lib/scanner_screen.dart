import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'coin_detector.dart';
import 'add_coin_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  //Instantiate native C++ detector
  final CoinDetector _detector = CoinDetector();

  //Flow control flags to prevent device overload
  bool _isProcessing = false;
  bool _coinDetected = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();

    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            ImageFormatGroup.yuv420, //Plane 0 provides grayscale data
      );

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });

          //Start real-time image stream (approx. 30 FPS)
          _controller!.startImageStream((CameraImage image) {
            _processCameraImage(image);
          });
        }
      } catch (e) {
        debugPrint("Camera initialization error: $e");
      }
    }
  }

  //Connect camera frames to native detector
  void _processCameraImage(CameraImage image) {
    //Skip frame if previous frame is still being processed
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      //Plane 0 (Y channel) already contains grayscale image data
      final imageBytes = image.planes[0].bytes;
      final width = image.width;
      final height = image.height;

      //Allocate shared memory between Dart and C++
      final pointer = calloc<ffi.Uint8>(imageBytes.length);

      //Copy camera bytes into allocated memory
      final externalTypedData = pointer.asTypedList(imageBytes.length);
      externalTypedData.setAll(0, imageBytes);

      //Invoke native C++ detection
      final result = _detector.processImage(pointer, width, height);

      //Free allocated memory to prevent crashes
      calloc.free(pointer);

      //Handle native detection result
      if (result != null) {
        final coinX = result[0];
        final coinY = result[1];
        final coinRadius = result[2];

        final isCenteredX = coinX > (width * 0.3) && coinX < (width * 0.7);
        final isCenteredY = coinY > (height * 0.3) && coinY < (height * 0.7);

        if (isCenteredX && isCenteredY) {
          debugPrint("Coin Centered! X:$coinX, Y:$coinY, R:$coinRadius");
          if (!_coinDetected && mounted) {
            setState(() {
              _coinDetected = true;
            });
          }
        } else {
          // Detected outside center
          if (_coinDetected && mounted) {
            setState(() {
              _coinDetected = false;
            });
          }
        }
      } else {
        if (_coinDetected && mounted) {
          setState(() {
            _coinDetected = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Image processing error: $e");
    } finally {
      //Allow next frame to be processed
      _isProcessing = false;
    }
  }

  //Smart capture function
  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture) {
      return;
    }

    try {
      //Stop image stream to prevent motion blur during capture
      await _controller!.stopImageStream();

      //Capture photo
      final XFile picture = await _controller!.takePicture();
      debugPrint("Photo captured: ${picture.path}");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddCoinScreen(imagePath: picture.path),
          ),
        );
      }
    } catch (e) {
      debugPrint("Photo capture error: $e");

      //Restart image stream if capture fails
      if (mounted) {
        _controller!.startImageStream((image) => _processCameraImage(image));
      }
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Scanner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: 1 / _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),

                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.5),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _coinDetected ? 280 : 250,
                    height: _coinDetected ? 280 : 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _coinDetected
                            ? Colors.amberAccent
                            : Colors.greenAccent,
                        width: _coinDetected ? 5 : 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                //Bottom control panel (status text + capture button)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      //Status text
                      Text(
                        _coinDetected
                            ? 'Coin centered!'
                            : 'Center the coin within the circle...',
                        style: TextStyle(
                          color: _coinDetected
                              ? Colors.amberAccent
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 10),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ), //Spacing between text and button
                      //Adaptive capture button
                      AnimatedOpacity(
                        opacity: _coinDetected ? 1.0 : 0.4,
                        //Reduced opacity when disabled
                        duration: const Duration(milliseconds: 300),
                        child: FloatingActionButton.large(
                          //Enabled only when a coin is detected
                          onPressed: _coinDetected ? _takePicture : null,
                          backgroundColor: _coinDetected
                              ? Colors.amberAccent
                              : Colors.grey.shade800,
                          elevation: _coinDetected ? 8 : 0,
                          child: Icon(
                            Icons.camera_alt,
                            color: _coinDetected
                                ? Colors.black
                                : Colors.white54,
                            size: 38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            ),
    );
  }
}
