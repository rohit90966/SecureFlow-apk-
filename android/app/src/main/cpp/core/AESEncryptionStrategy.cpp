#include "AESEncryptionStrategy.h"
#include <cryptopp/aes.h>
#include <cryptopp/modes.h>
#include <cryptopp/filters.h>
#include <cryptopp/base64.h>
#include <cryptopp/osrng.h>
#include <fstream>
#include <iostream>
#include <stdexcept>

using namespace CryptoPP;

AESEncryptionStrategy::AESEncryptionStrategy(
    const std::string& keyPath,
    const std::string& ivPath
) : key(32), iv(16), initialized(false), 
    keyFilePath(keyPath), ivFilePath(ivPath) {
    // Constructor - prepare key and IV containers
    // Actual initialization happens in initialize()
}

AESEncryptionStrategy::~AESEncryptionStrategy() {
    // Destructor - secure cleanup (zero out sensitive data)
    // SecByteBlock handles its own secure cleanup
    initialized = false;
}

void AESEncryptionStrategy::initialize() {
    if (initialized) {
        return; // Already initialized
    }

    if (!loadKeysFromFile()) {
        // Keys don't exist, generate new ones
        generateNewKeys();
        saveKeysToFile();
        std::cout << "🔐 [AES-256] Generated new encryption keys\n";
    } else {
        std::cout << "🔐 [AES-256] Loaded existing encryption keys\n";
    }

    initialized = true;
}

bool AESEncryptionStrategy::loadKeysFromFile() {
    std::ifstream keyIn(keyFilePath, std::ios::binary);
    std::ifstream ivIn(ivFilePath, std::ios::binary);

    if (!keyIn || !ivIn) {
        return false;
    }

    std::vector<byte> keyVec(32), ivVec(16);
    keyIn.read(reinterpret_cast<char*>(keyVec.data()), keyVec.size());
    ivIn.read(reinterpret_cast<char*>(ivVec.data()), ivVec.size());

    if (keyIn.gcount() != 32 || ivIn.gcount() != 16) {
        return false; // File corrupted or incomplete
    }

    key.Assign(keyVec.data(), keyVec.size());
    iv.Assign(ivVec.data(), ivVec.size());

    return true;
}

void AESEncryptionStrategy::saveKeysToFile() {
    std::ofstream keyOut(keyFilePath, std::ios::binary);
    std::ofstream ivOut(ivFilePath, std::ios::binary);

    if (!keyOut || !ivOut) {
        throw std::runtime_error("Failed to save encryption keys");
    }

    keyOut.write(reinterpret_cast<const char*>(key.data()), key.size());
    ivOut.write(reinterpret_cast<const char*>(iv.data()), iv.size());
}

void AESEncryptionStrategy::generateNewKeys() {
    AutoSeededRandomPool prng;
    prng.GenerateBlock(key, key.size());
    prng.GenerateBlock(iv, iv.size());
}

std::string AESEncryptionStrategy::encrypt(const std::string& plainText) {
    if (!initialized) {
        throw std::runtime_error("AES encryption strategy not initialized. Call initialize() first.");
    }

    if (plainText.empty()) {
        return ""; // Empty input returns empty output
    }

    try {
        std::string cipherText;
        CBC_Mode<AES>::Encryption encryptor(key, key.size(), iv);
        
        StringSource ss(plainText, true,
            new StreamTransformationFilter(encryptor,
                new Base64Encoder(
                    new StringSink(cipherText), 
                    false // No newlines in Base64
                )
            )
        );
        
        return cipherText;
    } catch (const Exception& e) {
        throw std::runtime_error(std::string("AES encryption failed: ") + e.what());
    }
}

std::string AESEncryptionStrategy::decrypt(const std::string& cipherText) {
    if (!initialized) {
        throw std::runtime_error("AES encryption strategy not initialized. Call initialize() first.");
    }

    if (cipherText.empty()) {
        return ""; // Empty input returns empty output
    }

    try {
        std::string plainText;
        CBC_Mode<AES>::Decryption decryptor(key, key.size(), iv);
        
        StringSource ss(cipherText, true,
            new Base64Decoder(
                new StreamTransformationFilter(decryptor,
                    new StringSink(plainText)
                )
            )
        );
        
        return plainText;
    } catch (const Exception& e) {
        throw std::runtime_error(std::string("AES decryption failed: ") + e.what());
    }
}

std::string AESEncryptionStrategy::getAlgorithmName() const {
    return "AES-256-CBC";
}

bool AESEncryptionStrategy::requiresInitialization() const {
    return true;
}

int AESEncryptionStrategy::getKeyStrength() const {
    return 256; // 256-bit key
}

void AESEncryptionStrategy::clearKeys() {
    std::remove(keyFilePath.c_str());
    std::remove(ivFilePath.c_str());
    initialized = false;
    std::cout << "🔐 [AES-256] Cleared encryption keys\n";
}
