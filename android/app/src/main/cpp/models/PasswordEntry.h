#ifndef PASSWORDENTRY_H
#define PASSWORDENTRY_H

#include <string>
#include <ctime>
#include <vector>

enum class Category {
    BANKING,
    SOCIAL_MEDIA,
    EMAIL,
    WORK,
    SHOPPING,
    ENTERTAINMENT,
    OTHER
};

struct PasswordAnalysisResult {
    int score;
    std::string strength;
    std::vector<std::string> suggestions;
};

class PasswordEntry {
private:
    std::string id;
    std::string title;
    std::string username;
    std::string password;
    std::string website;
    Category category;
    std::string notes;
    std::string strength;
    time_t createdDate;
    time_t modifiedDate;

public:
    PasswordEntry(const std::string& title, const std::string& username,
                  const std::string& password, Category category = Category::OTHER,
                  const std::string& website = "", const std::string& notes = "");

    std::string getId() const { return id; }
    std::string getTitle() const { return title; }
    std::string getUsername() const { return username; }
    std::string getPassword() const { return password; }
    std::string getWebsite() const { return website; }
    Category getCategory() const { return category; }
    std::string getCategoryString() const;
    std::string getNotes() const { return notes; }
    std::string getStrength() const { return strength; }
    time_t getCreatedDate() const { return createdDate; }
    time_t getModifiedDate() const { return modifiedDate; }

    // Setters
    void setId(const std::string& newId) { id = newId; }
    void setTitle(const std::string& newTitle) {
        title = newTitle;
        updateModifiedDate();
        calculateStrength();
    }
    void setUsername(const std::string& newUsername) {
        username = newUsername;
        updateModifiedDate();
    }
    void setPassword(const std::string& newPassword) {
        password = newPassword;
        updateModifiedDate();
        calculateStrength();
    }
    void setWebsite(const std::string& newWebsite) {
        website = newWebsite;
        updateModifiedDate();
    }
    void setCategory(Category newCategory) {
        category = newCategory;
        updateModifiedDate();
    }
    void setNotes(const std::string& newNotes) {
        notes = newNotes;
        updateModifiedDate();
    }
    void setCreatedDate(time_t date) { createdDate = date; }
    void setModifiedDate(time_t date) { modifiedDate = date; }

    // Analysis
    static std::string analyzeStrength(const std::string& password);
    static PasswordAnalysisResult analyzePasswordDetailed(const std::string& password);
    static std::string getDetailedAnalysisJson(const std::string& password);

    // JSON conversion
    std::string toJson() const;

    // Database helper methods
    static Category stringToCategory(const std::string& categoryStr);
    static std::string categoryToString(Category category);

private:
    void calculateStrength();
    void updateModifiedDate();
    std::string generateId();
};

#endif