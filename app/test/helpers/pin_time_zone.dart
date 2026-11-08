import 'dart:ffi';
import 'dart:io';

typedef _SetEnvC = Int32 Function(Pointer<Uint8>, Pointer<Uint8>, Int32);
typedef _SetEnv = int Function(Pointer<Uint8>, Pointer<Uint8>, int);

/// Sets the test process's time zone to UTC (POSIX `setenv("TZ", "UTC")` + `tzset()`), so
/// `DateTime.toLocal()` in widgets gives the same text on every machine (audit L11). Uses only
/// dart:ffi and the C library already loaded in the process; no package. A no-op on Windows.
void pinTimeZoneToUtc() {
  if (Platform.isWindows) return;
  final libc = DynamicLibrary.process();
  final setenv = libc.lookupFunction<_SetEnvC, _SetEnv>('setenv');
  final tzset = libc.lookupFunction<Void Function(), void Function()>('tzset');
  final name = _cString('TZ');
  final value = _cString('UTC');
  setenv(
    name,
    value,
    1,
  ); // setenv copies both strings; these stay allocated for the run.
  tzset();
}

Pointer<Uint8> _cString(String s) {
  final bytes = [...s.codeUnits, 0];
  final p = _malloc(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    p[i] = bytes[i];
  }
  return p;
}

Pointer<Uint8> _malloc(int n) {
  final malloc = DynamicLibrary.process()
      .lookupFunction<
        Pointer<Uint8> Function(IntPtr),
        Pointer<Uint8> Function(int)
      >('malloc');
  return malloc(n);
}
