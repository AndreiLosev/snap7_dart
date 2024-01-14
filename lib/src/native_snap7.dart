part of "load_lib.dart";

typedef S7Cli = Pointer<UintPtr>;

class NativeSnap7 {

  late final DynamicLibrary _lib;

  NativeSnap7(this._lib);

  late final createClient =
      _lib.lookupFunction<S7Cli Function(), S7Cli Function()>('Cli_Create');

  late final setConnectionType = _lib.lookupFunction<
      Int Function(S7Cli, Uint16),
      int Function(S7Cli, int)>('Cli_SetConnectionType');

  late final destroy = _lib.lookupFunction<Void Function(Pointer<S7Cli>),
      void Function(Pointer<S7Cli>)>('Cli_Destroy');

  late final connectTo = _lib.lookupFunction<
      Int Function(S7Cli, Pointer<Char>, Int, Int),
      int Function(S7Cli, Pointer<Char>, int, int)>('Cli_ConnectTo');

  late final disconnect =
      _lib.lookupFunction<Int Function(S7Cli), int Function(S7Cli)>(
          'Cli_Disconnect');

  late final getParam = _lib.lookupFunction<
      Int Function(S7Cli, Int, Pointer<Void>),
      int Function(S7Cli, int, Pointer<Void>)>('Cli_GetParam');

  late final setParam = _lib.lookupFunction<
      Int Function(S7Cli, Int, Pointer<Void>),
      int Function(S7Cli, int, Pointer<Void>)>('Cli_SetParam');

  late final getConnected = _lib.lookupFunction<
      Int Function(S7Cli, Pointer<Int32>),
      int Function(S7Cli, Pointer<Int32>)>('Cli_GetConnected');

  late final errorText = _lib.lookupFunction<
      Int Function(Int, Pointer<Char>, Int),
      int Function(int, Pointer<Char>, int)>('Cli_ErrorText');

  late final readAreaNative = _lib.lookupFunction<
      Int Function(S7Cli, Int, Int, Int, Int, Int, Pointer<Void>),
      int Function(
          S7Cli, int, int, int, int, int, Pointer<Void>)>('Cli_ReadArea');

  late final writeAreaNative = _lib.lookupFunction<
      Int Function(S7Cli, Int, Int, Int, Int, Int, Pointer<Void>),
      int Function(
          S7Cli, int, int, int, int, int, Pointer<Void>)>('Cli_WriteArea');

  late final readMultiVars = _lib.lookupFunction<
    Int Function(S7Cli, Pointer<PS7DataItem>, Int),
    int Function(S7Cli, Pointer<PS7DataItem>, int)
  >('Cli_ReadMultiVars');
}

final class PS7DataItem extends Struct {
  @Int32()
  external int Area;

  @Int32()
  external int WordLen;

  @Int32()
  external int Result;

  @Int32()
  external int DBNumber;

  @Int32()
  external int Start;

  @Int32()
  external int Amount;

  external Pointer<Uint8> pData;
}
