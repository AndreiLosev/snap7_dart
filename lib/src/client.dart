import 'dart:ffi';
import 'dart:typed_data';

import 'package:dart_snap7/src/load_lib.dart';
import 'package:dart_snap7/src/multi_read_request.dart';
import 'package:dart_snap7/src/s7_types.dart';
import 'package:ffi/ffi.dart';

typedef S7Cli = Pointer<UintPtr>;

class Client {
  late final NativeSnap7 _lib;

  late final S7Cli _pointer;

  Client([String? path]) {
    final loader = LoadLib.getI(path);
    _lib = loader.lib;
    _pointer = _lib.createClient();
  }

  void connect(String ip, int rack, int slot, [int port = 102]) {
    setParam(S7Param.socketRemotePort, port);
    final code = _lib.connectTo(_pointer, ip.toNativeUtf8().cast(), rack, slot);
    _checkResult(code);
  }

  void setConnectionType(int type) {
    final code = _lib.setConnectionType(_pointer, type);
    _checkResult(code);
  }

  bool isConnected() {
    late final bool result;

    using((arena) {
      final p = arena.allocate<Int32>(8);
      final code = _lib.getConnected(_pointer, p);
      _checkResult(code);
      result = p.value != 0;
    });

    return result;
  }

  void setParam(S7Param paramType, int value) {
    using((arena) {
      final p = arena.allocate<Int64>(8);
      p.value = value;
      final code = _lib.setParam(_pointer, paramType.value, p.cast());
      _checkResult(code);
    });
  }

  int getParam(S7Param paramType) {
    late final int result;

    using((arena) {
      final p = arena.allocate<Int64>(8);
      final code = _lib.getParam(_pointer, paramType.value, p.cast());
      result = p.value;
      _checkResult(code);
    });

    return result;
  }

  void disconnect() {
    final code = _lib.disconnect(_pointer);
    _checkResult(code);
  }

  Uint8List _readArea(S7Area area, int start, int amount, [int dbNumber = 0]) {
    final wordLen = area.toWordLen();
    final size = amount * wordLen.len;
    final result = Uint8List(size);

    using((arena) {
      final p = arena.allocate<Uint8>(size);
      final code = _lib.readAreaNative(_pointer, area.value, dbNumber, start,
          amount, wordLen.code, p.cast());
      _checkResult(code);

      for (var i = 0; i < size; i++) {
        result[i] = p[i];
      }
    }, malloc);

    return result;
  }

  void _writeArea(S7Area area, int start, Uint8List data, [int dbNumber = 0]) {
    final wordLen = area.toWordLen();

    using((arena) {
      final p = arena.allocate<Uint8>(data.length);
      for (var i = 0; i < data.length; i++) {
        p[i] = data[i];
      }
      final amaunt = data.length ~/ wordLen.len;
      final code = _lib.writeAreaNative(_pointer, area.value, dbNumber, start,
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

  void readMultiVarsTest(Pointer<PS7DataItem> s, int len) {
    final x = _lib.readMultiVars(_pointer, s, len);
    _checkResult(x);
    _checkResult(s.ref.Result);
  }

  void destroy() {
    using((arena) {
      final p = arena.allocate<S7Cli>(8);
      p.value = _pointer;
      _lib.destroy(p);
    });
  }

  List<(S7Error?, Uint8List)> readMultiVars(MultiReadRequest request) {
    final result = <(S7Error?, Uint8List)>[];

    for (var items in request.execute()) {
        result.addAll(_readMultiVarsExecut(items));
    }

    return result;
  }

  List<(S7Error?, Uint8List)> _readMultiVarsExecut(List<MultiReadItem> items) {
    final result = <(S7Error?, Uint8List)>[];

    using((arena) {
      final nativeItems =
          arena.allocate<PS7DataItem>(sizeOf<PS7DataItem>() * items.length);
      for (var i = 0; i < items.length; i++) {
        nativeItems[i].Area = items[i].area.value;
        nativeItems[i].WordLen = items[i].area.toWordLen().code;
        nativeItems[i].DBNumber = items[i].dbNum;
        nativeItems[i].Start = items[i].start;
        nativeItems[i].Amount = items[i].size;
        nativeItems[i].Result = 0;
        nativeItems[i].pData =
            arena.allocate(items[i].size * items[i].area.toWordLen().len);
      }

      _lib.readMultiVars(_pointer, nativeItems, items.length);

      for (var i = 0; i < items.length; i++) {
        final len = items[i].size * items[i].area.toWordLen().len;
        final buf = Uint8List(len);
        final code = nativeItems[i].Result;
        final err = code == 0 ? null : S7Error(code, _createErrorText(code));
        for (var i = 0; i < len; i++) {
          buf[i] = nativeItems[i].pData[i];
        }

        result.add((err, buf));
      }
    });

    return result;
  }

  void _checkResult(int code) {
    if (code != 0) {
      final text = _createErrorText(code);
      throw S7Error(code, text);
    }
  }

  String _createErrorText(int code) {
    late final String text;
    using((arena) {
      final p = arena.allocate<Char>(1024);
      _lib.errorText(code, p, 1024);
      text = p.cast<Utf8>().toDartString(length: 1024);
    });

    return text;
  }
}
