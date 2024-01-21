import 'dart:typed_data';

import 'package:dart_snap7/src/multi_request.dart';
import 'package:dart_snap7/src/s7_types.dart';

sealed class Method {

  Object? get params;
  Object? get result => null;

  Method(); 
}

class CreateClient extends Method {

  @override
  final (String?,) params;

  CreateClient(this.params);
}

class Connect extends Method {

  @override
  final (String ip, int, int, int) params;

  Connect(this.params);
}

class SetConnectionType extends Method {

  @override
  final (int,) params;

  SetConnectionType(this.params);
}

class IsConnected extends Method {

  @override
  final Null params = null;
  
  @override
  late final bool result;

  IsConnected();
}

class SetParam extends Method {

  @override
  final (S7Param, int) params;

   SetParam(this.params);
}

class GetParam extends Method {

  @override
  final (S7Param,) params;

  @override
  late final int result;

  GetParam(this.params);
}

class Disconnect extends Method {

  @override
  final Null params = null;

  Disconnect();
}

class ReadDataBlock extends Method {

  @override
  final (int, int, int) params;

  @override
  late final Uint8List result;

  ReadDataBlock(this.params);
}

class WriteDataBlock extends Method {

  @override
  final (int, int, Uint8List) params;

  WriteDataBlock(this.params);
}

class ReadInputs extends Method {

  @override
  final (int, int) params;

  @override
  late final Uint8List result;

  ReadInputs(this.params);
}

class WriteInputs extends Method {

  @override
  final (int, Uint8List) params;

  WriteInputs(this.params);
}

class ReadOutputs extends Method {

  @override
  final (int, int) params;

  @override
  late final Uint8List result;

  ReadOutputs(this.params);
}

class WriteOutputs extends Method {
  
  @override
  final (int, Uint8List) params;

  @override
  late final Uint8List result;

  WriteOutputs(this.params);
}

class ReadMerkers extends Method {

  @override
  final (int, int) params;

  @override
  late final Uint8List result;

  ReadMerkers(this.params);
}

class WriteMerkers extends Method {

  @override
  final (int, Uint8List) params;

  WriteMerkers(this.params);
}

class ReadTimers extends Method {

  @override
  final (int, int) params;

  @override
  late final Uint8List result;

  ReadTimers(this.params);
}

class WriteTimers extends Method {

  @override
  final (int, Uint8List) params;

  WriteTimers(this.params);
}

class ReadCounters extends Method {
  
  @override
  final (int, int) params;

  @override
  late final Uint8List result;

  ReadCounters(this.params);
}

class WriteCounters extends Method {

  @override
  final (int, Uint8List) params;

  WriteCounters(this.params);
}

class ReadMultiVars extends Method {

  @override
  final (MultiReadRequest,) params;

  @override
  late final List<(S7Error?, Uint8List)> result;

  ReadMultiVars(this.params);
}

class WriteMultiVars extends Method {

  @override
  final (MultiWriteRequest,) params;

  @override
  late final List<S7Error?> result;


  WriteMultiVars(this.params);
}
