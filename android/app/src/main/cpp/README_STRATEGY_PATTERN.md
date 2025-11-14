# Strategy Pattern for Encryption - OOP C++ Implementation

## 📚 Project Overview
This implementation demonstrates the **Strategy Pattern** (a core Gang of Four design pattern) applied to encryption algorithms. Perfect for an OOP C++ course project!

## 🎯 OOP Concepts Demonstrated

### 1. **Polymorphism** ⭐⭐⭐
- Single interface (`IEncryptionStrategy`) with multiple implementations
- Runtime algorithm selection without changing client code
- Virtual functions enable dynamic dispatch

### 2. **Encapsulation** ⭐⭐⭐
- Private members hide implementation details
- Public interfaces expose only necessary functionality
- Each strategy manages its own keys/state

### 3. **Abstraction** ⭐⭐⭐
- Abstract base class defines contract
- Clients work with interface, not concrete implementations
- Implementation details hidden behind clean API

### 4. **Strategy Pattern** ⭐⭐⭐ (GoF Design Pattern)
- Defines family of algorithms
- Encapsulates each one
- Makes them interchangeable at runtime

### 5. **SOLID Principles**
- **S**ingle Responsibility: Each class has one job
- **O**pen/Closed: Open for extension (new strategies), closed for modification
- **L**iskov Substitution: Any strategy can replace another
- **I**nterface Segregation: Clean, focused interfaces
- **D**ependency Inversion: Context depends on abstraction, not concrete classes

### 6. **Modern C++ Features**
- Smart pointers (`std::unique_ptr`) for RAII
- Move semantics for efficiency
- `= default` and `= delete` for special members
- `override` and `final` keywords

## 📂 File Structure

```
android/app/src/main/cpp/
├── core/
│   ├── IEncryptionStrategy.h          # Abstract interface
│   ├── AESEncryptionStrategy.h/cpp    # AES-256-CBC implementation
│   ├── XOREncryptionStrategy.h/cpp    # XOR implementation (demo)
│   ├── NoEncryptionStrategy.h/cpp     # Null Object Pattern
│   ├── EncryptionContext.h/cpp        # Context (uses strategy)
│   └── ...
├── strategy_pattern_demo.cpp          # Demo program
└── README_STRATEGY_PATTERN.md         # This file
```

## 🔧 Class Diagram (UML-style)

```
┌─────────────────────────┐
│  IEncryptionStrategy    │ (Abstract)
├─────────────────────────┤
│ + encrypt()   : string  │ (pure virtual)
│ + decrypt()   : string  │ (pure virtual)
│ + getAlgorithmName()    │
│ + requiresInit() : bool │
└───────────┬─────────────┘
            │
      ┌─────┴──────┬──────────────┬───────────────┐
      │            │              │               │
┌─────▼─────┐ ┌───▼────┐  ┌──────▼─────┐  ┌─────▼──────┐
│    AES    │ │  XOR   │  │  NoEncrypt │  │ (Future)   │
│ Strategy  │ │Strategy│  │  Strategy  │  │ ChaCha20   │
└───────────┘ └────────┘  └────────────┘  └────────────┘

┌─────────────────────────┐
│  EncryptionContext      │
├─────────────────────────┤
│ - strategy: unique_ptr  │
├─────────────────────────┤
│ + setStrategy()         │
│ + encrypt()             │
│ + decrypt()             │
└─────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- C++17 or later
- Crypto++ library (for AES implementation)
- CMake 3.10+ (optional, for easy building)

### Build and Run

#### Option 1: Manual Compilation
```bash
# Compile (simple XOR/NoEncrypt only)
g++ -std=c++17 -o strategy_demo \
    strategy_pattern_demo.cpp \
    core/EncryptionContext.cpp \
    core/XOREncryptionStrategy.cpp \
    core/NoEncryptionStrategy.cpp

# Run
./strategy_demo
```

#### Option 2: With AES (requires Crypto++)
```bash
# Install Crypto++ (Ubuntu/Debian)
sudo apt-get install libcrypto++-dev

# Compile with all strategies
g++ -std=c++17 -o strategy_demo \
    strategy_pattern_demo.cpp \
    core/EncryptionContext.cpp \
    core/AESEncryptionStrategy.cpp \
    core/XOREncryptionStrategy.cpp \
    core/NoEncryptionStrategy.cpp \
    -lcryptopp

# Run
./strategy_demo
```

## 📖 Usage Examples

### Example 1: Basic Usage
```cpp
#include "core/EncryptionContext.h"
#include "core/AESEncryptionStrategy.h"

int main() {
    // Create context with AES strategy
    EncryptionContext service;
    service.setStrategy(std::make_unique<AESEncryptionStrategy>());
    
    // Use it
    std::string encrypted = service.encrypt("secret");
    std::string decrypted = service.decrypt(encrypted);
    
    return 0;
}
```

### Example 2: Runtime Strategy Switching
```cpp
EncryptionContext service;

// Start with AES
service.setStrategy(std::make_unique<AESEncryptionStrategy>());
auto aesResult = service.encrypt("data");

// Switch to XOR for testing
service.setStrategy(std::make_unique<XOREncryptionStrategy>("key"));
auto xorResult = service.encrypt("data");

// Both work through same interface!
```

### Example 3: Adding a New Strategy
```cpp
// 1. Create new strategy class
class MyCustomStrategy : public IEncryptionStrategy {
public:
    std::string encrypt(const std::string& plain) override {
        // Your algorithm here
    }
    std::string decrypt(const std::string& cipher) override {
        // Your algorithm here
    }
    // ... implement other methods
};

// 2. Use it (no changes to existing code!)
context.setStrategy(std::make_unique<MyCustomStrategy>());
```

## 🎓 For Course Project Submission

### What to Include in Your Report

1. **Class Diagram** (see above)
2. **OOP Concepts Table**:
   | Concept | Where Used | Example |
   |---------|-----------|---------|
   | Polymorphism | IEncryptionStrategy | Multiple implementations |
   | Encapsulation | AESEncryptionStrategy | Private key members |
   | Strategy Pattern | EncryptionContext | Swappable algorithms |
   | SOLID | All classes | Each follows SOLID principles |

3. **Code Walkthrough**:
   - Explain how `IEncryptionStrategy` defines the interface
   - Show how `EncryptionContext` uses composition
   - Demonstrate runtime strategy switching

4. **Demo Video**:
   - Run `strategy_pattern_demo` program
   - Show output for all three strategies
   - Explain what's happening at each step

### Talking Points for Presentation

**Q: What is the Strategy Pattern?**
> A: It's a behavioral design pattern that defines a family of algorithms, encapsulates each one, and makes them interchangeable. Clients can choose algorithms at runtime without changing their code.

**Q: Why is this better than if/else statements?**
> A: 
> - **Open/Closed Principle**: Can add new strategies without modifying existing code
> - **Testability**: Each strategy can be tested independently
> - **Maintainability**: Changes to one algorithm don't affect others
> - **Flexibility**: Can switch algorithms at runtime

**Q: What OOP principles does this demonstrate?**
> A: Polymorphism (interface + implementations), Encapsulation (private members), Abstraction (clean interfaces), Composition (EncryptionContext has-a Strategy), and all SOLID principles.

## 🔍 Testing & Validation

### Unit Test Ideas
1. Test each strategy individually (encrypt/decrypt roundtrip)
2. Test strategy switching (different results from different algorithms)
3. Test error handling (decrypt with wrong key, null strategy)
4. Test edge cases (empty string, very long string, special characters)

### Example Test
```cpp
void testAESRoundtrip() {
    AESEncryptionStrategy aes;
    aes.initialize();
    
    std::string original = "test data";
    std::string encrypted = aes.encrypt(original);
    std::string decrypted = aes.decrypt(encrypted);
    
    assert(decrypted == original); // Should pass
}
```

## 🌟 Extension Ideas

1. **Add More Strategies**:
   - ChaCha20 encryption
   - RSA public-key encryption
   - Blowfish cipher

2. **Add Features**:
   - Strategy factory (create strategies by name)
   - Performance benchmarking
   - Key rotation support
   - Compression before encryption

3. **Add Patterns**:
   - **Factory Pattern**: `EncryptionStrategyFactory::create("AES")`
   - **Decorator Pattern**: Add compression/base64 as decorators
   - **Observer Pattern**: Notify when strategy changes

## 📝 Grading Rubric Checklist

- [x] Abstract base class with pure virtual functions
- [x] At least 3 concrete implementations
- [x] Polymorphism demonstrated (virtual functions)
- [x] Encapsulation (private members, public interface)
- [x] SOLID principles followed
- [x] Smart pointers used (RAII)
- [x] Comprehensive comments/documentation
- [x] Working demo program
- [x] Exception handling
- [x] README with diagrams

## 🎉 Benefits for Your Project

1. **Strong OOP Foundation**: Demonstrates core principles clearly
2. **Real-World Application**: Encryption is practical and relevant
3. **Extensible**: Easy to add more strategies later
4. **Well-Documented**: Comments explain "why" not just "what"
5. **Professional Quality**: Production-ready code structure
6. **Easy to Present**: Clear, visual, easy to explain

## 📚 References

- **Design Patterns** by Gang of Four (GoF)
- **Effective Modern C++** by Scott Meyers
- **C++ Core Guidelines** by Bjarne Stroustrup

---

**Created for OOP C++ Course Project**  
Demonstrates: Strategy Pattern, SOLID Principles, Modern C++, Clean Code
