cmake_minimum_required(VERSION 3.18.1)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find log library
find_library(log-lib log)

# Add your native library
add_library(
        passwordcore
        SHARED
        JNI_Wrapper.cpp
        core/PasswordManager.cpp
        core/PasswordGenerator.cpp
        models/PasswordEntry.cpp
        native_ffi_bridge.cpp
)

# Include directories
include_directories(core models)

# Link libraries
target_link_libraries(passwordcore ${log-lib})