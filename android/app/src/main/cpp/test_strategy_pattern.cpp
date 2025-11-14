#include <iostream>
#include <cassert>
#include <string>
#include <memory>
#include "core/EncryptionContext.h"
#include "core/XOREncryptionStrategy.h"
#include "core/NoEncryptionStrategy.h"

// AES requires Crypto++ library - uncomment if available:
// #include "core/AESEncryptionStrategy.h"

using namespace std;

/**
 * @brief Unit tests for Strategy Pattern implementation
 * 
 * Run this to verify your implementation before submission!
 */

int passCount = 0;
int failCount = 0;

void test(const string& name, bool condition) {
    if (condition) {
        cout << "✅ PASS: " << name << "\n";
        passCount++;
    } else {
        cout << "❌ FAIL: " << name << "\n";
        failCount++;
    }
}

void testXORStrategy() {
    cout << "\n=== Testing XOR Strategy ===\n";
    
    XOREncryptionStrategy xorStrategy("TestKey123");
    
    // Test 1: Basic encryption
    string plain = "Hello World";
    string encrypted = xorStrategy.encrypt(plain);
    test("XOR encryption produces output", !encrypted.empty());
    test("XOR encrypted != plaintext", encrypted != plain);
    
    // Test 2: Decryption roundtrip
    string decrypted = xorStrategy.decrypt(encrypted);
    test("XOR decrypt(encrypt(x)) == x", decrypted == plain);
    
    // Test 3: Empty string
    test("XOR handles empty string", xorStrategy.encrypt("") == "");
    
    // Test 4: Algorithm name
    test("XOR algorithm name set", !xorStrategy.getAlgorithmName().empty());
    
    // Test 5: No initialization required
    test("XOR doesn't require init", !xorStrategy.requiresInitialization());
}

void testNoEncryptionStrategy() {
    cout << "\n=== Testing No Encryption Strategy ===\n";
    
    NoEncryptionStrategy noEnc;
    
    // Test 1: Passthrough
    string text = "Plaintext";
    test("NoEncrypt passthrough works", noEnc.encrypt(text) == text);
    test("NoEncrypt decrypt = encrypt", noEnc.decrypt(text) == text);
    
    // Test 2: Algorithm name
    test("NoEncrypt has name", !noEnc.getAlgorithmName().empty());
    
    // Test 3: No key strength
    test("NoEncrypt key strength is 0", noEnc.getKeyStrength() == 0);
}

void testEncryptionContext() {
    cout << "\n=== Testing Encryption Context ===\n";
    
    EncryptionContext context;
    
    // Test 1: Initially no strategy
    test("Context starts empty", !context.hasStrategy());
    
    // Test 2: Set XOR strategy
    context.setStrategy(make_unique<XOREncryptionStrategy>("key"));
    test("Context has strategy after set", context.hasStrategy());
    
    // Test 3: Use strategy
    string plain = "Test Data";
    string encrypted = context.encrypt(plain);
    string decrypted = context.decrypt(encrypted);
    test("Context encryption works", decrypted == plain);
    
    // Test 4: Get algorithm info
    test("Context provides algorithm info", !context.getAlgorithmInfo().empty());
}

void testStrategyPolymorphism() {
    cout << "\n=== Testing Polymorphism ===\n";
    
    // Test 1: Interface pointers work
    IEncryptionStrategy* strategy1 = new XOREncryptionStrategy("key1");
    IEncryptionStrategy* strategy2 = new NoEncryptionStrategy();
    
    string plain = "Polymorphism Test";
    
    string enc1 = strategy1->encrypt(plain);
    string enc2 = strategy2->encrypt(plain);
    
    test("Polymorphism: different strategies work through interface",
         enc1 != enc2);
    
    delete strategy1;
    delete strategy2;
}

void testStrategySwitching() {
    cout << "\n=== Testing Strategy Switching ===\n";
    
    EncryptionContext context;
    string testData = "Switch Test";
    
    // Use XOR
    context.setStrategy(make_unique<XOREncryptionStrategy>("key1"));
    string xorResult = context.encrypt(testData);
    
    // Switch to NoEncrypt
    context.setStrategy(make_unique<NoEncryptionStrategy>());
    string noEncResult = context.encrypt(testData);
    
    test("Strategy switching: different results", xorResult != noEncResult);
    test("NoEncrypt returns plaintext", noEncResult == testData);
}

void testEdgeCases() {
    cout << "\n=== Testing Edge Cases ===\n";
    
    XOREncryptionStrategy xorStrategy("key");
    
    // Test 1: Empty string
    test("Empty string roundtrip", 
         xorStrategy.decrypt(xorStrategy.encrypt("")) == "");
    
    // Test 2: Special characters
    string special = "!@#$%^&*()_+-=[]{}|;':\"<>?,./ ";
    test("Special characters roundtrip",
         xorStrategy.decrypt(xorStrategy.encrypt(special)) == special);
    
    // Test 3: Long string
    string longStr(10000, 'x');
    test("Long string roundtrip",
         xorStrategy.decrypt(xorStrategy.encrypt(longStr)) == longStr);
    
    // Test 4: Unicode (basic)
    string unicode = "Hello 世界 🔐";
    test("Unicode roundtrip",
         xorStrategy.decrypt(xorStrategy.encrypt(unicode)) == unicode);
}

void testErrorHandling() {
    cout << "\n=== Testing Error Handling ===\n";
    
    EncryptionContext context;
    
    // Test 1: Using context without strategy
    bool caughtException = false;
    try {
        context.encrypt("test");
    } catch (const runtime_error&) {
        caughtException = true;
    }
    test("Context throws without strategy", caughtException);
}

int main() {
    cout << "╔════════════════════════════════════════════════╗\n";
    cout << "║  Strategy Pattern - Unit Tests                ║\n";
    cout << "║  Run before submission to verify correctness  ║\n";
    cout << "╚════════════════════════════════════════════════╝\n";
    
    testXORStrategy();
    testNoEncryptionStrategy();
    testEncryptionContext();
    testStrategyPolymorphism();
    testStrategySwitching();
    testEdgeCases();
    testErrorHandling();
    
    // Summary
    cout << "\n╔════════════════════════════════════════════════╗\n";
    cout << "║  Test Summary                                  ║\n";
    cout << "╠════════════════════════════════════════════════╣\n";
    cout << "║  Total Tests: " << (passCount + failCount) << "\n";
    cout << "║  ✅ Passed: " << passCount << "\n";
    cout << "║  ❌ Failed: " << failCount << "\n";
    cout << "╚════════════════════════════════════════════════╝\n";
    
    if (failCount == 0) {
        cout << "\n🎉 All tests passed! Ready for submission! 🎉\n";
        return 0;
    } else {
        cout << "\n⚠️  Some tests failed. Please fix before submitting.\n";
        return 1;
    }
}
