#include <iostream>
#include <string>
#include <memory>
#include "core/EncryptionContext.h"
#include "core/AESEncryptionStrategy.h"
#include "core/XOREncryptionStrategy.h"
#include "core/NoEncryptionStrategy.h"

using namespace std;

/**
 * @brief Demo program showing the Strategy Pattern for Encryption
 * 
 * This demonstrates:
 * 1. Polymorphism - different encryption algorithms through same interface
 * 2. Strategy Pattern - swappable algorithms at runtime
 * 3. Dependency Injection - strategies injected into context
 * 4. SOLID Principles - Open/Closed, Dependency Inversion
 * 
 * Perfect for OOP course project demonstration!
 */

void printHeader(const string& title) {
    cout << "\n" << string(60, '=') << "\n";
    cout << "  " << title << "\n";
    cout << string(60, '=') << "\n";
}

void demonstrateStrategy(EncryptionContext& context, const string& testData) {
    cout << "\n📋 Current Strategy: " << context.getAlgorithmInfo() << "\n";
    
    try {
        string encrypted = context.encrypt(testData);
        cout << "🔒 Encrypted: " << encrypted << "\n";
        
        string decrypted = context.decrypt(encrypted);
        cout << "🔓 Decrypted: " << decrypted << "\n";
        
        if (decrypted == testData) {
            cout << "✅ Encryption/Decryption SUCCESS!\n";
        } else {
            cout << "❌ Encryption/Decryption FAILED!\n";
        }
    } catch (const exception& e) {
        cout << "❌ Error: " << e.what() << "\n";
    }
}

int main() {
    printHeader("Strategy Pattern Encryption Demo");
    cout << "🎓 Demonstrating OOP Concepts: Polymorphism, Strategy Pattern, SOLID\n";
    
    const string testData = "MySecretPassword123!";
    cout << "\n📝 Test Data: \"" << testData << "\"\n";

    // Create encryption context (initially empty)
    EncryptionContext encryptionService;

    // ========================================================================
    // Strategy 1: AES-256-CBC (Production-grade encryption)
    // ========================================================================
    printHeader("Strategy 1: AES-256-CBC Encryption");
    cout << "🔐 Industry-standard encryption (256-bit key)\n";
    
    auto aesStrategy = make_unique<AESEncryptionStrategy>("test_aes_key.bin", "test_aes_iv.bin");
    encryptionService.setStrategy(move(aesStrategy));
    demonstrateStrategy(encryptionService, testData);

    // ========================================================================
    // Strategy 2: XOR Encryption (Educational/Demo)
    // ========================================================================
    printHeader("Strategy 2: XOR Encryption");
    cout << "⚠️  Simple encryption for demo purposes only\n";
    
    auto xorStrategy = make_unique<XOREncryptionStrategy>("MyXORKey456");
    encryptionService.setStrategy(move(xorStrategy));
    demonstrateStrategy(encryptionService, testData);

    // ========================================================================
    // Strategy 3: No Encryption (Null Object Pattern)
    // ========================================================================
    printHeader("Strategy 3: No Encryption (Plaintext)");
    cout << "🚫 Useful for testing and debugging\n";
    
    auto noStrategy = make_unique<NoEncryptionStrategy>();
    encryptionService.setStrategy(move(noStrategy));
    demonstrateStrategy(encryptionService, testData);

    // ========================================================================
    // Demonstrate Runtime Strategy Switching
    // ========================================================================
    printHeader("Runtime Strategy Switching Demo");
    cout << "🔄 Switching between strategies dynamically...\n";
    
    // Switch back to AES
    cout << "\n➡️  Switching to AES...\n";
    encryptionService.setStrategy(make_unique<AESEncryptionStrategy>("test_aes_key.bin", "test_aes_iv.bin"));
    string aesEncrypted = encryptionService.encrypt("SwitchTest");
    cout << "   AES Encrypted: " << aesEncrypted << "\n";
    
    // Switch to XOR
    cout << "\n➡️  Switching to XOR...\n";
    encryptionService.setStrategy(make_unique<XOREncryptionStrategy>("TestKey"));
    string xorEncrypted = encryptionService.encrypt("SwitchTest");
    cout << "   XOR Encrypted: " << xorEncrypted << "\n";
    
    cout << "\n✅ Both strategies work independently with same interface!\n";

    // ========================================================================
    // OOP Concepts Summary
    // ========================================================================
    printHeader("OOP Concepts Demonstrated");
    cout << "✅ Polymorphism: Multiple encryption algorithms via single interface\n";
    cout << "✅ Encapsulation: Implementation details hidden in strategy classes\n";
    cout << "✅ Abstraction: IEncryptionStrategy defines contract\n";
    cout << "✅ Strategy Pattern: Algorithms encapsulated and interchangeable\n";
    cout << "✅ Dependency Injection: Strategies injected into context\n";
    cout << "✅ Open/Closed Principle: New strategies without modifying context\n";
    cout << "✅ RAII: Smart pointers for automatic memory management\n";
    cout << "✅ Single Responsibility: Each class has one clear purpose\n";
    
    printHeader("Demo Complete");
    cout << "🎉 Strategy Pattern implementation successful!\n";
    cout << "📚 Perfect for OOP C++ course project submission!\n\n";

    return 0;
}
