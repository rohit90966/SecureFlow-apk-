cmake_minimum_required(VERSION 3.18.1)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find log library
find_library(log-lib log)

# Add Crypto++ library path (if using encryption strategies)
# Note: If AES/Crypto++ files cause linker errors, comment out the AES files below
# and ensure Crypto++ is properly installed/linked

# Add your native library
add_library(
        passwordcore
        SHARED
        # Main bridges
        # JNI_Wrapper.cpp                # Commented - uses PasswordManager (not used, we use FFI)
        native_ffi_bridge.cpp            # FFI bridge for Dart (USED)
        
        # Core business logic
        # core/PasswordManager.cpp       # Commented - requires SQLite3
        core/PasswordGenerator.cpp
        core/AuthManager.cpp
        # core/DatabaseManager.cpp       # Commented - requires SQLite3
        
        # Encryption strategies (Strategy Pattern)
        # core/EncryptionContext.cpp     # Commented - has inline definitions in header
        # core/XOREncryptionStrategy.cpp # Commented - not needed for production
        # core/NoEncryptionStrategy.cpp  # Commented - not needed for production
        core/SimpleAES.cpp              # Standalone AES-256 implementation (MAIN ENCRYPTION)
        # core/AESEncryptionStrategy.cpp  # Commented out - requires Crypto++ library
        # core/Encryption_Service.cpp     # Commented out - requires Crypto++ library
        
        # Models
        models/PasswordEntry.cpp
)

# Include directories
include_directories(core models)

# Link libraries
target_link_libraries(passwordcore ${log-lib})

# If using Crypto++ for AES encryption, uncomment below and ensure library is available:
# find_library(cryptopp-lib cryptopp)
# target_link_libraries(passwordcore ${cryptopp-lib})