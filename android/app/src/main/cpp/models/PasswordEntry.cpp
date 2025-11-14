#include "PasswordEntry.h"
#include <sstream>
#include <algorithm>
#include <cctype>
#include <chrono>
#include <random>
#include <vector>

PasswordEntry::PasswordEntry(const std::string& title, const std::string& username,
                             const std::string& password, Category category,
                             const std::string& website, const std::string& notes)
        : title(title), username(username), password(password), website(website),
          category(category), notes(notes) {

    
    id = generateId();

    // Set timestamps
    auto now = std::chrono::system_clock::now();
    createdDate = std::chrono::system_clock::to_time_t(now);
    modifiedDate = createdDate;

    calculateStrength();
}

std::string PasswordEntry::getCategoryString() const {
    return categoryToString(category);
}

void PasswordEntry::calculateStrength() {
    strength = analyzeStrength(password);
}

PasswordAnalysisResult PasswordEntry::analyzePasswordDetailed(const std::string& password) {
    PasswordAnalysisResult result;
    result.score = 0;
    result.strength = "Very Weak";

    if (password.empty()) {
        result.suggestions.push_back("Password cannot be empty");
        return result;
    }

    // Character type analysis
    bool hasUpper = false, hasLower = false, hasDigit = false, hasSpecial = false;
    int upperCount = 0, lowerCount = 0, digitCount = 0, specialCount = 0;

    for(char c : password) {
        if(std::isupper(c)) { hasUpper = true; upperCount++; }
        else if(std::islower(c)) { hasLower = true; lowerCount++; }
        else if(std::isdigit(c)) { hasDigit = true; digitCount++; }
        else if(!std::isalnum(c)) { hasSpecial = true; specialCount++; }
    }

    // Length scoring
    int length = password.length();
    if(length >= 8) result.score += 25;
    if(length >= 12) result.score += 15;
    if(length >= 16) result.score += 10;

    // Character variety scoring
    if(hasUpper) result.score += 15;
    if(hasLower) result.score += 15;
    if(hasDigit) result.score += 15;
    if(hasSpecial) result.score += 15;

    // Additional scoring for character distribution
    if (upperCount >= 2) result.score += 5;
    if (lowerCount >= 2) result.score += 5;
    if (digitCount >= 2) result.score += 5;
    if (specialCount >= 2) result.score += 5;

    // Determine strength level
    if(result.score >= 80) result.strength = "Very Strong";
    else if(result.score >= 60) result.strength = "Strong";
    else if(result.score >= 40) result.strength = "Moderate";
    else if(result.score >= 20) result.strength = "Weak";
    else result.strength = "Very Weak";

    // Generate suggestions
    if (length < 8) {
        result.suggestions.push_back("Make password longer (at least 8 characters)");
    } else if (length < 12) {
        result.suggestions.push_back("Consider using 12+ characters for better security");
    }

    if (!hasUpper) {
        result.suggestions.push_back("Add uppercase letters (A-Z)");
    } else if (upperCount == 1) {
        result.suggestions.push_back("Add more uppercase letters for better security");
    }

    if (!hasLower) {
        result.suggestions.push_back("Add lowercase letters (a-z)");
    }

    if (!hasDigit) {
        result.suggestions.push_back("Add numbers (0-9)");
    } else if (digitCount == 1) {
        result.suggestions.push_back("Add more numbers for better security");
    }

    if (!hasSpecial) {
        result.suggestions.push_back("Add special characters (!@#$%^&*)");
    } else if (specialCount == 1) {
        result.suggestions.push_back("Add more special characters for better security");
    }

    // Check for common patterns
    if (password.find("123") != std::string::npos) {
        result.suggestions.push_back("Avoid sequential numbers (123)");
    }
    if (password.find("abc") != std::string::npos) {
        result.suggestions.push_back("Avoid sequential letters (abc)");
    }
    if (password.find("password") != std::string::npos) {
        result.suggestions.push_back("Avoid common words like 'password'");
    }

    // Check for personal information patterns
    if (password.length() <= 6 && hasDigit && !hasUpper && !hasSpecial) {
        result.suggestions.push_back("Very short numeric passwords are easy to guess");
    }

    return result;
}

std::string PasswordEntry::analyzeStrength(const std::string& password) {
    PasswordAnalysisResult result = analyzePasswordDetailed(password);
    return result.strength + " (" + std::to_string(result.score) + "/100)";
}

// Get detailed analysis as JSON
std::string PasswordEntry::getDetailedAnalysisJson(const std::string& password) {
    PasswordAnalysisResult result = analyzePasswordDetailed(password);

    std::stringstream ss;
    ss << "{";
    ss << "\"score\":" << result.score << ",";
    ss << "\"strength\":\"" << result.strength << "\",";
    ss << "\"suggestions\":[";

    for(size_t i = 0; i < result.suggestions.size(); ++i) {
        ss << "\"" << result.suggestions[i] << "\"";
        if(i != result.suggestions.size() - 1) ss << ",";
    }

    ss << "],";
    ss << "\"length\":" << password.length() << ",";
    ss << "\"hasUpper\":" << (result.suggestions.empty() ? "false" : "true") << ",";
    ss << "\"hasLower\":" << (result.suggestions.empty() ? "false" : "true") << ",";
    ss << "\"hasDigit\":" << (result.suggestions.empty() ? "false" : "true") << ",";
    ss << "\"hasSpecial\":" << (result.suggestions.empty() ? "false" : "true");
    ss << "}";

    return ss.str();
}

std::string PasswordEntry::toJson() const {
    std::stringstream ss;
    ss << "{"
       << "\"id\":\"" << id << "\","
       << "\"title\":\"" << title << "\","
       << "\"username\":\"" << username << "\","
       << "\"website\":\"" << website << "\","
       << "\"category\":\"" << getCategoryString() << "\","
       << "\"strength\":\"" << strength << "\","
       << "\"notes\":\"" << notes << "\","
       << "\"createdDate\":" << createdDate << ","
       << "\"modifiedDate\":" << modifiedDate
       << "}";
    return ss.str();
}

Category PasswordEntry::stringToCategory(const std::string& categoryStr) {
    if (categoryStr == "Banking") return Category::BANKING;
    if (categoryStr == "Social Media") return Category::SOCIAL_MEDIA;
    if (categoryStr == "Email") return Category::EMAIL;
    if (categoryStr == "Work") return Category::WORK;
    if (categoryStr == "Shopping") return Category::SHOPPING;
    if (categoryStr == "Entertainment") return Category::ENTERTAINMENT;
    return Category::OTHER;
}

std::string PasswordEntry::categoryToString(Category category) {
    switch(category) {
        case Category::BANKING: return "Banking";
        case Category::SOCIAL_MEDIA: return "Social Media";
        case Category::EMAIL: return "Email";
        case Category::WORK: return "Work";
        case Category::SHOPPING: return "Shopping";
        case Category::ENTERTAINMENT: return "Entertainment";
        default: return "Other";
    }
}

void PasswordEntry::updateModifiedDate() {
    auto now = std::chrono::system_clock::now();
    modifiedDate = std::chrono::system_clock::to_time_t(now);
}

std::string PasswordEntry::generateId() {
    auto now = std::chrono::system_clock::now();
    auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
            now.time_since_epoch()).count();

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(1000, 9999);

    return "pwd_" + std::to_string(timestamp) + "_" + std::to_string(dis(gen));
}