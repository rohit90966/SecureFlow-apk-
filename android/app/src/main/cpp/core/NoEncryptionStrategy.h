#ifndef NOENCRYPTIONSTRATEGY_H
#define NOENCRYPTIONSTRATEGY_H

#include "IEncryptionStrategy.h"

/**
 * @brief No-op encryption strategy (plaintext passthrough)
 * 
 * Useful for: Testing, debugging, development mode
 * 
 * Demonstrates: Null Object Pattern combined with Strategy Pattern
 * 
 * OOP Concepts:
 * - Shows polymorphism - can be swapped in without breaking code
 * - Null Object Pattern - provides a "do nothing" implementation
 * - Useful for testing and debugging without crypto overhead
 */
class NoEncryptionStrategy : public IEncryptionStrategy {
public:
    NoEncryptionStrategy() = default;

    // Implement IEncryptionStrategy interface
    std::string encrypt(const std::string& plainText) override;
    std::string decrypt(const std::string& cipherText) override;
    std::string getAlgorithmName() const override;
    bool requiresInitialization() const override;
    int getKeyStrength() const override;
};

#endif // NOENCRYPTIONSTRATEGY_H
