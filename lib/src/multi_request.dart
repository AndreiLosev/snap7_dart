import 'dart:typed_data';

import 'package:dart_snap7/src/s7_types.dart';

abstract class MultiRequest {
  final int _maxSize;
  final _items = <MultiItem>[];

  MultiRequest(this._maxSize);

  List<List<MultiItem>> execute() {
    var oneRequest = <MultiItem>[];
    int requestSize = 0;
    final result = <List<MultiItem>>[];

    for (var i in _items) {
      if ((requestSize + i.getByteSize()) <= _maxSize) {
        requestSize += i.getByteSize();
        oneRequest.add(i);
      } else {
        result.add(oneRequest);
        oneRequest = [];
        requestSize = 0;
        oneRequest.add(i);
        requestSize += i.getByteSize();
      }
    }

    if (oneRequest.isNotEmpty) {
      result.add(oneRequest);
    }

    return result;
  }

  List<int> _split(S7Area area, int size) {
    int bytesSize = area.toWordLen().len * size;

    if (size <= _maxSize) {
      return [size];
    }

    final result = <int>[];

    while (bytesSize > _maxSize) {
      bytesSize -= _maxSize;
      result.add(_maxSize ~/ area.toWordLen().len);
    }

    if (bytesSize > 0) {
      result.add(bytesSize ~/ area.toWordLen().len);
    }

    return result;
  }

  int _nextStart(S7Area area, int start, int index) {
    return start + index * _maxSize ~/ area.toWordLen().len;
  }
}

class MultiReadRequest extends MultiRequest {
  MultiReadRequest() : super(462);

  void readDataBlock(int dbNumber, int start, int size) {
    _createItems(S7Area.dataBlock, dbNumber, start, size);
  }

  void readInputs(int start, int size) {
    _createItems(S7Area.inputs, 0, start, size);
  }

  void readOutputs(int start, int size) {
    _createItems(S7Area.outputs, 0, start, size);
  }

  void readMerkers(int start, int size) {
    _createItems(S7Area.merkers, 0, start, size);
  }

  void readTimers(int start, int size) {
    _createItems(S7Area.timers, 0, start, size);
  }

  void readCounters(int start, int size) {
    _createItems(S7Area.counters, 0, start, size);
  }

  void _createItems(S7Area area, int dbNum, int start, int size) {
    final chunks = _split(area, size);
    for (var i = 0; i < chunks.length; i++) {
      _items.add(
          MultiReadItem(area, dbNum, _nextStart(area, start, i), chunks[i]));
    }
  }
}

class MultiWriteRequest extends MultiRequest {
  MultiWriteRequest() : super(452);

  void writeDataBlock(int dbNumber, int start, Uint8List buf) {
    _createItems(S7Area.dataBlock, dbNumber, start, buf);
  }

  void writeInputs(int start, Uint8List buf) {
    _createItems(S7Area.inputs, 0, start, buf);
  }

  void writeOutputs(int start, Uint8List buf) {
    _createItems(S7Area.outputs, 0, start, buf);
  }

  void writeMerkers(int start, Uint8List buf) {
    _createItems(S7Area.merkers, 0, start, buf);
  }

  void writeTimers(int start, Uint8List buf) {
    _createItems(S7Area.timers, 0, start, buf);
  }

  void writeCounters(int start, Uint8List buf) {
    _createItems(S7Area.counters, 0, start, buf);
  }

  void _createItems(S7Area area, int dbNum, int start, Uint8List buf) {
    final chunks = _split(area, buf.length);
    for (var i = 0; i < chunks.length; i++) {
      final nextStart = _nextStart(area, start, i);
      final newBuf = Uint8List.fromList(
          buf.getRange(nextStart - start, nextStart - start + chunks[i]).toList());
      _items
          .add(MultiWriteItem(area, dbNum, nextStart, newBuf));
    }
  }
}
