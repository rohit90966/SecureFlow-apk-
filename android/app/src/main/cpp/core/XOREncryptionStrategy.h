#ifndef XORENCRYPTIONSTRATEGY_H
#define XORENCRYPTIONSTRATEGY_H

#include "IEncryptionStrategy.h"

/**
 * @brief Simple XOR encryption strategy (for educational/testing purposes)
 * 
 * ⚠️ WARNING: XOR is NOT secure for production use!
 * This is included for demonstration and testing purposes only.
 * 
 * Demonstrates: Inheritance, Polymorphism, Strategy Pattern
 * 
 * OOP Concepts:
 * - Shows how different algorithms can share same interface
 * - Simpler than AES, useful for testing and demonstrating the pattern
 * - Can be swapped with AES at runtime (Open/Closed Principle - SOLID)
 */
class XOREncryptionStrategy : public IEncryptionStrategy {
private:
    std::string key;
    
    std::string xorOperation(const std::string& input) const;

public:
    /**
     * @brief Constructor with XOR key
     * @param xorKey The key to use for XOR encryption (default: "SecureKey123")
     */
    explicit XOREncryptionStrategy(const std::string& xorKey = "SecureKey123");

    // Implement IEncryptionStrategy interface
    std::string encrypt(const std::string& plainText) override;
    std::string decrypt(const std::string& cipherText) override;
    std::string getAlgorithmName() const override;
    bool requiresInitialization() const override;
    int getKeyStrength() const override;

    // XOR-specific methods
    void setKey(const std::string& newKey);
    std::string getKey() const { return key; }
};

#endif // XORENCRYPTIONSTRATEGY_H
