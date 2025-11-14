#include "XOREncryptionStrategy.h"
#include <sstream>
#include <iomanip>

XOREncryptionStrategy::XOREncryptionStrategy(const std::string& xorKey) 
    : key(xorKey) {
    if (key.empty()) {
        key = "DefaultKey"; // Ensure key is never empty
    }
}

std::string XOREncryptionStrategy::xorOperation(const std::string& input) const {
    std::string result;
    result.reserve(input.size());
    
    size_t keyLen = key.length();
    for (size_t i = 0; i < input.length(); ++i) {
        result += input[i] ^ key[i % keyLen];
    }
    
    return result;
}

std::string XOREncryptionStrategy::encrypt(const std::string& plainText) {
    if (plainText.empty()) {
        return "";
    }

    // XOR the plaintext
    std::string xored = xorOperation(plainText);
    
    // Convert to hex for readable storage/transmission
    std::stringstream ss;
    for (unsigned char c : xored) {
        ss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(c);
    }
    
    return ss.str();
}

std::string XOREncryptionStrategy::decrypt(const std::string& cipherText) {
    if (cipherText.empty()) {
        return "";
    }

    // Convert hex back to binary
    std::string binary;
    for (size_t i = 0; i < cipherText.length(); i += 2) {
        std::string byteString = cipherText.substr(i, 2);
        char byte = static_cast<char>(std::stoi(byteString, nullptr, 16));
        binary += byte;
    }
    
    // XOR to decrypt (XOR is symmetric)
    return xorOperation(binary);
}

std::string XOREncryptionStrategy::getAlgorithmName() const {
    return "XOR (Educational Only - NOT SECURE)";
}

bool XOREncryptionStrategy::requiresInitialization() const {
    return false; // XOR doesn't need initialization
}

int XOREncryptionStrategy::getKeyStrength() const {
    return key.length() * 8; // Bits (weak, but returns key length in bits)
}

void XOREncryptionStrategy::setKey(const std::string& newKey) {
    if (!newKey.empty()) {
        key = newKey;
    }
}
