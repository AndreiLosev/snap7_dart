import 'dart:ffi' as ffi;

enum S7Param {
  socketRemotePort(2),
  clientPingTimeout(3),
  socketSendTimeout(4),
  socketRecvTimeout(5),
  isoTcpSourceReference(7),
  isoTcpDestinationReference(8),
  isoTcpSourceTSAP(9),
  initialPDULengthRequest(10);

  final int value;

  const S7Param(this.value);
}

enum S7Area {
  inputs(0x81),
  outputs(0x82),
  merkers(0x83),
  dataBlock(0x84),
  counters(0x1C),
  timers(0x1D);

  final int value;

  const S7Area(this.value);

  WordLen toWordLen() {
    return switch (this) {
      S7Area.timers => WordLen.timer,
      S7Area.counters => WordLen.counter,
      _ => WordLen.byte,
    };

}
}

enum WordLen {
  bit(0x01, 1),
  byte(0x02, 1),
  word(0x04, 2),
  dword(0x06, 4),
  real(0x08, 4),
  counter(0x1C, 2),
  timer(0x1D, 2);

  final int code;
  final int len;

  const WordLen(this.code, this.len);
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

class MultiReadItem {
  final S7Area area;
  final int dbNum;
  final int start;
  final int size;

  const MultiReadItem(this.area, this.dbNum, this.start, this.size);

  int getByteSize() => area.toWordLen().len * size;

  @override
  String toString() {
    return "area: $area, db: $dbNum, start: $start, size: $size";
  }
}
