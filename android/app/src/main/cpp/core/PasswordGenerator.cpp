#include "PasswordGenerator.h"
#include <algorithm>
#include <chrono>

PasswordGenerator::PasswordGenerator() {
    unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();
    rng.seed(seed);
}

std::string PasswordGenerator::generateRandom(int length) {
    std::string password;
    const std::string allChars = uppercase + lowercase + numbers + symbols;

    // Ensure at least one of each type
    password += getRandomChar(uppercase);
    password += getRandomChar(lowercase);
    password += getRandomChar(numbers);
    password += getRandomChar(symbols);

    // Fill remaining length
    for(int i = 4; i < length; i++) {
        password += getRandomChar(allChars);
    }

    return shuffleString(password);
}

std::string PasswordGenerator::generateFromFavorite(const std::string& favorite, int length) {
    std::string base = favorite;
    base += numbers;
    base += symbols;

    std::string password;
    for(int i = 0; i < length; i++) {
        password += getRandomChar(base);
    }

    return shuffleString(password);
}

std::string PasswordGenerator::generateMemorable() {
    std::vector<std::string> words = {"Red", "Blue", "Green", "Sun", "Moon", "Star", "Fast", "Strong"};
    std::string password;

    for(int i = 0; i < 3; i++) {
        password += words[std::uniform_int_distribution<int>(0, words.size()-1)(rng)];
        if(i < 2) password += "-";
    }

    password += std::to_string(std::uniform_int_distribution<int>(10, 99)(rng));
    return password;
}

std::string PasswordGenerator::generatePin(int length) {
    std::string pin;
    for(int i = 0; i < length; i++) {
        pin += getRandomChar(numbers);
    }
    return pin;
}

char PasswordGenerator::getRandomChar(const std::string& charSet) {
    std::uniform_int_distribution<int> dist(0, charSet.size() - 1);
    return charSet[dist(rng)];
}

std::string PasswordGenerator::shuffleString(const std::string& input) {
    std::string output = input;
    std::shuffle(output.begin(), output.end(), rng);
    return output;
}