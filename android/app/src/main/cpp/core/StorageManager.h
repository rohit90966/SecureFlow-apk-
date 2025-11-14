#ifndef STORAGEMANAGER_H
#define STORAGEMANAGER_H

#include <string>
#include <vector>
#include "../models/PasswordEntry.h"

class StorageManager {
private:
    std::string storagePath;
    std::string encryptionKey;

    std::string encryptData(const std::string& data);
    std::string decryptData(const std::string& encryptedData);
    bool fileExists(const std::string& path);

public:
    StorageManager(const std::string& appDirectory, const std::string& masterPassword);

    bool savePasswords(const std::vector<PasswordEntry>& passwords);
    std::vector<PasswordEntry> loadPasswords();

    bool saveUserData(const std::string& key, const std::string& value);
    std::string loadUserData(const std::string& key);

    bool createBackup(const std::string& backupPath);
    bool restoreBackup(const std::string& backupPath);
};

#endif