#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <fstream>
#include <iostream>
#include "core/SimpleAES.h"

static SimpleAES* g_aes = nullptr;
static std::string g_keyFile = "/data/data/com.example.last_final/aes_key.bin";
static std::string g_ivFile = "/data/data/com.example.last_final/aes_iv.bin";

static std::vector<uint8_t> deriveKey(const std::string& password, const std::vector<uint8_t>& salt, int iterations, size_t keyLen) {
    std::vector<uint8_t> derived(keyLen);
    std::vector<uint8_t> block(password.begin(), password.end());
    block.insert(block.end(), salt.begin(), salt.end());
    block.push_back(0);
    block.push_back(0);
    block.push_back(0);
    block.push_back(1);
    std::vector<uint8_t> U = block;
    std::vector<uint8_t> result(keyLen, 0);

    for (int iter = 0; iter < iterations; iter++) {
        uint8_t hash = 0;
        for (size_t i = 0; i < U.size(); i++) {
            hash ^= U[i];
            U[i] = (U[i] << 1) | (U[i] >> 7);
            U[i] ^= (hash + iter) & 0xFF;
        }
        for (size_t i = 0; i < keyLen && i < U.size(); i++) {
            result[i] ^= U[i];
        }
    }

    for (size_t i = 0; i < result.size(); i++) {
        result[i] ^= (result[(i + 1) % result.size()] + result[(i + 2) % result.size()]);
    }
    return result;
}

static std::string g_userPassword = "";
static bool g_keysInitialized = false;

extern "C" {
    void cpp_set_user_password(const char* password) {
        if (password) {
            g_userPassword = std::string(password);
            g_keysInitialized = false;
            if (g_aes) {
                delete g_aes;
                g_aes = nullptr;
            }
            std::cout << "User password set\n";
        }
    }
}

static void initAES() {
    if (g_aes != nullptr) return;

    if (g_userPassword.empty()) {
        std::cerr << "ERROR: User password not set\n";

        std::vector<uint8_t> key(32);
        std::vector<uint8_t> iv(16);

        std::ifstream keyIn(g_keyFile, std::ios::binary);
        std::ifstream ivIn(g_ivFile, std::ios::binary);

        if (keyIn && ivIn) {
            keyIn.read(reinterpret_cast<char*>(key.data()), 32);
            ivIn.read(reinterpret_cast<char*>(iv.data()), 16);
            keyIn.close();
            ivIn.close();

            bool keysValid = false;
            for (size_t i = 0; i < key.size(); i++) {
                if (key[i] != 0) {
                    keysValid = true;
                    break;
                }
            }

            if (keysValid) {
                std::cout << "Using legacy file-based keys\n";
                g_aes = new SimpleAES(key, iv);
                return;
            }
        }

        std::cerr << "No keys available\n";
        return;
    }

    std::cout << "Deriving encryption keys...\n";

    std::string packageName = "com.example.last_final";
    std::vector<uint8_t> salt(packageName.begin(), packageName.end());

    std::vector<uint8_t> fixed = {0x53, 0x65, 0x63, 0x75, 0x72, 0x65, 0x56, 0x61, 0x75, 0x6c, 0x74};
    salt.insert(salt.end(), fixed.begin(), fixed.end());

    while (salt.size() < 16) salt.push_back(salt.size() & 0xFF);
    salt.resize(16);

    int iterations = 100000;
    std::vector<uint8_t> derived = deriveKey(g_userPassword, salt, iterations, 48);

    std::vector<uint8_t> key(derived.begin(), derived.begin() + 32);
    std::vector<uint8_t> iv(derived.begin() + 32, derived.begin() + 48);

    g_aes = new SimpleAES(key, iv);
    g_keysInitialized = true;

    std::cout << "AES initialized\n";
}

extern "C" {

    const char* cpp_encrypt_aes(const char* plain) {
        if (!plain) return nullptr;
        try {
            initAES();
            if (!g_aes) {
                std::cerr << "AES not initialized\n";
                return nullptr;
            }

            std::string enc = g_aes->encrypt(std::string(plain));
            char* out = static_cast<char*>(std::malloc(enc.size() + 1));
            if (!out) return nullptr;
            std::memcpy(out, enc.c_str(), enc.size());
            out[enc.size()] = '\0';
            return out;

        } catch (const std::exception& e) {
            std::cerr << "AES encryption failed\n";
            return nullptr;
        }
    }

    const char* cpp_decrypt_aes(const char* cipher) {
        if (!cipher) return nullptr;
        try {
            initAES();
            if (!g_aes) {
                std::cerr << "AES not initialized\n";
                return nullptr;
            }

            std::string dec = g_aes->decrypt(std::string(cipher));
            char* out = static_cast<char*>(std::malloc(dec.size() + 1));
            if (!out) return nullptr;
            std::memcpy(out, dec.c_str(), dec.size());
            out[dec.size()] = '\0';
            return out;

        } catch (const std::exception& e) {
            std::cerr << "AES decryption failed\n";
            return nullptr;
        }
    }

    void cpp_reset_keys() {
        if (g_aes) {
            delete g_aes;
            g_aes = nullptr;
        }
        std::remove(g_keyFile.c_str());
        std::remove(g_ivFile.c_str());
        std::cout << "Reset encryption keys\n";
        initAES();
    }

    void cpp_free(const char* ptr) {
        if (ptr) std::free((void*)ptr);
    }

    void cpp_clear_keys() {
        if (g_aes) {
            delete g_aes;
            g_aes = nullptr;
        }
        std::remove(g_keyFile.c_str());
        std::remove(g_ivFile.c_str());
        std::cout << "Cleared AES keys\n";
    }
}
