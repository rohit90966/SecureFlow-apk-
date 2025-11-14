import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkg_ffi;
import 'dart:io' show Platform;
import 'dart:convert' show utf8;

// Dart FFI bindings for the native C++ encryption bridge.
// NOTE: These functions currently wrap an XOR strategy (educational only).
// Swap native implementation to AES (keeping same signatures) when ready.

typedef _EncryptNative = ffi.Pointer<ffi.Char> Function(
  ffi.Pointer<ffi.Char>, // key
  ffi.Pointer<ffi.Char>, // plain
);
typedef _DecryptNative = ffi.Pointer<ffi.Char> Function(
  ffi.Pointer<ffi.Char>, // key
  ffi.Pointer<ffi.Char>, // cipher
);
typedef _FreeNative = ffi.Void Function(ffi.Pointer<ffi.Char>);

typedef _Encrypt = ffi.Pointer<ffi.Char> Function(
  ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>,
);
typedef _Decrypt = ffi.Pointer<ffi.Char> Function(
  ffi.Pointer<ffi.Char>,
  ffi.Pointer<ffi.Char>,
);
typedef _Free = void Function(ffi.Pointer<ffi.Char>);

class NativeEncryption {
  static ffi.DynamicLibrary? _lib;
  static _Encrypt? _encrypt;
  static _Decrypt? _decrypt;
  static _Free? _free;

  static bool get isAvailable =>
      _lib != null && _encrypt != null && _decrypt != null && _free != null;

  static void init() {
    if (_lib != null) return;
    try {
      if (Platform.isAndroid) {
        // The shared library name is 'libpasswordcore.so' per CMake add_library(passwordcore SHARED ...)
        _lib = ffi.DynamicLibrary.open('libpasswordcore.so');
      } else if (Platform.isWindows) {
        _lib = ffi.DynamicLibrary.open('passwordcore.dll');
      } else if (Platform.isLinux) {
        _lib = ffi.DynamicLibrary.open('libpasswordcore.so');
      } else if (Platform.isMacOS || Platform.isIOS) {
        _lib = ffi.DynamicLibrary
            .process(); // adjust as needed for iOS/macOS build
      }

      _encrypt =
          _lib!.lookupFunction<_EncryptNative, _Encrypt>('cpp_encrypt_xor');
      _decrypt =
          _lib!.lookupFunction<_DecryptNative, _Decrypt>('cpp_decrypt_xor');
      _free = _lib!.lookupFunction<_FreeNative, _Free>('cpp_free');
    } catch (_) {
      _lib = null;
      _encrypt = null;
      _decrypt = null;
      _free = null;
    }
  }

  static String? encryptXor(String key, String plain) {
    init();
    if (!isAvailable) return null;
    final keyPtr = _toNativeUtf8(key);
    final plainPtr = _toNativeUtf8(plain);
    final resPtr = _encrypt!(keyPtr, plainPtr);
    _freeNativeString(keyPtr);
    _freeNativeString(plainPtr);
    if (resPtr == ffi.Pointer.fromAddress(0)) return null;
    final result = _fromNativeUtf8(resPtr);
    _free!(resPtr);
    return result;
  }

  static String? decryptXor(String key, String cipher) {
    init();
    if (!isAvailable) return null;
    final keyPtr = _toNativeUtf8(key);
    final cipherPtr = _toNativeUtf8(cipher);
    final resPtr = _decrypt!(keyPtr, cipherPtr);
    _freeNativeString(keyPtr);
    _freeNativeString(cipherPtr);
    if (resPtr == ffi.Pointer.fromAddress(0)) return null;
    final result = _fromNativeUtf8(resPtr);
    _free!(resPtr);
    return result;
  }

  static ffi.Pointer<ffi.Char> _toNativeUtf8(String s) {
    final units = utf8.encode(s);
    final ptr = pkg_ffi.malloc.allocate<ffi.Char>(units.length + 1);
    for (var i = 0; i < units.length; i++) {
      ptr.elementAt(i).value = units[i];
    }
    ptr.elementAt(units.length).value = 0;
    return ptr;
  }

  static void _freeNativeString(ffi.Pointer<ffi.Char> p) {
    pkg_ffi.malloc.free(p);
  }

  static String _fromNativeUtf8(ffi.Pointer<ffi.Char> ptr) {
    // Read until null terminator
    final bytes = <int>[];
    int offset = 0;
    while (true) {
      final v = ptr.elementAt(offset).value;
      if (v == 0) break;
      bytes.add(v);
      offset++;
    }
    return utf8.decode(bytes);
  }
}
