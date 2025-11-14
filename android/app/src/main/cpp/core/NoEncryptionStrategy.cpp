#include "NoEncryptionStrategy.h"

std::string NoEncryptionStrategy::encrypt(const std::string& plainText) {
    // Passthrough - no encryption
    return plainText;
}

std::string NoEncryptionStrategy::decrypt(const std::string& cipherText) {
    // Passthrough - no decryption needed
    return cipherText;
}

std::string NoEncryptionStrategy::getAlgorithmName() const {
    return "None (Plaintext)";
}

bool NoEncryptionStrategy::requiresInitialization() const {
    return false;
}

int NoEncryptionStrategy::getKeyStrength() const {
    return 0; // No encryption = no key
}
