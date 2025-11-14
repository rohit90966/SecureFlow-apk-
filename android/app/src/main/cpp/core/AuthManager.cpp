#include "AuthManager.h"
#include <iostream>
#include <regex>
#include <chrono>
#include <random>

AuthManager::AuthManager()
        : currentUserEmail(""), currentUserId(""), isAuthenticated(false) {
}

AuthManager::AuthResult AuthManager::registerUser(const std::string& email, const std::string& password) {
    AuthResult result;

    // Validate inputs
    if (!isEmailValid(email)) {
        result.success = false;
        result.message = "Invalid email format";
        return result;
    }

    if (!validatePasswordStrength(password)) {
        result.success = false;
        result.message = "Password is too weak. Use at least 8 characters with mix of letters, numbers, and symbols";
        return result;
    }

    // Generate user ID
    currentUserId = generateUserId();
    currentUserEmail = email;
    isAuthenticated = true;

    result.success = true;
    result.message = "Registration successful";
    result.userId = currentUserId;

    std::cout << "User registered: " << email << " (ID: " << currentUserId << ")" << std::endl;

    return result;
}

AuthManager::AuthResult AuthManager::loginUser(const std::string& email, const std::string& password) {
    AuthResult result;

    if (!isEmailValid(email)) {
        result.success = false;
        result.message = "Invalid email format";
        return result;
    }

    if (password.empty()) {
        result.success = false;
        result.message = "Password cannot be empty";
        return result;
    }

    // In real app, this would validate against database
    // For now, we'll simulate successful login
    currentUserId = generateUserId();
    currentUserEmail = email;
    isAuthenticated = true;

    result.success = true;
    result.message = "Login successful";
    result.userId = currentUserId;

    std::cout << "User logged in: " << email << " (ID: " << currentUserId << ")" << std::endl;

    return result;
}

bool AuthManager::logoutUser() {
    currentUserEmail = "";
    currentUserId = "";
    isAuthenticated = false;
    std::cout << "User logged out" << std::endl;
    return true;
}

bool AuthManager::isLoggedIn() const {
    return isAuthenticated;
}

std::string AuthManager::getCurrentUserEmail() const {
    return currentUserEmail;
}

std::string AuthManager::getCurrentUserId() const {
    return currentUserId;
}

bool AuthManager::validatePasswordStrength(const std::string& password) {
    if (password.length() < 8) {
        return false;
    }

    bool hasUpper = false, hasLower = false, hasDigit = false, hasSpecial = false;

    for (char c : password) {
        if (std::isupper(c)) hasUpper = true;
        else if (std::islower(c)) hasLower = true;
        else if (std::isdigit(c)) hasDigit = true;
        else if (!std::isalnum(c)) hasSpecial = true;
    }

    // Require at least 3 out of 4 character types
    int typeCount = (hasUpper ? 1 : 0) + (hasLower ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSpecial ? 1 : 0);
    return typeCount >= 3;
}

bool AuthManager::isEmailValid(const std::string& email) {
    // Simple email validation regex
    std::regex emailPattern(R"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})");
    return std::regex_match(email, emailPattern);
}

std::string AuthManager::hashPassword(const std::string& password) {
    // In real app, use proper hashing like bcrypt
    // This is a simplified version
    std::hash<std::string> hasher;
    return std::to_string(hasher(password));
}

std::string AuthManager::generateUserId() {
    auto now = std::chrono::system_clock::now();
    auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
            now.time_since_epoch()).count();

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(1000, 9999);

    return "user_" + std::to_string(timestamp) + "_" + std::to_string(dis(gen));
}