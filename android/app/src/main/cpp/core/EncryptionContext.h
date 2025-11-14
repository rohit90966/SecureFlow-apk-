#ifndef ENCRYPTIONCONTEXT_H
#define ENCRYPTIONCONTEXT_H

#include "IEncryptionStrategy.h"
#include <memory>
#include <string>

class EncryptionContext {
private:
    std::unique_ptr<IEncryptionStrategy> strategy;

public:
    EncryptionContext() = default;

    explicit EncryptionContext(std::unique_ptr<IEncryptionStrategy> initialStrategy) 
        : strategy(std::move(initialStrategy)) {
        if (strategy && strategy->requiresInitialization()) {
            strategy->initialize();
        }
    }

    void setStrategy(std::unique_ptr<IEncryptionStrategy> newStrategy) {
        if (!newStrategy) {
            throw std::invalid_argument("Strategy cannot be null");
        }
        
        if (newStrategy->requiresInitialization()) {
            newStrategy->initialize();
        }
        
        strategy = std::move(newStrategy);
    }

    const IEncryptionStrategy* getStrategy() const {
        return strategy.get();
    }

    std::string encrypt(const std::string& plainText) {
        if (!strategy) {
            throw EncryptionException("No encryption strategy set");
        }
        
        if (plainText.empty()) {
            throw std::invalid_argument("Plaintext cannot be empty");
        }

        try {
            strategy->validate();
            return strategy->encrypt(plainText);
        } catch (const std::exception& e) {
            throw EncryptionException(std::string("Encryption failed: ") + e.what());
        }
    }

    std::string decrypt(const std::string& cipherText) {
        if (!strategy) {
            throw EncryptionException("No encryption strategy set");
        }
        
        if (cipherText.empty()) {
            throw std::invalid_argument("Ciphertext cannot be empty");
        }

        try {
            strategy->validate();
            return strategy->decrypt(cipherText);
        } catch (const std::exception& e) {
            throw EncryptionException(std::string("Decryption failed: ") + e.what());
        }
    }

    std::string getAlgorithmInfo() const {
        if (!strategy) {
            return "No strategy set";
        }
        
        try {
            return strategy->getAlgorithmName() + " (" + 
                   std::to_string(strategy->getKeyStrength()) + "-bit)";
        } catch (const std::exception& e) {
            return "Error getting algorithm info: " + std::string(e.what());
        }
    }

    bool hasStrategy() const { return strategy != nullptr; }
};

#endif // ENCRYPTIONCONTEXT_H