import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkg_ffi;
import 'dart:io' show Platform;
import 'dart:convert' show utf8;

// Dart FFI bindings for the native C++ encryption bridge.
// NOTE: These functions currently wrap an XOR strategy (educational only).
// Swap native implementation to AES (keeping same signatures) when ready.

// C++ AES-256 encryption function signatures
typedef _EncryptNative =
    ffi.Pointer<ffi.Char> Function(
      ffi.Pointer<ffi.Char>, // plain
    );
typedef _DecryptNative =
    ffi.Pointer<ffi.Char> Function(
      ffi.Pointer<ffi.Char>, // cipher
    );
typedef _FreeNative = ffi.Void Function(ffi.Pointer<ffi.Char>);
typedef _ClearKeysNative = ffi.Void Function();
typedef _ResetKeysNative = ffi.Void Function();
typedef _SetUserPasswordNative = ffi.Void Function(ffi.Pointer<ffi.Char>);

typedef _Encrypt = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef _Decrypt = ffi.Pointer<ffi.Char> Function(ffi.Pointer<ffi.Char>);
typedef _Free = void Function(ffi.Pointer<ffi.Char>);
typedef _ClearKeys = void Function();
typedef _ResetKeys = void Function();
typedef _SetUserPassword = void Function(ffi.Pointer<ffi.Char>);

class NativeEncryption {
  static ffi.DynamicLibrary? _lib;
  static _Encrypt? _encrypt;
  static _Decrypt? _decrypt;
  static _Free? _free;
  static _ClearKeys? _clearKeys;
  static _ResetKeys? _resetKeys;
  static _SetUserPassword? _setUserPassword;

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
        _lib = ffi
            .DynamicLibrary.process(); // adjust as needed for iOS/macOS build
      }

      _encrypt = _lib!.lookupFunction<_EncryptNative, _Encrypt>(
        'cpp_encrypt_aes',
      );
      _decrypt = _lib!.lookupFunction<_DecryptNative, _Decrypt>(
        'cpp_decrypt_aes',
      );
      _free = _lib!.lookupFunction<_FreeNative, _Free>('cpp_free');
      _clearKeys = _lib!.lookupFunction<_ClearKeysNative, _ClearKeys>(
        'cpp_clear_keys',
      );
      _resetKeys = _lib!.lookupFunction<_ResetKeysNative, _ResetKeys>(
        'cpp_reset_keys',
      );
      _setUserPassword = _lib!
          .lookupFunction<_SetUserPasswordNative, _SetUserPassword>(
            'cpp_set_user_password',
          );
    } catch (_) {
      _lib = null;
      _encrypt = null;
      _decrypt = null;
      _free = null;
      _resetKeys = null;
      _setUserPassword = null;
    }
  }

  /// Encrypt using C++ AES-256-CBC encryption
  /// Returns base64 encoded ciphertext
  static String? encryptAES(String plain) {
    init();
    if (!isAvailable) return null;
    final plainPtr = _toNativeUtf8(plain);
    final resPtr = _encrypt!(plainPtr);
    _freeNativeString(plainPtr);
    if (resPtr == ffi.Pointer.fromAddress(0)) return null;
    final result = _fromNativeUtf8(resPtr);
    _free!(resPtr);
    return result;
  }

  /// Decrypt using C++ AES-256-CBC encryption
  /// Input should be base64 encoded ciphertext
  static String? decryptAES(String cipher) {
    init();
    if (!isAvailable) return null;
    final cipherPtr = _toNativeUtf8(cipher);
    final resPtr = _decrypt!(cipherPtr);
    _freeNativeString(cipherPtr);
    if (resPtr == ffi.Pointer.fromAddress(0)) return null;
    final result = _fromNativeUtf8(resPtr);
    _free!(resPtr);
    return result;
  }

  /// Clear encryption keys (for logout)
  static void clearKeys() {
    init();
    if (_clearKeys != null) {
      _clearKeys!();
    }
  }

  /// Reset encryption keys (regenerate deterministic keys)
  static void resetKeys() {
    init();
    if (_resetKeys != null) {
      _resetKeys!();
    }
  }

  /// Set user password for key derivation (called after login)
  /// Each user will have unique encryption keys derived from their password
  static void setUserPassword(String password) {
    init();
    if (_setUserPassword != null) {
      final passwordPtr = _toNativeUtf8(password);
      _setUserPassword!(passwordPtr);
      _freeNativeString(passwordPtr);
    }
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
