#include <cstdlib>
#include <cstring>
#include <string>
#include "core/XOREncryptionStrategy.h"

// Simple C ABI for Dart FFI. This demonstrates using your C++ OOP strategies.
// NOTE: XOR is NOT secure; replace with your AESEncryptionStrategy once Crypto++
// is linked into the project, but the FFI interface remains the same.

extern "C" {

    // Encrypt with XOR strategy (educational). Returns newly allocated C-string.
    // Caller must free with cpp_free.
    const char* cpp_encrypt_xor(const char* key, const char* plain) {
        if (!plain) return nullptr;
        std::string k = key ? std::string(key) : std::string("DefaultKey");
        XOREncryptionStrategy strategy(k);
        std::string enc = strategy.encrypt(std::string(plain));

        char* out = static_cast<char*>(std::malloc(enc.size() + 1));
        if (!out) return nullptr;
        std::memcpy(out, enc.c_str(), enc.size());
        out[enc.size()] = '\0';
        return out;
    }

    // Decrypt with XOR strategy (educational). Returns newly allocated C-string.
    // Caller must free with cpp_free.
    const char* cpp_decrypt_xor(const char* key, const char* cipher) {
        if (!cipher) return nullptr;
        std::string k = key ? std::string(key) : std::string("DefaultKey");
        XOREncryptionStrategy strategy(k);
        std::string dec = strategy.decrypt(std::string(cipher));

        char* out = static_cast<char*>(std::malloc(dec.size() + 1));
        if (!out) return nullptr;
        std::memcpy(out, dec.c_str(), dec.size());
        out[dec.size()] = '\0';
        return out;
    }

    // Free a C-string allocated by the functions above
    void cpp_free(const char* ptr) {
        if (ptr) std::free((void*)ptr);
    }
}
