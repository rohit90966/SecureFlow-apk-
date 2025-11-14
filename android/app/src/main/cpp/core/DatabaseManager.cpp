#include "DatabaseManager.h"
#include "../models/PasswordEntry.h"
#include <iostream>
#include <sstream>

DatabaseManager::DatabaseManager(const std::string& databasePath) : db(nullptr), dbPath(databasePath) {
    initializeDatabase();
}

DatabaseManager::~DatabaseManager() {
    if (db) {
        sqlite3_close(db);
    }
}

bool DatabaseManager::initializeDatabase() {
    std::cout << "Initializing database at: " << dbPath << std::endl;

    int result = sqlite3_open(dbPath.c_str(), &db);
    if (result != SQLITE_OK) {
        std::cerr << "Cannot open database: " << sqlite3_errmsg(db) << std::endl;
        return false;
    }

    std::cout << "Database opened successfully" << std::endl;
    return createTables();
}

bool DatabaseManager::createTables() {
    const char* createPasswordsTable =
            "CREATE TABLE IF NOT EXISTS passwords ("
            "id TEXT PRIMARY KEY,"
            "title TEXT NOT NULL,"
            "username TEXT NOT NULL,"
            "password TEXT NOT NULL,"
            "website TEXT,"
            "category TEXT,"
            "notes TEXT,"
            "created_date INTEGER,"
            "modified_date INTEGER"
            ");";

    char* errorMessage = nullptr;

    if (sqlite3_exec(db, createPasswordsTable, nullptr, nullptr, &errorMessage) != SQLITE_OK) {
        std::cerr << "Error creating passwords table: " << errorMessage << std::endl;
        sqlite3_free(errorMessage);
        return false;
    }

    std::cout << "Passwords table created successfully" << std::endl;
    return true;
}

bool DatabaseManager::savePassword(const PasswordEntry& entry) {
    const char* insertSQL =
            "INSERT OR REPLACE INTO passwords "
            "(id, title, username, password, website, category, notes, created_date, modified_date) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);";

    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nullptr) != SQLITE_OK) {
        std::cerr << "Failed to prepare insert statement" << std::endl;
        return false;
    }

    sqlite3_bind_text(stmt, 1, entry.getId().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, entry.getTitle().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 3, entry.getUsername().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 4, entry.getPassword().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 5, entry.getWebsite().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 6, entry.getCategory().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 7, entry.getNotes().c_str(), -1, SQLITE_STATIC);
    sqlite3_bind_int64(stmt, 8, entry.getCreatedDate());
    sqlite3_bind_int64(stmt, 9, entry.getModifiedDate());

    bool success = (sqlite3_step(stmt) == SQLITE_DONE);
    sqlite3_finalize(stmt);

    if (success) {
        std::cout << "Password saved successfully: " << entry.getTitle() << std::endl;
    } else {
        std::cerr << "Failed to save password: " << entry.getTitle() << std::endl;
    }

    return success;
}

std::vector<PasswordEntry> DatabaseManager::getAllPasswords() {
    std::vector<PasswordEntry> passwords;
    const char* selectSQL = "SELECT * FROM passwords;";

    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db, selectSQL, -1, &stmt, nullptr) != SQLITE_OK) {
        std::cerr << "Failed to prepare select statement" << std::endl;
        return passwords;
    }

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        std::string id = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
        std::string title = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 1));
        std::string username = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 2));
        std::string password = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 3));

        PasswordEntry entry(title, username, password);

        // Set ID from database
        // Note: You'll need to add setId method to PasswordEntry

        // Set optional fields if they exist
        if (sqlite3_column_text(stmt, 4)) {
            entry.setWebsite(reinterpret_cast<const char*>(sqlite3_column_text(stmt, 4)));
        }
        if (sqlite3_column_text(stmt, 5)) {
            entry.setCategory(reinterpret_cast<const char*>(sqlite3_column_text(stmt, 5)));
        }
        if (sqlite3_column_text(stmt, 6)) {
            entry.setNotes(reinterpret_cast<const char*>(sqlite3_column_text(stmt, 6)));
        }

        passwords.push_back(entry);
    }

    sqlite3_finalize(stmt);
    std::cout << "Loaded " << passwords.size() << " passwords from database" << std::endl;
    return passwords;
}

bool DatabaseManager::isDatabaseOpen() const {
    return db != nullptr;
}

std::string DatabaseManager::getDatabasePath() const {
    return dbPath;
}