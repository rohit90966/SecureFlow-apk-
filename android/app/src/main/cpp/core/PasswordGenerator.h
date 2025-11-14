#ifndef PASSWORD_GENERATOR_H
#define PASSWORD_GENERATOR_H

#include <string>
#include <random>
#include <vector>

class PasswordGenerator {
private:
    std::mt19937 rng;

    const std::string uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const std::string lowercase = "abcdefghijklmnopqrstuvwxyz";
    const std::string numbers = "0123456789";
    const std::string symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?";

public:
    PasswordGenerator();

    std::string generateRandom(int length = 16);
    std::string generateFromFavorite(const std::string& favorite, int length = 12);
    std::string generateMemorable();
    std::string generatePin(int length = 6);

private:
    char getRandomChar(const std::string& charSet);
    std::string shuffleString(const std::string& input);
};

#endif