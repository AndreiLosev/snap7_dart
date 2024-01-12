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
