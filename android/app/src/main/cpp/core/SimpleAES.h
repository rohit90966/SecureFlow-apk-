#ifndef SIMPLEAES_H
#define SIMPLEAES_H

#include <string>
#include <vector>
#include <cstdint>

/**
 * @brief Simplified AES-256 CBC implementation
 * Uses mbedTLS-style approach without external dependencies
 * This is a production-ready implementation for password encryption
 */
class SimpleAES {
private:
    std::vector<uint8_t> key;  // 32 bytes for AES-256
    std::vector<uint8_t> iv;   // 16 bytes for CBC mode
    
    // AES core functions
    void aesEncryptBlock(const uint8_t* in, uint8_t* out, const std::vector<uint32_t>& roundKeys);
    void aesDecryptBlock(const uint8_t* in, uint8_t* out, const std::vector<uint32_t>& roundKeys);
    std::vector<uint32_t> keyExpansion(const std::vector<uint8_t>& key);
    
    // Helper functions
    std::string base64Encode(const std::vector<uint8_t>& data);
    std::vector<uint8_t> base64Decode(const std::string& encoded);
    std::vector<uint8_t> pkcs7Pad(const std::vector<uint8_t>& data, size_t blockSize);
    std::vector<uint8_t> pkcs7Unpad(const std::vector<uint8_t>& data);

public:
    SimpleAES(const std::vector<uint8_t>& key, const std::vector<uint8_t>& iv);
    
    /**
     * @brief Encrypt plaintext to base64 encoded ciphertext
     * @param plainText Input string to encrypt
     * @return Base64 encoded encrypted string
     */
    std::string encrypt(const std::string& plainText);
    
    /**
     * @brief Decrypt base64 encoded ciphertext to plaintext
     * @param cipherText Base64 encoded encrypted string
     * @return Decrypted plaintext string
     */
    std::string decrypt(const std::string& cipherText);
    
    /**
     * @brief Generate random bytes for key/IV
     * @param length Number of bytes to generate
     * @return Vector of random bytes
     */
    static std::vector<uint8_t> generateRandomBytes(size_t length);
};

#endif // SIMPLEAES_H
