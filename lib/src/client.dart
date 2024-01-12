import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_snap7/src/s7_enums.dart';
import 'package:ffi/ffi.dart';

typedef S7Cli = Pointer<UintPtr>;

class Client {
  static final _finalizer = Finalizer((Client c) {
    print("<<<<<<<<<< destory >>>>>>>>>>>>>>>");
    c._destroy(c._pointer);
  });

  late final DynamicLibrary _lib;

  late final S7Cli _pointer;

  late final _createClient =
      _lib.lookupFunction<S7Cli Function(), S7Cli Function()>('Cli_Create');

  late final _setConnectionType = _lib.lookupFunction<
      Int Function(S7Cli, Uint16),
      int Function(S7Cli, int)>('Cli_SetConnectionType');

  late final _destroy = _lib
      .lookupFunction<Int Function(S7Cli), int Function(S7Cli)>('Cli_Destroy');

  late final _connectTo = _lib.lookupFunction<
      Int Function(S7Cli, Pointer<Char>, Int, Int),
      int Function(S7Cli, Pointer<Char>, int, int)>('Cli_ConnectTo');

  late final _disconnect =
      _lib.lookupFunction<Int Function(S7Cli), int Function(S7Cli)>(
          'Cli_Disconnect');

  late final _getParam = _lib.lookupFunction<
      Int Function(S7Cli, Int, Pointer<Void>),
      int Function(S7Cli, int, Pointer<Void>)>('Cli_GetParam');

  late final _setParam = _lib.lookupFunction<
      Int Function(S7Cli, Int, Pointer<Void>),
      int Function(S7Cli, int, Pointer<Void>)>('Cli_SetParam');

  late final _getConnected = _lib.lookupFunction<
      Int Function(S7Cli, Pointer<Int32>),
      int Function(S7Cli, Pointer<Int32>)>('Cli_GetConnected');

  late final _errorText = _lib.lookupFunction<
      Int Function(Int, Pointer<Char>, Int),
      int Function(int, Pointer<Char>, int)>('Cli_ErrorText');

  late final _readAreaNative = _lib.lookupFunction<
      Int Function(S7Cli, Int, Int, Int, Int, Int, Pointer<Void>),
      int Function(
          S7Cli, int, int, int, int, int, Pointer<Void>)>('Cli_ReadArea');

  late final _writeAreaNative = _lib.lookupFunction<
      Int Function(S7Cli, Int, Int, Int, Int, Int, Pointer<Void>),
      int Function(
          S7Cli, int, int, int, int, int, Pointer<Void>)>('Cli_WriteArea');

  Client([String? path]) {
    if (path is String) {
      _lib = DynamicLibrary.open(path);
    } else {
      late final String libName;

      if (Platform.isLinux || Platform.isAndroid) {
        libName = 'libsnap7.so';
      } else if (Platform.isMacOS) {
        libName = 'libsnap7.dylib';
      } else if (Platform.isWindows) {
        libName = 'libsnap7.dll';
      } else {
        throw "Platform not suported";
      }

      _lib = DynamicLibrary.open(libName);

      _pointer = _createClient();

      _finalizer.attach(this, this);
    }
  }

  void connect(String ip, int rack, int slot, [int port = 102]) {
    setParam(S7Param.socketRemotePort, port);
    final code = _connectTo(_pointer, ip.toNativeUtf8().cast(), rack, slot);
    _checkResult(code);
  }

  void setConnectionType(int type) {
    final code = _setConnectionType(_pointer, type);
    _checkResult(code);
  }

  bool isConnected() {
    late final bool result;

    using((arena) {
      final p = arena.allocate<Int32>(8);
      final code = _getConnected(_pointer, p);
      _checkResult(code);
      result = p.value != 0;
    });

    return result;
  }

  void setParam(S7Param paramType, int value) {
    using((arena) {
      final p = arena.allocate<Int64>(8);
      p.value = value;
      final code = _setParam(_pointer, paramType.value, p.cast());
      _checkResult(code);
    });
  }

  int getParam(S7Param paramType) {
    late final int result;

    using((arena) {
      final p = arena.allocate<Int64>(8);
      final code = _getParam(_pointer, paramType.value, p.cast());
      result = p.value;
      _checkResult(code);
    });

    return result;
  }

  void disconnect() {
    final code = _disconnect(_pointer);
    _checkResult(code);
  }

  Uint8List _readArea(S7Area area, int start, int amount, [int dbNumber = 0]) {
    final wordLen = switch (area) {
      S7Area.timers => WordLen.timer,
      S7Area.counters => WordLen.counter,
      _ => WordLen.byte,
    };

    final size = amount * wordLen.len;

    late final Uint8List result;

    using((arena) {
      final p = arena.allocate<Uint8>(size);

      final code = _readAreaNative(_pointer, area.value, dbNumber, start,
          amount, wordLen.code, p.cast());
      _checkResult(code);

      result = Uint8List.fromList(p.asTypedList(size).toList());
    }, malloc);

    return result;
  }

  void _writeArea(S7Area area, int start, Uint8List data, [int dbNumber = 0]) {
    final wordLen = switch (area) {
      S7Area.timers => WordLen.timer,
      S7Area.counters => WordLen.counter,
      _ => WordLen.byte,
    };

    using((arena) {
      final p = arena.allocate<Uint8>(data.length);
      for (var i = 0; i < data.length; i++) {
        p[i] = data[i];
      }
      final amaunt = data.length ~/ wordLen.len;
      final code = _writeAreaNative(_pointer, area.value, dbNumber, start,
          amaunt, wordLen.code, p.cast());
      _checkResult(code);
    }, malloc);
  }

  Uint8List readDataBlock(int dbNumber, int start, int size) {
    return _readArea(S7Area.dataBlock, start, size, dbNumber);
  }

  void writeDataBlock(int dbNumber, int start, Uint8List data) {
    _writeArea(S7Area.dataBlock, start, data, dbNumber);
  }

  Uint8List readInputs(int start, int size) {
    return _readArea(S7Area.inputs, start, size);
  }

  void writeInputs(int start, Uint8List data) {
    _writeArea(S7Area.inputs, start, data);
  }

  Uint8List readOutputs(int start, int size) {
    return _readArea(S7Area.outputs, start, size);
  }

  void writeOutputs(int start, Uint8List data) {
    _writeArea(S7Area.outputs, start, data);
  }

  Uint8List readMerkers(int start, int size) {
    return _readArea(S7Area.merkers, start, size);
  }

  void writeMerkers(int start, Uint8List data) {
    _writeArea(S7Area.merkers, start, data);
  }

  Uint8List readTimers(int start, int size) {
    return _readArea(S7Area.timers, start, size);
  }

  void writeTimers(int start, Uint8List data) {
    _writeArea(S7Area.timers, start, data);
  }

  Uint8List readCounters(int start, int size) {
    return _readArea(S7Area.counters, start, size);
  }

  void writeCounters(int start, Uint8List data) {
    _writeArea(S7Area.counters, start, data);
  }

  void _checkResult(int code) {
    if (code != 0) {
      late final String text;
      using((arena) {
        final p = arena.allocate<Char>(1024);
        _errorText(code, p, 1024);
        text = p.cast<Utf8>().toDartString(length: 1024);
      });

      throw S7Error(code, text);
    }
  }
}

class S7Error {
  final int _code;
  final String _message;

  S7Error(this._code, this._message);

  int get code => _code;

  String get message => _message;

  @override
  String toString() => "S7Error: $message";
}
