#ifndef IENCRYPTIONSTRATEGY_H
#define IENCRYPTIONSTRATEGY_H

#include <string>
#include <memory>
#include <fstream>
#include <stdexcept>

/**
 * @brief Custom exception hierarchy for encryption operations
 */
class EncryptionException : public std::runtime_error {
public:
    explicit EncryptionException(const std::string& message) 
        : std::runtime_error("🔐 Encryption Error: " + message) {}
};

class KeyManagementException : public EncryptionException {
public:
    explicit KeyManagementException(const std::string& message)
        : EncryptionException("Key Management: " + message) {}
};

class AlgorithmException : public EncryptionException {
public:
    explicit AlgorithmException(const std::string& message)
        : EncryptionException("Algorithm: " + message) {}
};

/**
 * @brief Base interface for all encryption strategies
 */
class IEncryptionStrategy {
public:
    virtual ~IEncryptionStrategy() = default;

    virtual std::string encrypt(const std::string& plainText) = 0;
    virtual std::string decrypt(const std::string& cipherText) = 0;
    virtual std::string getAlgorithmName() const = 0;
    virtual bool requiresInitialization() const = 0;
    virtual void initialize() {}
    virtual int getKeyStrength() const { return 0; }

    virtual void validate() const {
        if (requiresInitialization()) {
            throw EncryptionException("Strategy requires initialization before use");
        }
    }
};

/**
 * @brief Base class for symmetric encryption strategies
 */
class ISymmetricEncryption : public IEncryptionStrategy {
public:
    virtual std::string getKeyType() const { return "Symmetric"; }
    
    void validate() const override {
        IEncryptionStrategy::validate();
        if (getKeyStrength() < 128) {
            throw KeyManagementException("Symmetric key strength too weak: " + 
                                       std::to_string(getKeyStrength()) + " bits");
        }
    }
};

/**
 * @brief Base class for strategies that use file-based key storage
 */
class IFileBasedEncryption : public IEncryptionStrategy {
protected:
    std::string keyFilePath;
    std::string ivFilePath;

public:
    IFileBasedEncryption(const std::string& keyPath, const std::string& ivPath)
        : keyFilePath(keyPath), ivFilePath(ivPath) {}
    
    virtual bool keysExist() const {
        std::ifstream keyFile(keyFilePath), ivFile(ivFilePath);
        return keyFile.good() && ivFile.good();
    }
    
    virtual void backupKeys(const std::string& backupPath) const {
        // Implementation for key backup
        throw KeyManagementException("Key backup not implemented");
    }
};

#endif 