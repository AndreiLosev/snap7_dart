* wrapper for C library snap7 https://snap7.sourceforge.net/
* pub dev: https://pub.dev/packages/snap7_dart
<?code-excerpt "readme_excerpts.dart (Write)"?>
```dart
import 'dart:typed_data';
import 'package:dart_snap7/dart_snap7.dart';

void main(List<String> args) async {
  final aC = AsyncClient();
  await aC.init();
  await aC.connect('192.168.100.55', 0, 0);
  final data = await aC.readMultiVars(
    MultiReadRequest()
      ..readDataBlock(2, 0, 2)
      ..readMerkers(22, 25)
  );

  final bytes = ByteData.view(data[1].$2.buffer);
  
  final byte = bytes.getUint8(46 - 22);

  print(['datablock 2', data[0].$2]);

  print([':', [
    bytes.getUint8(0),
    bytes.getUint16(2),
    bytes.getUint32(4),
    bytes.getInt16(8),
    bytes.getFloat64(32 - 22),
    bytes.getFloat32(40 - 22),
    bytes.getUint16(44 - 22),
    bytes.getUint8(46 - 22)
  ]]);

  print(['bits:', [
    byte.getBit(0),
    byte.getBit(1),
    byte.getBit(2),
    byte.getBit(3),
    byte.getBit(4),
    byte.getBit(5),
    byte.getBit(6),
    byte.getBit(7),
  ]]);

  await aC.disconnect();
  await aC.destroy();
}

extension BitMap on int {
  bool getBit(int pos) {
    final x = this >> pos;
    return x & 1 == 1;
  }

  int setBit(int pos, bool bit) {
    final x = 1 << pos;
    if (bit) {
      return this | x;
    }

    return getBit(pos) ? this ^ x : this;
  }
}
```
