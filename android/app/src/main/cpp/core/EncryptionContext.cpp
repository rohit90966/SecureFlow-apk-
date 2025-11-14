#include "EncryptionContext.h"
#include <stdexcept>
#include <sstream>

EncryptionContext::EncryptionContext() : strategy(nullptr) {}

EncryptionContext::EncryptionContext(std::unique_ptr<IEncryptionStrategy> initialStrategy)
    : strategy(std::move(initialStrategy)) {
    
    if (strategy && strategy->requiresInitialization()) {
        strategy->initialize();
    }
}

void EncryptionContext::setStrategy(std::unique_ptr<IEncryptionStrategy> newStrategy) {
    strategy = std::move(newStrategy);
    
    if (strategy && strategy->requiresInitialization()) {
        strategy->initialize();
    }
}

const IEncryptionStrategy* EncryptionContext::getStrategy() const {
    return strategy.get();
}

std::string EncryptionContext::encrypt(const std::string& plainText) {
    if (!strategy) {
        throw std::runtime_error("No encryption strategy set. Call setStrategy() first.");
    }
    
    return strategy->encrypt(plainText);
}

std::string EncryptionContext::decrypt(const std::string& cipherText) {
    if (!strategy) {
        throw std::runtime_error("No encryption strategy set. Call setStrategy() first.");
    }
    
    return strategy->decrypt(cipherText);
}

std::string EncryptionContext::getAlgorithmInfo() const {
    if (!strategy) {
        return "No strategy set";
    }
    
    std::stringstream ss;
    ss << "Algorithm: " << strategy->getAlgorithmName();
    
    int keyStrength = strategy->getKeyStrength();
    if (keyStrength > 0) {
        ss << " | Key Strength: " << keyStrength << " bits";
    }
    
    return ss.str();
}
