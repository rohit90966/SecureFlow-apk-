//#ifndef PASSWORD_MANAGER_H
//#define PASSWORD_MANAGER_H
//
//#include "PasswordEntry.h"
//#include "PasswordGenerator.h"
//#include <vector>
//#include <string>
//#include <map>
//
//class PasswordManager {
//private:
//    std::vector<PasswordEntry> passwords;
//    PasswordGenerator generator;
//
//public:
//    PasswordManager();
//
//    // Password operations
//    bool addPassword(const std::string& title, const std::string& username,
//                     const std::string& password, Category category,
//                     const std::string& website = "", const std::string& notes = "");
//
//    bool deletePassword(int id);
//    std::vector<PasswordEntry> getAllPasswords() const { return passwords; }
//
//    // Search and filter
//    std::vector<PasswordEntry> getPasswordsByCategory(Category category);
//    std::vector<PasswordEntry> searchPasswords(const std::string& query);
//
//    // Analysis
//    std::string analyzePassword(const std::string& password);
//    std::map<std::string, int> getCategoryStats();
//
//    // Generation
//    std::string generateRandomPassword(int length = 16);
//    std::string generateFromFavorite(const std::string& favorite, int length = 12);
//    std::string generateMemorablePassword();
//    std::string generatePin(int length = 6);
//
//    // Data management
//    std::string exportToJson();
//    int getTotalCount() const { return passwords.size(); }
//};
//
//#endif
#ifndef PASSWORD_MANAGER_H
#define PASSWORD_MANAGER_H

#include "PasswordEntry.h"
#include "PasswordGenerator.h"
#include <vector>
#include <string>
#include <map>

class PasswordManager {
private:
    std::vector<PasswordEntry> passwords;
    PasswordGenerator generator;
    std::string databasePath;

    // Database methods
    bool initializeDatabase();
    bool loadPasswordsFromDatabase();
    bool savePasswordToDatabase(const PasswordEntry& entry);
    bool deletePasswordFromDatabase(int id);

public:
    PasswordManager();

    // Set database path (call this before any operations)
    void setDatabasePath(const std::string& path);

    // Password operations
    bool addPassword(const std::string& title, const std::string& username,
                     const std::string& password, Category category,
                     const std::string& website = "", const std::string& notes = "");

    bool deletePassword(int id);
    std::vector<PasswordEntry> getAllPasswords() const { return passwords; }

    // Search and filter
    std::vector<PasswordEntry> getPasswordsByCategory(Category category);
    std::vector<PasswordEntry> searchPasswords(const std::string& query);

    // Analysis
    std::string analyzePassword(const std::string& password);
    std::map<std::string, int> getCategoryStats();

    // Generation
    std::string generateRandomPassword(int length = 16);
    std::string generateFromFavorite(const std::string& favorite, int length = 12);
    std::string generateMemorablePassword();
    std::string generatePin(int length = 6);

    // Data management
    std::string exportToJson();
    bool importFromJson(const std::string& jsonData);
    int getTotalCount() const { return passwords.size(); }

    // Database management
    bool backupDatabase(const std::string& backupPath);
    bool restoreDatabase(const std::string& backupPath);
};

#endif