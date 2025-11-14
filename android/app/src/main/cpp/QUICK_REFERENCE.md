# 🎓 Strategy Pattern - Quick Reference Card

## One-Line Explanation
> "The Strategy Pattern defines a family of interchangeable algorithms and lets clients choose which one to use at runtime."

---

## 📊 Key Classes at a Glance

```cpp
// 1. Interface (Abstract Base Class)
class IEncryptionStrategy {
    virtual string encrypt(string) = 0;  // Pure virtual
    virtual string decrypt(string) = 0;  // Must implement
};

// 2. Concrete Strategies (Implementations)
class AESEncryptionStrategy : public IEncryptionStrategy {
    // Implements encrypt/decrypt with AES-256
};

class XOREncryptionStrategy : public IEncryptionStrategy {
    // Implements encrypt/decrypt with XOR
};

// 3. Context (Uses the Strategy)
class EncryptionContext {
    unique_ptr<IEncryptionStrategy> strategy;  // Composition!
    
    void setStrategy(unique_ptr<...> s) {
        strategy = move(s);  // Runtime switching
    }
};
```

---

## 🎯 OOP Concepts - Quick Answers

### Q: "What is polymorphism?"
**A:** Multiple classes share the same interface but behave differently.
**Example:** `AES.encrypt()` and `XOR.encrypt()` - same method name, different behavior.

### Q: "What is encapsulation?"
**A:** Hiding implementation details, exposing only what's necessary.
**Example:** `AESEncryptionStrategy` keeps keys private, exposes only encrypt/decrypt.

### Q: "What is abstraction?"
**A:** Defining "what" without "how" - interfaces without implementation.
**Example:** `IEncryptionStrategy` defines contract, strategies implement it.

### Q: "What is the Strategy Pattern?"
**A:** Encapsulate algorithms in separate classes, make them interchangeable via a common interface.
**Example:** Switch from AES to XOR without changing client code.

---

## 💡 SOLID Principles - One-Liners

| Principle | What It Means | Our Example |
|-----------|---------------|-------------|
| **S**ingle Responsibility | One class = one job | Each strategy does only encryption |
| **O**pen/Closed | Open for extension, closed for modification | Add new strategies without changing existing code |
| **L**iskov Substitution | Subclass can replace parent | Any strategy can replace another |
| **I**nterface Segregation | No fat interfaces | `IEncryptionStrategy` has only needed methods |
| **D**ependency Inversion | Depend on abstractions | `EncryptionContext` depends on interface, not concrete classes |

---

## 🔄 Runtime Strategy Switching (Demo Script)

```cpp
// Create context
EncryptionContext service;

// Use AES
service.setStrategy(make_unique<AESEncryptionStrategy>());
auto encrypted1 = service.encrypt("test");
cout << "AES: " << encrypted1 << "\n";

// Switch to XOR (at runtime!)
service.setStrategy(make_unique<XOREncryptionStrategy>());
auto encrypted2 = service.encrypt("test");
cout << "XOR: " << encrypted2 << "\n";

// ✅ Different results, same interface!
```

---

## 📈 Benefits of Strategy Pattern (Memorize These!)

1. **Runtime Flexibility** - Change algorithms on the fly
2. **Open/Closed** - Add new strategies without modifying existing code
3. **Testability** - Test each strategy independently
4. **Maintainability** - Changes to one algorithm don't affect others
5. **Clean Code** - No messy if/else chains

---

## 🎬 Demo Talking Points (30 seconds each)

### 1. Show the Interface (10 sec)
"Here's `IEncryptionStrategy` - pure virtual functions define the contract."

### 2. Show Implementations (15 sec)
"Three concrete strategies: AES (production), XOR (demo), None (testing)."

### 3. Show Context (10 sec)
"`EncryptionContext` uses composition - it HAS-A strategy, not IS-A strategy."

### 4. Show Runtime Switching (20 sec)
"Watch - I switch from AES to XOR... different output, same interface!"

### 5. Explain OOP (15 sec)
"This demonstrates polymorphism, encapsulation, and all SOLID principles."

---

## ❓ Likely Questions & Answers

### Q: "Why not just use if/else?"
**A:** 
- If/else violates Open/Closed principle
- Hard to test each algorithm separately
- Messy code with many algorithms
- Can't switch algorithms at runtime easily

### Q: "What's the difference between Strategy and inheritance?"
**A:**
- Strategy uses COMPOSITION (has-a), not inheritance (is-a)
- Strategy makes algorithms first-class objects
- Strategy allows runtime switching

### Q: "Can you add a new strategy without changing existing code?"
**A:** YES! Just create a new class implementing `IEncryptionStrategy`. No changes to context or other strategies. (Open/Closed Principle!)

### Q: "What C++ features did you use?"
**A:**
- Virtual functions (polymorphism)
- Pure virtual (abstract interface)
- Smart pointers (RAII, memory safety)
- Move semantics (efficiency)
- Override keyword (clarity)

---

## 🧪 Testing Proof (Quick Demo)

```cpp
// Test 1: Roundtrip
auto encrypted = strategy->encrypt("test");
auto decrypted = strategy->decrypt(encrypted);
assert(decrypted == "test"); // ✅

// Test 2: Polymorphism
IEncryptionStrategy* s1 = new AESEncryptionStrategy();
IEncryptionStrategy* s2 = new XOREncryptionStrategy();
// Both work through same interface! ✅

// Test 3: Strategy Switching
context.setStrategy(make_unique<AES>());
auto r1 = context.encrypt("x");
context.setStrategy(make_unique<XOR>());
auto r2 = context.encrypt("x");
assert(r1 != r2); // Different algorithms! ✅
```

---

## 🏆 Why This Is Strong for Course Project

✅ **Advanced Pattern** - Strategy is a core GoF pattern  
✅ **Real-World Use** - Encryption is practical and relevant  
✅ **All OOP Concepts** - Demonstrates every major principle  
✅ **SOLID Compliant** - Follows all 5 principles  
✅ **Modern C++** - Uses C++17 features properly  
✅ **Well-Documented** - Comments explain "why" not just "what"  
✅ **Extensible** - Easy to add more strategies  
✅ **Testable** - Each component can be tested independently  

---

## 🎤 30-Second Elevator Pitch

> "I implemented the Strategy Pattern to make encryption algorithms interchangeable in my password manager. It demonstrates polymorphism through virtual functions, encapsulation with private key management, and follows all SOLID principles. I can switch between AES, XOR, or no encryption at runtime without changing any client code. This shows how design patterns create flexible, maintainable systems."

---

## 📱 Files to Have Open During Presentation

1. `IEncryptionStrategy.h` - Show the interface
2. `AESEncryptionStrategy.h` - Show concrete implementation
3. `EncryptionContext.h` - Show composition
4. `strategy_pattern_demo.cpp` - Run the demo
5. `SUBMISSION_SUMMARY.md` - Reference diagrams

---

**Print this card and keep it with you during presentation!**  
**Good luck! 🍀**
