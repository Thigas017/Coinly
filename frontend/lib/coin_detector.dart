import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

//C function signature (C/C++ side)
//int detect_coin(unsigned char* image_bytes, int width, int height, float* out_circle)
typedef DetectCoinCFunc = ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8> imageBytes,
    ffi.Int32 width,
    ffi.Int32 height,
    ffi.Pointer<ffi.Float> outCircle,
    );

//Dart function signature (Flutter side)
typedef DetectCoinDartFunc = int Function(
    ffi.Pointer<ffi.Uint8> imageBytes,
    int width,
    int height,
    ffi.Pointer<ffi.Float> outCircle,
    );

class CoinDetector {
  late DetectCoinDartFunc _detectCoin;

  CoinDetector() {
    //Load the native library depending on the platform
    final ffi.DynamicLibrary nativeLib;
    if (Platform.isAndroid) {
      nativeLib = ffi.DynamicLibrary.open('libcore_ai.so');
    } else if (Platform.isWindows) {
      nativeLib = ffi.DynamicLibrary.open('core_ai.dll');
    } else {
      throw UnsupportedError('Unsupported platform for Coinly AI');
    }

    //Bind the C++ function to the Dart function reference
    _detectCoin = nativeLib
        .lookup<ffi.NativeFunction<DetectCoinCFunc>>('detect_coin')
        .asFunction();
  }

  //Public method used by Flutter screens
  List<double>? processImage(
      ffi.Pointer<ffi.Uint8> imageBytes, int width, int height) {
    //Allocate memory for the output values (X, Y, Radius)
    final outCircle = calloc<ffi.Float>(3);

    try {
      //Invoke the native C++ function
      final result = _detectCoin(imageBytes, width, height, outCircle);

      if (result == 1) {
        //Return detected circle data [X, Y, Radius]
        return [outCircle[0], outCircle[1], outCircle[2]];
      }
      return null;
    } finally {
      //Free allocated memory to prevent leaks or crashes
      calloc.free(outCircle);
    }
  }
}