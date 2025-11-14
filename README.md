# Secure Password Manager

A cross-platform password manager built with Flutter and C++, featuring native encryption, cloud backup, and advanced security features.

## OOP Concepts Used in This Project

### Basic OOP Concepts

| Concept | Description | Implementation Location | Example |
|---------|-------------|------------------------|---------|
| **Class** | Blueprint for creating objects with properties and methods | All `.h`/`.cpp` files, `.dart` files | `class PasswordManager { ... }` |
| **Object** | Instance of a class with actual values | Throughout codebase | `PasswordManager manager;` |
| **Attribute/Property** | Data stored in a class (member variables) | `AESEncryptionStrategy.h` | `SecByteBlock key;`, `bool initialized;` |
| **Method/Function** | Behavior/actions a class can perform | All classes | `encrypt()`, `decrypt()`, `savePassword()` |
| **Constructor** | Special method to initialize objects | All classes | `PasswordManager()`, `AuthService()` |
| **Destructor** | Special method to cleanup when object is destroyed | C++ classes | `~AESEncryptionStrategy()` |
| **Access Modifiers** | Control visibility of class members | `private:`, `public:`, `protected:` | `private: SecByteBlock key;` |
| **Encapsulation** | Bundle data and methods; hide internal details | All classes with private members | Private key/IV in `AESEncryptionStrategy` |
| **Abstraction** | Hide complexity; show only essential features | `IEncryptionStrategy.h` | Pure virtual functions (abstract interface) |
| **Inheritance** | Derive new class from existing class | Strategy implementations | `class XOREncryptionStrategy : public IEncryptionStrategy` |
| **Polymorphism** | Same interface, different implementations | Strategy pattern usage | `strategy->encrypt()` behaves differently per strategy |
| **Interface** | Contract defining methods without implementation | `IEncryptionStrategy.h` | Pure virtual functions (`= 0`) |
| **Abstract Class** | Class with at least one pure virtual function | `IEncryptionStrategy` | Cannot be instantiated directly |
| **Concrete Class** | Class that can be instantiated | `AESEncryptionStrategy`, `XOREncryptionStrategy` | Can create objects |
| **Member Variable** | Variable declared inside a class | All classes | `std::vector<PasswordEntry> passwords;` |
| **Member Function** | Function declared inside a class | All classes | `bool addPassword(...)` |
| **Static Member** | Belongs to class, not object | `EncryptionService` | `static SecByteBlock key;` |
| **Virtual Function** | Function that can be overridden in derived class | `IEncryptionStrategy` | `virtual std::string encrypt(...) = 0;` |
| **Override** | Redefine base class function in derived class | All strategy implementations | `std::string encrypt(...) override;` |
| **this Pointer** | Points to current object | Throughout C++ code | `this->key`, `this->initialized` |
| **Namespace** | Organize code into logical groups | C++ files | `using namespace std;`, `CryptoPP::` |
| **Template** | Generic programming with types | STL containers | `std::vector<T>`, `std::unique_ptr<T>` |
| **Pointer** | Variable storing memory address | C++ code | `IEncryptionStrategy* strategy;` |
| **Reference** | Alias for another variable | Function parameters | `const std::string& plainText` |
| **Smart Pointer** | Automatic memory management | `EncryptionContext` | `std::unique_ptr<IEncryptionStrategy>` |

### Advanced OOP Concepts

| Concept | Description | Implementation Location | Example |
|---------|-------------|------------------------|---------|
| **Composition** | Has-a relationship; object contains other objects | `PasswordManager` | `PasswordGenerator generator;` member |
| **Aggregation** | Weak has-a relationship | Service dependencies | Services use but don't own Firebase |
| **Association** | Relationship between classes | Service interactions | `StorageService` uses `FirebaseService` |
| **Multiple Inheritance** | Inherit from multiple base classes | Not used (single inheritance preferred) | N/A |
| **Virtual Destructor** | Ensure proper cleanup in inheritance | `IEncryptionStrategy` | `virtual ~IEncryptionStrategy() = default;` |
| **Pure Virtual Function** | Abstract method that must be implemented | `IEncryptionStrategy` | `virtual std::string encrypt(...) = 0;` |
| **Function Overloading** | Multiple functions with same name, different parameters | Constructor overloads | `PasswordManager()`, `PasswordManager(path)` |
| **Operator Overloading** | Define custom behavior for operators | Not extensively used | Could override `==`, `<<` operators |
| **Friend Function** | Function with access to private members | Not used | `friend void printKey(...)` |
| **Nested Class** | Class defined inside another class | `AuthManager::AuthResult` | Struct inside class |
| **Const Member Function** | Function that doesn't modify object state | Getter methods | `bool isInitialized() const { return initialized; }` |
| **Static Function** | Class-level function, no `this` pointer | `EncryptionService` | `static void initialize();` |
| **Inline Function** | Function definition in class declaration | Header files | `bool hasStrategy() const { return strategy != nullptr; }` |
| **Default Parameters** | Function parameters with default values | Many functions | `generateRandom(int length = 16)` |

### SOLID Principles

| Principle | Description | Implementation | Example |
|-----------|-------------|----------------|---------|
| **Single Responsibility** | Class has one reason to change | Separate classes for each concern | `PasswordGenerator` only generates passwords |
| **Open/Closed** | Open for extension, closed for modification | Strategy pattern | Add new encryption without changing context |
| **Liskov Substitution** | Derived classes substitutable for base | All strategies work with context | Any `IEncryptionStrategy` works in `EncryptionContext` |
| **Interface Segregation** | Small, focused interfaces | Minimal interface design | `IEncryptionStrategy` only has crypto methods |
| **Dependency Inversion** | Depend on abstractions, not concrete classes | Strategy pattern | `EncryptionContext` uses interface, not concrete class |

### Design Patterns

| Pattern | Description | Implementation | Example |
|---------|-------------|----------------|---------|
| **Strategy Pattern** | Encapsulate algorithms, make them interchangeable | Encryption strategies | `IEncryptionStrategy` with AES/XOR/None implementations |
| **Null Object Pattern** | Provide "do nothing" object instead of null | `NoEncryptionStrategy` | Returns plaintext; no null checks needed |
| **Singleton Pattern** | Ensure only one instance exists | Flutter services | `Provider(create: (context) => AppLockService())` |
| **Factory Pattern** | Create objects without specifying exact class | Route builders | `'/login': (context) => const LoginScreen()` |
| **Observer Pattern** | Notify dependents when state changes | `ChangeNotifier` | `AuthService extends ChangeNotifier` |
| **Repository Pattern** | Abstract data access | Firebase service | `savePassword()`, `getPasswords()` |
| **Bridge Pattern** | Separate abstraction from implementation | FFI/JNI bridges | Dart ↔ C++ communication layer |
| **Template Method** | Define algorithm skeleton | PIN verification | Base flow with overridable steps |
| **State Pattern** | Change behavior based on state | App lifecycle | Different behavior per `AppLifecycleState` |
| **RAII Pattern** | Automatic resource management | Smart pointers | `std::unique_ptr` auto-cleanup |
| **Dependency Injection** | Inject dependencies externally | Provider pattern | Services injected into screens |
| **MVC/MVVM** | Separate UI, logic, data | App architecture | Screens (View), Services (Model) |
| **Composite Pattern** | Treat individual/composite objects uniformly | Widget tree | Nested widgets treated uniformly |

## SOLID Principles Applied

| Principle | Implementation | Location |
|-----------|---------------|----------|
| **Single Responsibility Principle (SRP)** | Each class has one job | `PasswordGenerator` only generates; `DatabaseManager` only persists |
| **Open/Closed Principle (OCP)** | Extend without modifying | Add new encryption algorithm without changing `EncryptionContext` |
| **Liskov Substitution Principle (LSP)** | Derived classes substitutable for base | All `IEncryptionStrategy` implementations work interchangeably |
| **Interface Segregation Principle (ISP)** | Small, focused interfaces | `IEncryptionStrategy` has only encryption-related methods |
| **Dependency Inversion Principle (DIP)** | Depend on abstractions | `EncryptionContext` uses `IEncryptionStrategy`, not concrete classes |

## Design Patterns Used

| Pattern | Purpose | Implementation |
|---------|---------|----------------|
| **Strategy Pattern** | Swap algorithms at runtime | `IEncryptionStrategy` interface with AES, XOR, NoEncryption strategies |
| **Null Object Pattern** | Avoid null checks | `NoEncryptionStrategy` provides no-op implementation |
| **Bridge Pattern** | Separate abstraction from platform | FFI and JNI bridges for Dart ↔ C++ communication |
| **Repository Pattern** | Abstract data access | `FirebaseService` hides Firestore implementation details |
| **Singleton Pattern** | One instance per app lifecycle | Services managed by Provider in `main.dart` |
| **Observer Pattern** | Reactive state updates | `ChangeNotifier` services notify UI of changes |
| **Factory Pattern** | Flexible object creation | Route builders, widget factories |

## Project Architecture

### Technology Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Authentication, Firestore, Cloud Storage)
- **Native Layer:** C++ (Crypto++, SQLite)
- **Bridges:** FFI (Flutter ↔ C++), JNI (Android ↔ C++)
- **State Management:** Provider
- **Security:** AES-256-CBC encryption, SHA-256 hashing, Flutter Secure Storage

### Code Distribution

#### C++ Native Core (4 Modules)

**Module 1 - Encryption System (Strategy Pattern)**
- `IEncryptionStrategy.h` - Abstract interface
- `EncryptionContext.h/.cpp` - Strategy context
- `AESEncryptionStrategy.h/.cpp` - AES-256-CBC implementation
- `XOREncryptionStrategy.h/.cpp` - XOR demo (educational)
- `NoEncryptionStrategy.h/.cpp` - Null object
- `Encryption_Service.cpp` - Standalone AES service

**Module 2 - Password Management**
- `PasswordManager.h/.cpp` - CRUD operations
- `PasswordGenerator.h/.cpp` - Password generation algorithms
- `PasswordEntry.h/.cpp` - Data model with strength analysis

**Module 3 - Data Persistence**
- `DatabaseManager.h/.cpp` - SQLite wrapper
- `AuthManager.h/.cpp` - Authentication logic
- `StorageManager.h` - Storage abstraction

**Module 4 - Integration & Demos**
- `JNI_Wrapper.cpp` - Android JNI bridge
- `native_ffi_bridge.cpp` - Flutter FFI bridge
- `strategy_pattern_demo.cpp` - Demo program
- `test_strategy_pattern.cpp` - Unit tests

#### Flutter (4 Modules)

**Module 1 - Core Services & Encryption**
- `encryption_service.dart` - Main encryption orchestrator
- `native_encryption.dart` - FFI bridge to C++
- `storage_service.dart` - Hybrid storage (local + cloud)
- `native_password_service.dart` - JNI bridge to C++

**Module 2 - Firebase & Cloud Sync**
- `firebase_service.dart` - Firestore CRUD, cloud backup
- `auth_service.dart` - Authentication orchestration
- `login_screen.dart` - Login UI
- `setup_screen.dart` - First-time setup wizard

**Module 3 - Security Features**
- `app_lock_service.dart` - Inactivity timeout
- `app_pin_service.dart` - PIN management
- `lock_screen.dart` - Lock UI
- `pin_setup_screen.dart` - PIN creation
- `pin_verification_screen.dart` - PIN entry
- `security_dashboard_screen.dart` - Security settings

**Module 4 - UI Screens & Password Management**
- `main.dart` - App initialization
- `home_screen.dart` - Main dashboard
- `password_list_screen.dart` - Browse passwords
- `add_password_screen.dart` - Create password
- `edit_password_screen.dart` - Edit password
- `password_generator_screen.dart` - Generate passwords
- `debug_screen.dart` - Debug utilities

## Key Features

- **AES-256 Encryption:** All sensitive data encrypted at rest and in transit
- **Cloud Backup:** Encrypted backups to Firebase Firestore
- **Biometric Authentication:** Fingerprint/Face ID support
- **App Lock:** Auto-lock after inactivity with PIN protection
- **Password Generation:** Strong password generator with customizable rules
- **Strength Analysis:** Real-time password strength scoring
- **Cross-Platform:** Android, iOS, Web, Desktop from single codebase
- **Offline Support:** Local caching with cloud sync when online
- **Native Performance:** C++ encryption for speed

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio / Xcode
- Firebase project with Authentication & Firestore enabled
- CMake and NDK (for C++ compilation)

### Setup
1. Clone repository
2. Run `flutter pub get`
3. Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Build: `flutter build apk` or `flutter build ios`

### Run
```bash
flutter run
```

## Security Architecture

### Encryption Flow
```
User Input → Dart AES (or Native C++) → Base64 → Firestore
           ↓
           Flutter Secure Storage (key/IV)
```

### User Scoping
- **userKey** = SHA-256(userId) stored in Firestore
- All queries filtered by `userKey` for isolation
- Plaintext `userId` never stored in cloud

### Data Model
- **Local:** SharedPreferences (encrypted JSON)
- **Cloud:** Firestore documents with encrypted fields
- **Fields Encrypted:** password, username, email, userId, title, website, notes, category

## License
MIT License - see LICENSE file for details
