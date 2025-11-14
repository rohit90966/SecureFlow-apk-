#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cryptopp/aes.h>
#include <cryptopp/modes.h>
#include <cryptopp/filters.h>
#include <cryptopp/base64.h>
#include <cryptopp/osrng.h>

using namespace std;
using namespace CryptoPP;

class EncryptionService {
private:
    static SecByteBlock key;
    static SecByteBlock iv;
    static bool initialized;
    static const string KEY_FILE;
    static const string IV_FILE;

    // Load key/IV from file
    static bool loadKeys() {
        ifstream keyIn(KEY_FILE, ios::binary);
        ifstream ivIn(IV_FILE, ios::binary);

        if (!keyIn || !ivIn) return false;

        vector<byte> keyVec(32), ivVec(16);
        keyIn.read((char*)keyVec.data(), keyVec.size());
        ivIn.read((char*)ivVec.data(), ivVec.size());
        key.Assign(keyVec.data(), keyVec.size());
        iv.Assign(ivVec.data(), ivVec.size());

        keyIn.close();
        ivIn.close();
        return true;
    }

    // Save key/IV to file
    static void saveKeys() {
        ofstream keyOut(KEY_FILE, ios::binary);
        ofstream ivOut(IV_FILE, ios::binary);
        keyOut.write((char*)key.data(), key.size());
        ivOut.write((char*)iv.data(), iv.size());
        keyOut.close();
        ivOut.close();
    }

public:
    // Initialize AES key and IV (load or generate)
    static void initialize() {
        if (initialized) return;

        AutoSeededRandomPool prng;

        if (!loadKeys()) {
            key = SecByteBlock(32); // 256-bit
            iv = SecByteBlock(16);  // 128-bit
            prng.GenerateBlock(key, key.size());
            prng.GenerateBlock(iv, iv.size());
            saveKeys();
            cout << "🔐 Generated new AES key and IV.\n";
        } else {
            cout << "🔐 Loaded existing AES key and IV.\n";
        }

        initialized = true;
    }

    // Encrypt plaintext
    static string encrypt(const string& plainText) {
        if (!initialized) throw runtime_error("Encryption service not initialized");

        string cipherText;
        CBC_Mode<AES>::Encryption encryptor(key, key.size(), iv);
        StringSource ss(plainText, true,
                        new StreamTransformationFilter(encryptor,
                                                       new Base64Encoder(
                                                               new StringSink(cipherText), false
                                                       )
                        )
        );
        return cipherText;
    }

    // Decrypt ciphertext
    static string decrypt(const string& cipherText) {
        if (!initialized) throw runtime_error("Encryption service not initialized");

        string plainText;
        CBC_Mode<AES>::Decryption decryptor(key, key.size(), iv);
        StringSource ss(cipherText, true,
                        new Base64Decoder(
                                new StreamTransformationFilter(decryptor,
                                                               new StringSink(plainText)
                                )
                        )
        );
        return plainText;
    }

    // Clear keys
    static void clearKeys() {
        remove(KEY_FILE.c_str());
        remove(IV_FILE.c_str());
        initialized = false;
        cout << "🔐 Cleared AES key and IV.\n";
    }
};

// Static member definitions
SecByteBlock EncryptionService::key;
SecByteBlock EncryptionService::iv;
bool EncryptionService::initialized = false;
const string EncryptionService::KEY_FILE = "D:\\Downloads\\aes_key.bin";
const string EncryptionService::IV_FILE = "D:\\Downloads\\aes_iv.bin";

int main() {
    EncryptionService::initialize();

    string text;
    cout << "Enter text to encrypt: ";
    getline(cin, text);

    string encrypted = EncryptionService::encrypt(text);
    cout << "\nEncrypted (Base64): " << encrypted << "\n";

    string decrypted = EncryptionService::decrypt(encrypted);
    cout << "Decrypted: " << decrypted << "\n";

    cout << "\nTest Success: " << (text == decrypted ? "✅" : "❌") << "\n";


    return 0;
}
