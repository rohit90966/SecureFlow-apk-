# C++ Encryption Module – OOP Concepts & Syllabus Mapping

## 1. Purpose & Scope
This document explains how the native C++ encryption layer in this project works and maps each applied Object-Oriented Programming (OOP) concept to your syllabus units (Units 1–6). It covers design patterns, class responsibilities, encryption flow (AES‑256 CBC & educational XOR), file handling for key persistence, exception handling, and SOLID principles.

## 2. Core Files
| File | Role | Key Concepts |
|------|------|-------------|
| `core/IEncryptionStrategy.h` | Base interface + exception hierarchy | Abstraction, Polymorphism, Inheritance, Exception classes |
| `core/AESEncryptionStrategy.h/.cpp` | AES‑256 CBC strategy using Crypto++ | Encapsulation, RAII, File handling, Dynamic binding |
| `core/XOREncryptionStrategy.h/.cpp` | Simple XOR educational strategy | Strategy pattern, Polymorphism |
| `core/EncryptionContext.h` | Context that holds current strategy | Strategy pattern, Dependency Inversion, Encapsulation |
| `core/SimpleAES.h/.cpp` | Manual AES‑256 CBC (custom implementation) | Encapsulation, Algorithm-level abstraction |
| `native_ffi_bridge.cpp` | FFI bridge to Dart; key derivation (PBKDF2-like) | Interop, Encapsulation, Deterministic key derivation |
| `core/AESEncryptionStrategy.cpp` | File-backed key lifecycle | Resource management (RAII), Exception handling |

## 3. High-Level Architecture (Strategy Pattern)
```
+----------------------+         +---------------------------+
| EncryptionContext    | uses -> | IEncryptionStrategy       |
|  - setStrategy()     |         |  + encrypt() (virtual)    |
|  - encrypt()/decrypt |         |  + decrypt() (virtual)    |
+----------------------+         +-------------+-------------+
                                          ^           ^
                                          |           |
                                +----------------+  +-------------------------+
                                | XOREncryption  |  | AESEncryptionStrategy   |
                                +----------------+  +-------------------------+
```
`EncryptionContext` accepts any object implementing `IEncryptionStrategy`. Calls are dispatched via virtual methods (dynamic binding → runtime polymorphism).

## 4. Encryption Flow Overview
### AES (Crypto++ based – `AESEncryptionStrategy`)
1. On first use `initialize()` loads keys from files; if absent generates new ones.
2. Plaintext is passed to `encrypt()` → CBC_Mode<AES>::Encryption → Base64.
3. Decryption reverses: Base64 decode → CBC_Mode<AES>::Decryption → plaintext.
4. Keys stored in `aes_key.bin`, IV in `aes_iv.bin` (file handling).

### Manual AES (`SimpleAES`)
1. Implements AES‑256 CBC manually: key expansion, 14 rounds (AES‑256), S-box, MixColumns, PKCS7 padding.
2. Each 16‑byte block XOR’d with previous cipher block (CBC chaining).
3. Output encoded to Base64 for transmission/storage.

### XOR Strategy (Educational)
1. Each byte XOR’d with repeating key bytes.
2. Encrypted result converted to hex for readability.
3. Symmetric: same function reverses with same key.

### Key Derivation (`native_ffi_bridge.cpp`)
1. User password + app-based salt → iterative transform (simplified PBKDF2-like loop with 100k iterations).
2. Derived 48 bytes split: first 32 → AES key, next 16 → IV.
3. Ensures cross-device consistency (same password → same key across devices).

## 5. Detailed OOP Concept Mapping
### Unit 1: Fundamentals
| Concept | Where Used | Explanation |
|---------|------------|-------------|
| Objects/Classes | All strategy classes (e.g., `AESEncryptionStrategy`) | Encapsulate encryption behavior and state (key, IV, init flag). |
| Data Members | `key`, `iv`, `initialized` in AES strategy; S‑boxes in `SimpleAES.cpp` | Hold algorithm configuration & persistent state. |
| Methods | `encrypt`, `decrypt`, `initialize`, `clearKeys` | Define operations users can perform. |
| Encapsulation | Private helper methods: `loadKeysFromFile()`, `generateNewKeys()` | Hide complexity; only public API exposed. |
| Abstraction | `IEncryptionStrategy` interface | Users interact with common encryption API, not concrete details. |
| Information Hiding | Key/IV never exposed publicly; file operations internal | Prevent accidental leakage. |
| Inheritance | `AESEncryptionStrategy`, `XOREncryptionStrategy` inherit from `IEncryptionStrategy` | Share common contract; override specifics. |
| Polymorphism | Virtual methods called via `EncryptionContext` | Runtime dispatch chooses appropriate algorithm. |
| Static Binding | Non-virtual helpers (e.g., `gf_mul` in `SimpleAES.cpp`) | Resolved at compile time for efficiency. |
| Dynamic Binding | `encrypt()` / `decrypt()` virtual calls | Decide algorithm at runtime. |
| Message Passing | `context.encrypt("secret")` forwards request to strategy | Object-to-object collaboration pattern. |

### Unit 2: Classes and Objects
| Concept | Example |
|---------|---------|
| Visibility Modifiers | `private` vs `public` sections in headers control access. |
| `this` keyword | Implicit in member access (e.g., `initialized` in methods). |
| Method Overloading | Not significantly used (same name, different params absent) – Could add future overload `encrypt(const uint8_t* buffer, size_t len)`. |
| Passing Objects | `EncryptionContext(std::unique_ptr<IEncryptionStrategy>)` passes ownership of strategy object. |
| Returning Objects | `generateRandomBytes()` returns `std::vector<uint8_t>` (value semantics). |
| Static Members | Not used; could enhance by adding static factory (e.g., `AESEncryptionStrategy::WithTempKey()`). |
| Memory Allocation | `new SimpleAES(...)` and `std::unique_ptr` (heap allocation). |
| Memory Recovery | RAII: destructors + `unique_ptr` auto free; explicit `delete g_aes` in FFI bridge. |
| Array of Objects | Vectors of bytes (`std::vector<uint8_t>`) act as dynamic arrays. |

### Unit 3: Constructors & Destructors
| Concept | Example |
|---------|---------|
| Constructor Use | `AESEncryptionStrategy(...)` stores file paths; `SimpleAES(key, iv)` validates sizes. |
| Characteristics | No implicit default state beyond parameter validation. |
| Overloading | Multiple constructors via default parameters (single signature using defaults). |
| Dynamic Initialization | Keys loaded or generated inside `initialize()` separate from constructor (two-phase init). |
| Default Arguments | Provided in `AESEncryptionStrategy` for file paths. |
| Destructor | `~AESEncryptionStrategy()` marks state invalid; SimpleAES relies on vector cleanup. |

### Unit 4: Inheritance & Polymorphism
| Concept | Example |
|---------|---------|
| Need of Inheritance | Common interface so context can switch algorithms seamlessly. |
| Type | Single inheritance (each concrete strategy inherits one interface). |
| Benefits | Extensibility (add `ChaCha20Strategy` without modifying context). |
| Cost | Extra virtual dispatch overhead (minimal). |
| Method Overriding | `encrypt()` / `decrypt()` / `getAlgorithmName()` overridden per strategy. |
| Abstract Classes | `IEncryptionStrategy` (pure virtual methods). |
| Interfaces | Same as abstract base class here. |
| Compile-Time Polymorphism | Template use in STL (e.g., `std::vector<uint8_t>`). |
| Run-Time Polymorphism | Virtual methods invoked through base pointer in `EncryptionContext`. |
| Friend Function | Not used; design aims to keep encapsulation intact. |

### Unit 5: File Handling
| Concept | Where |
|---------|------|
| Opening/Closing Files | Key/IV persistence in `AESEncryptionStrategy::loadKeysFromFile()` / `saveKeysToFile()` using `std::ifstream` / `std::ofstream`. |
| File Modes | Binary mode (`std::ios::binary`) for raw key bytes. |
| Sequential I/O | Raw read/write operations for keys. |
| Error Handling | Validations; if read counts mismatch treat file as corrupted → regenerate keys. |
| Pointers/Manipulators | Basic stream usage; no advanced manipulators, but `gcount()` for validation. |

### Unit 6: Exception Handling, Generic Programming, SOLID
| Concept | Example |
|---------|---------|
| Custom Exceptions | `EncryptionException`, `KeyManagementException`, `AlgorithmException`. |
| Throw/Catch | `encrypt()` / `decrypt()` wrap Crypto++ and manual AES operations in try/catch blocks. |
| Uncaught Exception | Propagated up to Dart FFI if not handled. |
| Multiple Catch | FFI layer uses general `std::exception` catch; could extend. |
| Nested Try | Not prominently used; structure kept simple. |
| Generics | STL templates (`std::vector<uint8_t>`, `std::unique_ptr<IEncryptionStrategy>`). |
| SOLID – Single Responsibility | Each strategy class handles exactly one algorithm. |
| SOLID – Open/Closed | Add new strategies without modifying existing ones. |
| SOLID – Liskov Substitution | Any derived strategy can replace base without breaking context logic. |
| SOLID – Interface Segregation | Common interface is minimal (encrypt/decrypt/initialize). |
| SOLID – Dependency Inversion | `EncryptionContext` depends on abstraction (`IEncryptionStrategy`), not concretes. |
| Dependency Injection | Strategy passed into context constructor or `setStrategy()`. |

## 6. Design Patterns Used
| Pattern | Where | Benefit |
|---------|-------|--------|
| Strategy | `IEncryptionStrategy` + concrete implementations + `EncryptionContext` | Swap algorithms at runtime; promotes open/closed design. |
| RAII | Destructors + `std::unique_ptr` | Automatic memory & resource cleanup. |
| Adapter / Bridge (FFI) | `native_ffi_bridge.cpp` functions | Expose C++ class functionality to Dart via C ABI. |

## 7. Security Considerations
| Topic | Notes |
|-------|-------|
| AES-256-CBC | Secure when used with random key + IV and proper padding. |
| Custom SimpleAES | Educational; correct structure but manual crypto is risky (side-channel, maintenance). Prefer battle-tested libraries. |
| XOR Strategy | Weak; for demonstration only. Should never protect real secrets. |
| Key Derivation | Simplified PBKDF2-like loop; Production should use proper PBKDF2/HKDF (e.g., OpenSSL / CryptoPP functions). |
| File Keys | Rotatable via `clearKeys()` / `reset` logic; consider secure wiping & OS keystore integration. |

## 8. Missing / Optional Syllabus Concepts
| Concept | Status | Possible Enhancement |
|---------|--------|---------------------|
| Method Overloading | Minimal | Add overload `encrypt(const std::vector<uint8_t>&)` |
| Friend Function | Not used | Could create diagnostic friend for testing key internals |
| Multiple Inheritance | Not applied | Unnecessary; would add complexity |
| Templates (Custom) | Only STL used | Could template a buffer encryptor class |
| Exception Hierarchy Depth | Shallow | Add per-algorithm specialized exception types |

## 9. Example Usage Snippet (Strategy Switch)
```cpp
#include "core/EncryptionContext.h"
#include "core/AESEncryptionStrategy.h"
#include "core/XOREncryptionStrategy.h"

EncryptionContext ctx(std::make_unique<AESEncryptionStrategy>("aes_key.bin","aes_iv.bin"));
std::string cipher = ctx.encrypt("MySecret123");
std::string plain = ctx.decrypt(cipher); // AES

ctx.setStrategy(std::make_unique<XOREncryptionStrategy>("LiteKey"));
std::string xorCipher = ctx.encrypt("MySecret123");
std::string xorPlain  = ctx.decrypt(xorCipher); // XOR
```
Demonstrates: dynamic binding, runtime strategy replacement (Open/Closed principle), polymorphism.

## 10. Execution Path (Native FFI)
1. Dart calls `cpp_set_user_password(password)`.
2. Bridge derives deterministic key+IV → initializes `SimpleAES`.
3. Dart calls `cpp_encrypt_aes(plain)` → returns Base64 ciphertext.
4. Decryption uses same derived key on any device → cross-device restore.

## 11. Error & Exception Flow
- Strategy validation via `validate()` checks initialization and key strength.
- Crypto failures throw `std::runtime_error` → wrapped or propagated to caller.
- FFI layer prints errors to stdout/stderr for debugging.

## 12. Mapping Summary Table
| Syllabus Unit | Implemented Elements |
|---------------|----------------------|
| Unit 1 | Classes, objects, abstraction, encapsulation, inheritance, polymorphism, dynamic binding |
| Unit 2 | Constructors, visibility, passing/returning objects, memory management, arrays (vectors) |
| Unit 3 | Constructors/destructors, dynamic initialization, default parameters |
| Unit 4 | Inheritance, method overriding, runtime polymorphism, abstract interfaces |
| Unit 5 | File I/O for key persistence (binary mode), error handling |
| Unit 6 | Custom exceptions, try/catch, STL generics, SOLID principles |

## 13. Suggested Improvements
| Improvement | Rationale |
|-------------|-----------|
| Replace manual AES with vetted library only | Reduce maintenance risk, improve security assurance |
| Use proper PBKDF2/HKDF | Strengthen key derivation + resistance to brute-force |
| Secure erase of key material | Defense-in-depth against memory scraping |
| Add unit tests around encryption/decryption | Detect regressions early |
| Add timing-safe comparisons for key validity | Mitigate side-channel risk |

## 14. Quick Glossary
| Term | Meaning |
|------|---------|
| CBC Mode | Cipher Block Chaining – each block XOR with previous ciphertext block |
| PKCS7 Padding | Standard padding to fill last block to 16 bytes |
| Base64 | ASCII encoding of binary data for storage/transmission |
| RAII | Resource Acquisition Is Initialization – deterministic cleanup via scope |
| Strategy Pattern | Behavioral pattern to swap algorithm implementations dynamically |

## 15. Final Notes
- The C++ layer demonstrates multiple syllabus concepts compactly.
- For production, keep AES via Crypto++ and retire manual `SimpleAES` implementation.
- Deterministic user password derived keys enable cross-device backup reliability.

---
**Document Location:** `docs/CPP_ENCRYPTION_OOP.md`
