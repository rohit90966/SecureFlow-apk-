#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <string>
#include <vector>
#include <sqlite3.h>

// Forward declaration
class PasswordEntry;

class DatabaseManager {
private:
    sqlite3* db;
    std::string dbPath;

    bool initializeDatabase();
    bool createTables();

public:
    DatabaseManager(const std::string& databasePath);
    ~DatabaseManager();

    // Password operations
    bool savePassword(const PasswordEntry& entry);
    bool updatePassword(const PasswordEntry& entry);
    bool deletePassword(const std::string& id);
    std::vector<PasswordEntry> getAllPasswords();
    PasswordEntry getPasswordById(const std::string& id);

    // Utility methods
    bool isDatabaseOpen() const;
    std::string getDatabasePath() const;
};

#endif