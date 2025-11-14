//#include "PasswordManager.h"
//#include <algorithm>
//#include <sstream>
//
//PasswordManager::PasswordManager() {}
//
//bool PasswordManager::addPassword(const std::string& title, const std::string& username,
//                                  const std::string& password, Category category,
//                                  const std::string& website, const std::string& notes) {
//    try {
//        PasswordEntry newEntry(title, username, password, category, website, notes);
//        passwords.push_back(newEntry);
//        return true;
//    } catch(...) {
//        return false;
//    }
//}
//
//bool PasswordManager::deletePassword(int id) {
//    for(auto it = passwords.begin(); it != passwords.end(); ++it) {
//        if(it->getId() == id) {
//            passwords.erase(it);
//            return true;
//        }
//    }
//    return false;
//}
//
//std::vector<PasswordEntry> PasswordManager::getPasswordsByCategory(Category category) {
//    std::vector<PasswordEntry> result;
//    for(const auto& entry : passwords) {
//        if(entry.getCategory() == category) {
//            result.push_back(entry);
//        }
//    }
//    return result;
//}
//
//std::vector<PasswordEntry> PasswordManager::searchPasswords(const std::string& query) {
//    std::vector<PasswordEntry> result;
//    if(query.empty()) return passwords;
//
//    std::string lowerQuery = query;
//    std::transform(lowerQuery.begin(), lowerQuery.end(), lowerQuery.begin(), ::tolower);
//
//    for(const auto& entry : passwords) {
//        std::string title = entry.getTitle();
//        std::string username = entry.getUsername();
//        std::string website = entry.getWebsite();
//
//        std::transform(title.begin(), title.end(), title.begin(), ::tolower);
//        std::transform(username.begin(), username.end(), username.begin(), ::tolower);
//        std::transform(website.begin(), website.end(), website.begin(), ::tolower);
//
//        if(title.find(lowerQuery) != std::string::npos ||
//           username.find(lowerQuery) != std::string::npos ||
//           website.find(lowerQuery) != std::string::npos) {
//            result.push_back(entry);
//        }
//    }
//    return result;
//}
//
//std::string PasswordManager::analyzePassword(const std::string& password) {
//    return PasswordEntry::analyzeStrength(password);
//}
//
//std::map<std::string, int> PasswordManager::getCategoryStats() {
//    std::map<std::string, int> stats;
//    for(const auto& entry : passwords) {
//        std::string category = entry.getCategoryString();
//        stats[category]++;
//    }
//    return stats;
//}
//
//std::string PasswordManager::generateRandomPassword(int length) {
//    return generator.generateRandom(length);
//}
//
//std::string PasswordManager::generateFromFavorite(const std::string& favorite, int length) {
//    return generator.generateFromFavorite(favorite, length);
//}
//
//std::string PasswordManager::generateMemorablePassword() {
//    return generator.generateMemorable();
//}
//
//std::string PasswordManager::generatePin(int length) {
//    return generator.generatePin(length);
//}
//
//std::string PasswordManager::exportToJson() {
//    std::stringstream ss;
//    ss << "{\"passwords\":[";
//
//    for(size_t i = 0; i < passwords.size(); ++i) {
//        ss << passwords[i].toJson();
//        if(i != passwords.size() - 1) ss << ",";
//    }
//
//    ss << "]}";
//    return ss.str();
//}
#include "PasswordManager.h"
#include <algorithm>
#include <sstream>
#include <sqlite3.h>
#include <iostream>
#include <filesystem>

PasswordManager::PasswordManager() : databasePath("") {}

void PasswordManager::setDatabasePath(const std::string& path) {
    databasePath = path;
    if (!databasePath.empty()) {
        initializeDatabase();
        loadPasswordsFromDatabase();
    }
}

bool PasswordManager::initializeDatabase() {
    if (databasePath.empty()) return false;

    sqlite3* db;
    int rc = sqlite3_open(databasePath.c_str(), &db);

    if (rc) {
        std::cerr << "Can't open database: " << sqlite3_errmsg(db) << std::endl;
        return false;
    }

    const char* createTableSQL =
            "CREATE TABLE IF NOT EXISTS passwords ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "title TEXT NOT NULL, "
            "username TEXT NOT NULL, "
            "password TEXT NOT NULL, "
            "category INTEGER NOT NULL, "
            "website TEXT, "
            "notes TEXT, "
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
            "updated_at DATETIME DEFAULT CURRENT_TIMESTAMP);";

    char* errMsg = 0;
    rc = sqlite3_exec(db, createTableSQL, 0, 0, &errMsg);

    if (rc != SQLITE_OK) {
        std::cerr << "SQL error: " << errMsg << std::endl;
        sqlite3_free(errMsg);
        sqlite3_close(db);
        return false;
    }

    sqlite3_close(db);
    return true;
}

bool PasswordManager::loadPasswordsFromDatabase() {
    if (databasePath.empty()) return false;

    sqlite3* db;
    int rc = sqlite3_open(databasePath.c_str(), &db);

    if (rc) {
        std::cerr << "Can't open database: " << sqlite3_errmsg(db) << std::endl;
        return false;
    }

    const char* selectSQL = "SELECT id, title, username, password, category, website, notes FROM passwords;";
    sqlite3_stmt* stmt;

    rc = sqlite3_prepare_v2(db, selectSQL, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        std::cerr << "Failed to prepare statement: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return false;
    }

    passwords.clear(); // Clear existing passwords before loading from database

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int id = sqlite3_column_int(stmt, 0);
        const char* title = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        const char* username = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
        const char* password = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 3));
        int category = sqlite3_column_int(stmt, 4);
        const char* website = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 5));
        const char* notes = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 6));

        PasswordEntry entry(
                title ? title : "",
                username ? username : "",
                password ? password : "",
                static_cast<Category>(category),
                website ? website : "",
                notes ? notes : ""
        );
        entry.setId(id); // Set the ID from database

        passwords.push_back(entry);
    }

    sqlite3_finalize(stmt);
    sqlite3_close(db);
    return true;
}

bool PasswordManager::savePasswordToDatabase(const PasswordEntry& entry) {
    if (databasePath.empty()) return false;

    sqlite3* db;
    int rc = sqlite3_open(databasePath.c_str(), &db);

    if (rc) {
        std::cerr << "Can't open database: " << sqlite3_errmsg(db) << std::endl;
        return false;
    }

    const char* insertSQL =
            "INSERT INTO passwords (title, username, password, category, website, notes) "
            "VALUES (?, ?, ?, ?, ?, ?);";

    sqlite3_stmt* stmt;
    rc = sqlite3_prepare_v2(db, insertSQL, -1, &stmt, 0);

    if (rc != SQLITE_OK) {
        std::cerr << "Failed to prepare statement: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return false;
    }

    sqlite3_bind_text(stmt, 1, entry.getTitle().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, entry.getUsername().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 3, entry.getPassword().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_int(stmt, 4, static_cast<int>(entry.getCategory()));
    sqlite3_bind_text(stmt, 5, entry.getWebsite().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 6, entry.getNotes().c_str(), -1, SQLITE_STATIC);

    rc = sqlite3_step(stmt);
    bool success = (rc == SQLITE_DONE);

    sqlite3_finalize(stmt);
    sqlite3_close(db);

    return success;
}

bool PasswordManager::deletePasswordFromDatabase(int id) {
    if (databasePath.empty()) return false;

    sqlite3* db;
    int rc = sqlite3_open(databasePath.c_str(), &db);

    if (rc) {
        std::cerr << "Can't open database: " << sqlite3_errmsg(db) << std::endl;
        return false;
    }

    const char* deleteSQL = "DELETE FROM passwords WHERE id = ?;";
    sqlite3_stmt* stmt;

    rc = sqlite3_prepare_v2(db, deleteSQL, -1, &stmt, 0);
    if (rc != SQLITE_OK) {
        std::cerr << "Failed to prepare statement: " << sqlite3_errmsg(db) << std::endl;
        sqlite3_close(db);
        return false;
    }

    sqlite3_bind_int(stmt, 1, id);
    rc = sqlite3_step(stmt);
    bool success = (rc == SQLITE_DONE);

    sqlite3_finalize(stmt);
    sqlite3_close(db);

    return success;
}

bool PasswordManager::addPassword(const std::string& title, const std::string& username,
                                  const std::string& password, Category category,
                                  const std::string& website, const std::string& notes) {
    try {
        PasswordEntry newEntry(title, username, password, category, website, notes);

        // Save to database first
        if (savePasswordToDatabase(newEntry)) {
            // If successful, add to memory and reload to get the auto-incremented ID
            loadPasswordsFromDatabase();
            return true;
        }
        return false;
    } catch(...) {
        return false;
    }
}

bool PasswordManager::deletePassword(int id) {
    // Delete from database first
    if (deletePasswordFromDatabase(id)) {
        // If successful, delete from memory
        for(auto it = passwords.begin(); it != passwords.end(); ++it) {
            if(it->getId() == id) {
                passwords.erase(it);
                return true;
            }
        }
    }
    return false;
}

// Rest of your existing methods remain the same...
std::vector<PasswordEntry> PasswordManager::getPasswordsByCategory(Category category) {
    std::vector<PasswordEntry> result;
    for(const auto& entry : passwords) {
        if(entry.getCategory() == category) {
            result.push_back(entry);
        }
    }
    return result;
}

std::vector<PasswordEntry> PasswordManager::searchPasswords(const std::string& query) {
    std::vector<PasswordEntry> result;
    if(query.empty()) return passwords;

    std::string lowerQuery = query;
    std::transform(lowerQuery.begin(), lowerQuery.end(), lowerQuery.begin(), ::tolower);

    for(const auto& entry : passwords) {
        std::string title = entry.getTitle();
        std::string username = entry.getUsername();
        std::string website = entry.getWebsite();

        std::transform(title.begin(), title.end(), title.begin(), ::tolower);
        std::transform(username.begin(), username.end(), username.begin(), ::tolower);
        std::transform(website.begin(), website.end(), website.begin(), ::tolower);

        if(title.find(lowerQuery) != std::string::npos ||
           username.find(lowerQuery) != std::string::npos ||
           website.find(lowerQuery) != std::string::npos) {
            result.push_back(entry);
        }
    }
    return result;
}

std::string PasswordManager::analyzePassword(const std::string& password) {
    return PasswordEntry::analyzeStrength(password);
}

std::map<std::string, int> PasswordManager::getCategoryStats() {
    std::map<std::string, int> stats;
    for(const auto& entry : passwords) {
        std::string category = entry.getCategoryString();
        stats[category]++;
    }
    return stats;
}

std::string PasswordManager::generateRandomPassword(int length) {
    return generator.generateRandom(length);
}

std::string PasswordManager::generateFromFavorite(const std::string& favorite, int length) {
    return generator.generateFromFavorite(favorite, length);
}

std::string PasswordManager::generateMemorablePassword() {
    return generator.generateMemorable();
}

std::string PasswordManager::generatePin(int length) {
    return generator.generatePin(length);
}

std::string PasswordManager::exportToJson() {
    std::stringstream ss;
    ss << "{\"passwords\":[";

    for(size_t i = 0; i < passwords.size(); ++i) {
        ss << passwords[i].toJson();
        if(i != passwords.size() - 1) ss << ",";
    }

    ss << "]}";
    return ss.str();
}