typedef uintptr_t S7Object; // multi platform/processor object reference

S7Object Cli_Create();
int Cli_ConnectTo(S7Object Client, const char *Address, int Rack, int Slot);
int Cli_SetParam(S7Object Client, int ParamNumber, void *pValue);

