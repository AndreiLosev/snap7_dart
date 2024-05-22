import 'dart:ffi';
import 'dart:io';
import 'dart:math';

part 'native_snap7.dart';

class LoadLib {
  static LoadLib? _i;

  late final NativeSnap7 _lib;

  LoadLib._([String? path]) {
    if (path is String) {
      _lib = NativeSnap7(DynamicLibrary.open(path)); 
    } else {
      _lib = NativeSnap7(_loadLib());
    }
  }

  factory LoadLib.getI([String? path]) {
    if (_i != null) {
      return _i!;
    }

    _i = LoadLib._(path);

    return _i!;
  }

  NativeSnap7 get lib => _lib;

  static DynamicLibrary _loadLib() {
    if (Platform.isAndroid) {
      try {
        return DynamicLibrary.open('libsnap7.so');
      } on ArgumentError {
        final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();
        final endOfAppId = max(appIdAsBytes.indexOf(0), 0);
        final appId = String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId));

        return DynamicLibrary.open('/data/data/$appId/lib/libsnap7.so');
      }
    } else if (Platform.isLinux) {
      final self = DynamicLibrary.executable();
      if (self.providesSymbol(
          'sqlite3_flutter_libs_plugin_register_with_registrar')) {
        return self;
      }

      return DynamicLibrary.open('libsnap7.so');
    } else if (Platform.isIOS) {
      try {
        return DynamicLibrary.open('libsnap7.dylib');
      } on ArgumentError catch (_) {
        return DynamicLibrary.process();
      }
    } else if (Platform.isMacOS) {
      DynamicLibrary result;

      result = DynamicLibrary.process();

      if (!result.providesSymbol('sqlite3_version')) {
        result = DynamicLibrary.open('/usr/lib/libsnap7.dylib');
      }
      return result;
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('libsnap7.dll');
    }

    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}
