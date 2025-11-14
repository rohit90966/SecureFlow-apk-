#include <jni.h>
#include <string>
#include <sstream>
#include "core/PasswordManager.h"
#include "core/PasswordEntry.h"

extern "C" JNIEXPORT jlong JNICALL
Java_com_example_advanced_1password_1manager_NativePasswordService_createManager(
        JNIEnv* env,
        jobject /* this */) {
    return reinterpret_cast<jlong>(new PasswordManager());
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_advanced_1password_1manager_NativePasswordService_destroyManager(
        JNIEnv* env,
jobject /* this */,
jlong manager_ptr) {
if (manager_ptr != 0) {
delete reinterpret_cast<PasswordManager*>(manager_ptr);
}
}

// Set database path
extern "C" JNIEXPORT void JNICALL
Java_com_example_advanced_1password_1manager_NativePasswordService_setDatabasePath(
        JNIEnv* env,
jobject /* this */,
jlong manager_ptr,
        jstring db_path) {
if (manager_ptr == 0) return;

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
const char* nativeDbPath = env->GetStringUTFChars(db_path, nullptr);

manager->setDatabasePath(nativeDbPath);

env->ReleaseStringUTFChars(db_path, nativeDbPath);
}

extern "C" JNIEXPORT jboolean JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_addPassword(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jstring title,
        jstring username,
jstring password,
        jint category,
jstring website,
        jstring notes) {

if (manager_ptr == 0) return false;

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
const char* nativeTitle = env->GetStringUTFChars(title, nullptr);
const char* nativeUsername = env->GetStringUTFChars(username, nullptr);
const char* nativePassword = env->GetStringUTFChars(password, nullptr);
const char* nativeWebsite = env->GetStringUTFChars(website, nullptr);
const char* nativeNotes = env->GetStringUTFChars(notes, nullptr);

bool result = manager->addPassword(
        nativeTitle, nativeUsername, nativePassword,
        static_cast<Category>(category), nativeWebsite, nativeNotes
);

env->ReleaseStringUTFChars(title, nativeTitle);
env->ReleaseStringUTFChars(username, nativeUsername);
env->ReleaseStringUTFChars(password, nativePassword);
env->ReleaseStringUTFChars(website, nativeWebsite);
env->ReleaseStringUTFChars(notes, nativeNotes);

return result;
}

extern "C" JNIEXPORT jboolean JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_deletePassword(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jint id) {

if (manager_ptr == 0) return false;

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
return manager->deletePassword(id);
}

// Get all passwords as JSON
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_getAllPasswordsJson(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr) {

if (manager_ptr == 0) return env->NewStringUTF("{\"error\": \"Manager not initialized\"}");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
std::string result = manager->exportToJson();

return env->NewStringUTF(result.c_str());
}

// Get passwords by category as JSON
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_getPasswordsByCategoryJson(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jint category) {

if (manager_ptr == 0) return env->NewStringUTF("{\"error\": \"Manager not initialized\"}");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
auto passwords = manager->getPasswordsByCategory(static_cast<Category>(category));

std::stringstream ss;
ss << "[";
for(size_t i = 0; i < passwords.size(); ++i) {
ss << passwords[i].toJson();
if(i != passwords.size() - 1) ss << ",";
}
ss << "]";

return env->NewStringUTF(ss.str().c_str());
}

// Search passwords as JSON
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_searchPasswordsJson(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jstring query) {

if (manager_ptr == 0) return env->NewStringUTF("{\"error\": \"Manager not initialized\"}");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
const char* nativeQuery = env->GetStringUTFChars(query, nullptr);

auto passwords = manager->searchPasswords(nativeQuery);

std::stringstream ss;
ss << "[";
for(size_t i = 0; i < passwords.size(); ++i) {
ss << passwords[i].toJson();
if(i != passwords.size() - 1) ss << ",";
}
ss << "]";

env->ReleaseStringUTFChars(query, nativeQuery);
return env->NewStringUTF(ss.str().c_str());
}

// Get category statistics as JSON
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_getCategoryStatsJson(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr) {

if (manager_ptr == 0) return env->NewStringUTF("{\"error\": \"Manager not initialized\"}");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
auto stats = manager->getCategoryStats();

std::stringstream ss;
ss << "{";
bool first = true;
for(const auto& [category, count] : stats) {
if(!first) ss << ",";
ss << "\"" << category << "\":" << count;
first = false;
}
ss << "}";

return env->NewStringUTF(ss.str().c_str());
}

// Get total password count
extern "C" JNIEXPORT jint JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_getTotalPasswordCount(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr) {

if (manager_ptr == 0) return -1;

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
return manager->getTotalCount();
}

// NEW: Enhanced password analysis with detailed suggestions
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_analyzePasswordDetailed(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jstring password) {

if (manager_ptr == 0) return env->NewStringUTF("{\"error\": \"Manager not initialized\"}");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
const char* nativePassword = env->GetStringUTFChars(password, nullptr);

// Use the enhanced password analysis
PasswordAnalysisResult result = PasswordEntry::analyzePasswordDetailed(nativePassword);

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
ss << "\"length\":" << strlen(nativePassword) << ",";

// Analyze character types for UI
bool hasUpper = false, hasLower = false, hasDigit = false, hasSpecial = false;
std::string passStr = nativePassword;

for(char c : passStr) {
if(std::isupper(c)) hasUpper = true;
else if(std::islower(c)) hasLower = true;
else if(std::isdigit(c)) hasDigit = true;
else if(!std::isalnum(c)) hasSpecial = true;
}

ss << "\"hasUpper\":" << (hasUpper ? "true" : "false") << ",";
ss << "\"hasLower\":" << (hasLower ? "true" : "false") << ",";
ss << "\"hasDigit\":" << (hasDigit ? "true" : "false") << ",";
ss << "\"hasSpecial\":" << (hasSpecial ? "true" : "false");
ss << "}";

env->ReleaseStringUTFChars(password, nativePassword);
return env->NewStringUTF(ss.str().c_str());
}

// NEW: Quick password strength check (for real-time feedback)
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_getPasswordStrength(
        JNIEnv* env,
        jobject /* this */,
        jstring password) {

const char* nativePassword = env->GetStringUTFChars(password, nullptr);

std::string result = PasswordEntry::analyzeStrength(nativePassword);

env->ReleaseStringUTFChars(password, nativePassword);
return env->NewStringUTF(result.c_str());
}

// NEW: Generate password with specific requirements
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_generateStrongPassword(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jint length,
        jboolean includeUpper,
jboolean includeLower,
        jboolean includeDigits,
jboolean includeSymbols) {

if (manager_ptr == 0) return env->NewStringUTF("");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);

// Generate password with specified requirements
const std::string uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const std::string lowercase = "abcdefghijklmnopqrstuvwxyz";
const std::string digits = "0123456789";
const std::string symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?";

std::string charPool = "";
if (includeUpper) charPool += uppercase;
if (includeLower) charPool += lowercase;
if (includeDigits) charPool += digits;
if (includeSymbols) charPool += symbols;

if (charPool.empty()) {
charPool = uppercase + lowercase + digits + symbols; // Default to all
}

std::string result;
std::random_device rd;
std::mt19937 gen(rd());
std::uniform_int_distribution<> dis(0, charPool.size() - 1);

// Ensure at least one of each required type
if (includeUpper) result += uppercase[dis(gen) % uppercase.size()];
if (includeLower) result += lowercase[dis(gen) % lowercase.size()];
if (includeDigits) result += digits[dis(gen) % digits.size()];
if (includeSymbols) result += symbols[dis(gen) % symbols.size()];

// Fill remaining length
while (result.length() < length) {
result += charPool[dis(gen)];
}

// Shuffle the result
std::shuffle(result.begin(), result.end(), gen);

return env->NewStringUTF(result.c_str());
}

// Your existing methods remain the same...
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_analyzePassword(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jstring password) {

if (manager_ptr == 0) return env->NewStringUTF("Error: Manager not initialized");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
const char* nativePassword = env->GetStringUTFChars(password, nullptr);

std::string result = manager->analyzePassword(nativePassword);

env->ReleaseStringUTFChars(password, nativePassword);

return env->NewStringUTF(result.c_str());
}

extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_generateRandomPassword(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jint length) {

if (manager_ptr == 0) return env->NewStringUTF("");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
std::string result = manager->generateRandomPassword(length);

return env->NewStringUTF(result.c_str());
}

extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_generateFromFavorite(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jstring favorite,
        jint length) {

if (manager_ptr == 0) return env->NewStringUTF("");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
const char* nativeFavorite = env->GetStringUTFChars(favorite, nullptr);

std::string result = manager->generateFromFavorite(nativeFavorite, length);

env->ReleaseStringUTFChars(favorite, nativeFavorite);

return env->NewStringUTF(result.c_str());
}

// Generate memorable password
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_generateMemorablePassword(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr) {

if (manager_ptr == 0) return env->NewStringUTF("");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
std::string result = manager->generateMemorablePassword();

return env->NewStringUTF(result.c_str());
}

// Generate PIN
extern "C" JNIEXPORT jstring JNICALL
        Java_com_example_advanced_1password_1manager_NativePasswordService_generatePin(
        JNIEnv* env,
        jobject /* this */,
        jlong manager_ptr,
jint length) {

if (manager_ptr == 0) return env->NewStringUTF("");

PasswordManager* manager = reinterpret_cast<PasswordManager*>(manager_ptr);
std::string result = manager->generatePin(length);

return env->NewStringUTF(result.c_str());
}