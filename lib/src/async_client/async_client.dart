import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_snap7/src/async_client/frame.dart';
import 'package:dart_snap7/src/async_client/methods.dart';
import 'package:dart_snap7/src/client.dart';
import 'package:dart_snap7/src/multi_request.dart';
import 'package:dart_snap7/src/s7_types.dart';

class AsyncClient {
  final _receiver = ReceivePort();
  late final SendPort _sender;
  late final Isolate _isolate;

  int _messageId = 0;

  late final StreamSubscription _subscriber;
  final _results = <int, Completer<Frame>>{};

  Future<void> init([String? path]) async {
    _isolate = await Isolate.spawn(_isolateMain, _receiver.sendPort);
    _isolate.setErrorsFatal(true);
    _isolate.addErrorListener(_receiver.sendPort);

    final senderCompliter = Completer();

    _subscriber = _receiver.listen((message) {
      if (message is SendPort) {
        senderCompliter.complete(message);
        _subscriber.onData(_handler);
      }
    });

    _sender = await senderCompliter.future;
    await _methodHandler(CreateClient((path,)));
  }

  Future<void> destroy() async {
    await _methodHandler(Destroy());
    _isolate.kill();
    _subscriber.cancel();
  }

  Future<void> connect(String ip, int rack, int slot, [int port = 102]) async {
    await _methodHandler(Connect((ip, rack, slot, port)));
  }

  Future<void> setConnectionType(int value) async {
    await _methodHandler(SetConnectionType((value,)));
  }

  Future<bool> isConnected() async {
    final m = await _methodHandler(IsConnected());
    return m.result;
  }

  Future<void> setParam(S7Param param, int value) async {
    await _methodHandler(SetParam((param, value)));
  }

  Future<int> getParam(S7Param param) async {
    final m = await _methodHandler(GetParam((param,)));
    return m.result;
  }

  Future<void> disconnect() async {
    await _methodHandler(Disconnect());
  }

  Future<Uint8List> readDataBlock(int dbNum, int start, int size) async {
    final m = await _methodHandler(ReadDataBlock((dbNum, start, size)));
    return m.result;
  }

  Future<void> writeDataBlock(int dbNum, int start, Uint8List data) async {
    await _methodHandler(WriteDataBlock((dbNum, start, data)));
  }

  Future<Uint8List> readInputs(int start, int size) async {
    final m = await _methodHandler(ReadInputs((start, size)));
    return m.result;
  }

  Future<void> writeInputs(int start, Uint8List data) async {
    await _methodHandler(WriteInputs((start, data)));
  }

  Future<Uint8List> readOutputs(int start, int size) async {
    final m = await _methodHandler(ReadOutputs((start, size)));
    return m.result;
  }

  Future<void> writeOutputs(int start, Uint8List data) async {
    await _methodHandler(WriteOutputs((start, data)));
  }

  Future<Uint8List> readMerkers(int start, int size) async {
    final m = await _methodHandler(ReadMerkers((start, size)));
    return m.result;
  }

  Future<void> writeMerkers(int start, Uint8List data) async {
    await _methodHandler(WriteMerkers((start, data)));
  }

  Future<Uint8List> readTimers(int start, int size) async {
    final m = await _methodHandler(ReadTimers((start, size)));
    return m.result;
  }

  Future<void> writeTimers(int start, Uint8List data) async {
    await _methodHandler(WriteTimers((start, data)));
  }

  Future<Uint8List> readCounters(int start, int size) async {
    final m = await _methodHandler(ReadCounters((start, size)));
    return m.result;
  }

  Future<void> writeMerkersBit(int byte, int bit, bool value) async {
    await _methodHandler(WriteMerkersbit((byte, bit, value)));
  }

  Future<void> writeOutputsBit(int byte, int bit, bool value) async {
    await _methodHandler(WriteOutputsBit((byte, bit, value)));
  }

  Future<void> writeDataBlockBit(int dbNamber, int byte, int bit, bool value) async {
    await _methodHandler(WriteDataBlockBit((dbNamber, byte, bit, value)));
  }

  Future<void> writeCounters(int start, Uint8List data) async {
    await _methodHandler(WriteCounters((start, data)));
  }

  Future<List<(S7Error?, Uint8List)>> readMultiVars(
      MultiReadRequest request) async {
    final m = await _methodHandler(ReadMultiVars((request,)));
    return m.result;
  }

  Future<List<S7Error?>> writeMultiVars(MultiWriteRequest request) async {
    final m = await _methodHandler(WriteMultiVars((request,)));
    return m.result;
  }

  Future<T> _methodHandler<T extends Method>(T method) async {
    final id = _getId();
    _results[id] = Completer();
    var frame = Frame(id, method);
    _sender.send(frame);

    frame = await _results[id]!.future;

    if (frame.err != null) {
      throw frame.err!;
    }

    return frame.method as T;
  }

  void _handler(frame) {
    if (frame is! Frame) {
      return;
    }

    if (_results[frame.id] == null) {
      throw StateError("frame.id is null");
    }

    _results[frame.id]!.complete(frame);
  }

  int _getId() {
    _messageId = switch (_messageId >= 0x7FFFFFFFFFFFFFFF) {
      true => 0,
      false => _messageId + 1,
    };

    return _messageId;
  }

  static void _isolateMain(SendPort sender) async {
    final receiver = ReceivePort();
    sender.send(receiver.sendPort);
    late final Client client;

    await for (var frame in receiver) {
      if (frame is! Frame) {
        throw StateError("message mast be Frame");
      }
      try {
        final method = frame.method;
        switch (method) {
          case CreateClient():
            client = Client(method.params.$1);
          case Connect():
            final (ip, rack, slot, port) = method.params;
            client.connect(ip, rack, slot, port);
          case SetConnectionType():
            client.setConnectionType(method.params.$1);
          case IsConnected():
            method.result = client.isConnected();
          case SetParam():
            client.setParam(method.params.$1, method.params.$2);
          case GetParam():
            method.result = client.getParam(method.params.$1);
          case Disconnect():
            client.disconnect();
          case ReadDataBlock():
            final (dbNum, start, size) = method.params;
            method.result = client.readDataBlock(dbNum, start, size);
          case WriteDataBlock():
            final (dbNum, start, buf) = method.params;
            client.writeDataBlock(dbNum, start, buf);
          case ReadInputs():
            final (start, size) = method.params;
            method.result = client.readInputs(start, size);
          case WriteInputs():
            client.writeInputs(method.params.$1, method.params.$2);
          case ReadOutputs():
            final (start, size) = method.params;
            method.result = client.readOutputs(start, size);
          case WriteOutputs():
            client.writeOutputs(method.params.$1, method.params.$2);
          case ReadMerkers():
            final (start, size) = method.params;
            method.result = client.readMerkers(start, size);
          case WriteMerkers():
            client.writeMerkers(method.params.$1, method.params.$2);
          case ReadTimers():
            final (start, size) = method.params;
            method.result = client.readTimers(start, size);
          case WriteTimers():
            client.writeTimers(method.params.$1, method.params.$2);
          case ReadCounters():
            final (start, size) = method.params;
            method.result = client.readCounters(start, size);
          case WriteCounters():
            client.writeCounters(method.params.$1, method.params.$2);
          case WriteMerkersbit():
            final (byte, bit, value) = method.params;
            client.writeMerkersBit(byte, bit, value);
          case WriteDataBlockBit():
            final (dbNamber, byte, bit, value) = method.params;
            client.writeDataBlockBit(dbNamber, byte, bit, value);
          case WriteOutputsBit():
            final (byte, bit, value) = method.params;
            client.writeOutputsBit(byte, bit, value);
          case ReadMultiVars():
            method.result = client.readMultiVars(method.params.$1);
          case WriteMultiVars():
            method.result = client.writeMultiVars(method.params.$1);
          case Destroy():
            client.destroy();
        }

        sender.send(frame);
      } catch (e) {
        frame.err = e;
        sender.send(frame);
      }
    }
  }
}
