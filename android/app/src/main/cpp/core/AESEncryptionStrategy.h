#ifndef AESENCRYPTIONSTRATEGY_H
#define AESENCRYPTIONSTRATEGY_H

#include "IEncryptionStrategy.h"
#include <cryptopp/secblock.h>


class AESEncryptionStrategy : public IEncryptionStrategy {
private:
    CryptoPP::SecByteBlock key;  // 256-bit AES key
    CryptoPP::SecByteBlock iv;   // 128-bit initialization vector
    bool initialized;
    
    std::string keyFilePath;
    std::string ivFilePath;

    // Private helper methods (encapsulation)
    bool loadKeysFromFile();
    void saveKeysToFile();
    void generateNewKeys();

public:
    /**
     * @brief Constructor with custom key/IV file paths
     * @param keyPath Path to store/load AES key
     * @param ivPath Path to store/load IV
     */
    explicit AESEncryptionStrategy(
        const std::string& keyPath = "aes_key.bin",
        const std::string& ivPath = "aes_iv.bin"
    );

    // Destructor - demonstrates RAII cleanup
    ~AESEncryptionStrategy() override;

    // Implement IEncryptionStrategy interface
    std::string encrypt(const std::string& plainText) override;
    std::string decrypt(const std::string& cipherText) override;
    std::string getAlgorithmName() const override;
    bool requiresInitialization() const override;
    void initialize() override;
    int getKeyStrength() const override;

    // Additional AES-specific methods
    void clearKeys();
    bool isInitialized() const { return initialized; }
};

#endif // AESENCRYPTIONSTRATEGY_H
