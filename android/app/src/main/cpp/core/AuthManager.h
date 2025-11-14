#ifndef AUTHMANAGER_H
#define AUTHMANAGER_H

#include <string>

class AuthManager {
private:
    std::string currentUserEmail;
    std::string currentUserId;
    bool isAuthenticated;

    std::string hashPassword(const std::string& password);
    std::string generateUserId();

public:
    AuthManager();

    struct AuthResult {
        bool success;
        std::string message;
        std::string userId;
    };

    // Authentication
    AuthResult registerUser(const std::string& email, const std::string& password);
    AuthResult loginUser(const std::string& email, const std::string& password);
    bool logoutUser();

    // Session Management
    bool isLoggedIn() const;
    std::string getCurrentUserEmail() const;
    std::string getCurrentUserId() const;

    // Security
    bool validatePasswordStrength(const std::string& password);
    bool isEmailValid(const std::string& email);
};

#endif