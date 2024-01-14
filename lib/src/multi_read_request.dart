import 'dart:ffi';
import 'dart:typed_data';

import 'package:dart_snap7/src/load_lib.dart';
import 'package:dart_snap7/src/s7_types.dart';
import 'package:ffi/ffi.dart';

class MultiReadRequest {
  static const _maxSize = 450;

  final _items = <MultiReadItem>[];

  void readDataBlock(int dbNumber, int start, int size) {
    final chunks = _split(S7Area.dataBlock, size);
    for (var i = 0; i < chunks.length; i++) {
      _items.add(MultiReadItem(
          S7Area.dataBlock, dbNumber, _nextStart(S7Area.dataBlock, start, i), chunks[i]));
    }
  }

  void readInputs(int start, int size) {
    final chunks = _split(S7Area.inputs, size);
    for (var i = 0; i < chunks.length; i++) {
      _items.add(
          MultiReadItem(S7Area.inputs, 0, _nextStart(S7Area.inputs, start, i), chunks[i]));
    }
  }

  void readOutputs(int start, int size) {
    final chunks = _split(S7Area.outputs, size);
    for (var i = 0; i < chunks.length; i++) {
      _items.add(
          MultiReadItem(S7Area.outputs, 0, _nextStart(S7Area.outputs, start, i), chunks[i]));
    }
  }

  void readMerkers(int start, int size) {
    final chunks = _split(S7Area.merkers, size);
    for (var i = 0; i < chunks.length; i++) {
      _items.add(
          MultiReadItem(S7Area.merkers, 0, _nextStart(S7Area.merkers, start, i), chunks[i]));
    }
  }

  void readTimers(int start, int size) {
    final chunks = _split(S7Area.timers, size);
    for (var i = 0; i < chunks.length; i++) {
      _items.add(
          MultiReadItem(S7Area.timers, 0, _nextStart(S7Area.timers, start, i), chunks[i]));
    }
  }

  void readCounters(int start, int size) {
    final chunks = _split(S7Area.counters, size);
    for (var i = 0; i < chunks.length; i++) {
      _items.add(
          MultiReadItem(S7Area.counters, 0, _nextStart(S7Area.counters, start, i), chunks[i]));
    }
  }

  List<List<MultiReadItem>> execute() {
    final oneRequest = <MultiReadItem>[];
    int requestSize = 0;
    final result = <List<MultiReadItem>>[];


    for (var i in _items) {
      if ((requestSize + i.getByteSize()) < _maxSize) {
        requestSize += i.getByteSize();
        oneRequest.add(i);
      } else {
        result.add(oneRequest);
        oneRequest.removeRange(0, oneRequest.length);
        requestSize = 0;
      }
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
