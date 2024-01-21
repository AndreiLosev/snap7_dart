import 'package:dart_snap7/src/async_client/methods.dart';

class Frame {
  final int id;
  Object? err;
  final Method method;

  Frame(this.id, this.method);
}
