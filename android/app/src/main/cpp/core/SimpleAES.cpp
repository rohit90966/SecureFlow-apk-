#include "SimpleAES.h"
#include <stdexcept>
#include <random>
#include <cstring>
#include <sstream>
#include <iomanip>

// AES S-box
static const uint8_t sbox[256] = {
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
};

// AES inverse S-box
static const uint8_t inv_sbox[256] = {
    0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
    0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
    0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
    0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
    0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
    0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
    0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
    0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
    0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
    0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
    0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
    0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
    0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
    0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
    0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
    0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
};

// Rcon for key expansion
static const uint8_t rcon[11] = {
    0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36
};

// Base64 encoding table
static const char base64_chars[] = 
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

// GF(2^8) multiplication helper function (forward declaration before use)
static uint8_t gf_mul(uint8_t a, uint8_t b) {
    uint8_t p = 0;
    for (int i = 0; i < 8; i++) {
        if (b & 1) {
            p ^= a;
        }
        bool hi_bit_set = (a & 0x80) != 0;
        a <<= 1;
        if (hi_bit_set) {
            a ^= 0x1B; // x^8 + x^4 + x^3 + x + 1
        }
        b >>= 1;
    }
    return p;
}

SimpleAES::SimpleAES(const std::vector<uint8_t>& key, const std::vector<uint8_t>& iv)
    : key(key), iv(iv) {
    if (key.size() != 32) {
        throw std::invalid_argument("Key must be 32 bytes for AES-256");
    }
    if (iv.size() != 16) {
        throw std::invalid_argument("IV must be 16 bytes");
    }
}

std::vector<uint8_t> SimpleAES::generateRandomBytes(size_t length) {
    std::vector<uint8_t> bytes(length);
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, 255);
    
    for (size_t i = 0; i < length; ++i) {
        bytes[i] = static_cast<uint8_t>(dis(gen));
    }
    return bytes;
}

std::string SimpleAES::base64Encode(const std::vector<uint8_t>& data) {
    std::string encoded;
    int val = 0;
    int valb = -6;
    
    for (uint8_t c : data) {
        val = (val << 8) + c;
        valb += 8;
        while (valb >= 0) {
            encoded.push_back(base64_chars[(val >> valb) & 0x3F]);
            valb -= 6;
        }
    }
    
    if (valb > -6) {
        encoded.push_back(base64_chars[((val << 8) >> (valb + 8)) & 0x3F]);
    }
    
    while (encoded.size() % 4) {
        encoded.push_back('=');
    }
    
    return encoded;
}

std::vector<uint8_t> SimpleAES::base64Decode(const std::string& encoded) {
    std::vector<uint8_t> decoded;
    std::vector<int> T(256, -1);
    
    for (int i = 0; i < 64; i++) {
        T[base64_chars[i]] = i;
    }
    
    int val = 0;
    int valb = -8;
    
    for (unsigned char c : encoded) {
        if (T[c] == -1) break;
        val = (val << 6) + T[c];
        valb += 6;
        if (valb >= 0) {
            decoded.push_back((val >> valb) & 0xFF);
            valb -= 8;
        }
    }
    
    return decoded;
}

std::vector<uint8_t> SimpleAES::pkcs7Pad(const std::vector<uint8_t>& data, size_t blockSize) {
    size_t padding = blockSize - (data.size() % blockSize);
    std::vector<uint8_t> padded = data;
    padded.insert(padded.end(), padding, static_cast<uint8_t>(padding));
    return padded;
}

std::vector<uint8_t> SimpleAES::pkcs7Unpad(const std::vector<uint8_t>& data) {
    if (data.empty()) {
        throw std::runtime_error("Cannot unpad empty data");
    }
    
    uint8_t padding = data.back();
    if (padding > 16 || padding == 0) {
        throw std::runtime_error("Invalid padding");
    }
    
    for (size_t i = data.size() - padding; i < data.size(); ++i) {
        if (data[i] != padding) {
            throw std::runtime_error("Invalid padding bytes");
        }
    }
    
    return std::vector<uint8_t>(data.begin(), data.end() - padding);
}

std::vector<uint32_t> SimpleAES::keyExpansion(const std::vector<uint8_t>& key) {
    std::vector<uint32_t> w(60); // 4 * (14 + 1) for AES-256
    
    // First 8 words from key
    for (int i = 0; i < 8; i++) {
        w[i] = (key[4*i] << 24) | (key[4*i+1] << 16) | (key[4*i+2] << 8) | key[4*i+3];
    }
    
    // Generate remaining words
    for (int i = 8; i < 60; i++) {
        uint32_t temp = w[i-1];
        
        if (i % 8 == 0) {
            // RotWord and SubWord
            temp = ((sbox[(temp >> 16) & 0xff] << 24) |
                    (sbox[(temp >> 8) & 0xff] << 16) |
                    (sbox[temp & 0xff] << 8) |
                    sbox[(temp >> 24) & 0xff]) ^ (rcon[i/8] << 24);
        } else if (i % 8 == 4) {
            // SubWord only
            temp = (sbox[(temp >> 24) & 0xff] << 24) |
                   (sbox[(temp >> 16) & 0xff] << 16) |
                   (sbox[(temp >> 8) & 0xff] << 8) |
                   sbox[temp & 0xff];
        }
        
        w[i] = w[i-8] ^ temp;
    }
    
    return w;
}

void SimpleAES::aesEncryptBlock(const uint8_t* in, uint8_t* out, const std::vector<uint32_t>& roundKeys) {
    uint8_t state[16];
    std::memcpy(state, in, 16);
    
    // Add round key 0
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            state[i*4 + j] ^= (roundKeys[i] >> (24 - j*8)) & 0xff;
        }
    }
    
    // 13 rounds for AES-256
    for (int round = 1; round <= 13; round++) {
        // SubBytes
        for (int i = 0; i < 16; i++) {
            state[i] = sbox[state[i]];
        }
        
        // ShiftRows
        uint8_t temp = state[1];
        state[1] = state[5]; state[5] = state[9]; state[9] = state[13]; state[13] = temp;
        
        temp = state[2];
        state[2] = state[10]; state[10] = temp;
        temp = state[6];
        state[6] = state[14]; state[14] = temp;
        
        temp = state[15];
        state[15] = state[11]; state[11] = state[7]; state[7] = state[3]; state[3] = temp;
        
        // MixColumns (skip on last round)
        if (round != 13) {
            uint8_t temp_col[4];
            for (int i = 0; i < 4; i++) {
                temp_col[0] = state[i*4];
                temp_col[1] = state[i*4 + 1];
                temp_col[2] = state[i*4 + 2];
                temp_col[3] = state[i*4 + 3];
                
                // MixColumns using GF(2^8) multiplication
                // Multiply by matrix: [2 3 1 1; 1 2 3 1; 1 1 2 3; 3 1 1 2]
                state[i*4]     = gf_mul(temp_col[0], 2) ^ gf_mul(temp_col[1], 3) ^ temp_col[2] ^ temp_col[3];
                state[i*4 + 1] = temp_col[0] ^ gf_mul(temp_col[1], 2) ^ gf_mul(temp_col[2], 3) ^ temp_col[3];
                state[i*4 + 2] = temp_col[0] ^ temp_col[1] ^ gf_mul(temp_col[2], 2) ^ gf_mul(temp_col[3], 3);
                state[i*4 + 3] = gf_mul(temp_col[0], 3) ^ temp_col[1] ^ temp_col[2] ^ gf_mul(temp_col[3], 2);
            }
        }
        
        // AddRoundKey
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                state[i*4 + j] ^= (roundKeys[round*4 + i] >> (24 - j*8)) & 0xff;
            }
        }
    }
    
    // Final round - AddRoundKey
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            state[i*4 + j] ^= (roundKeys[56 + i] >> (24 - j*8)) & 0xff;
        }
    }
    
    std::memcpy(out, state, 16);
}

void SimpleAES::aesDecryptBlock(const uint8_t* in, uint8_t* out, const std::vector<uint32_t>& roundKeys) {
    uint8_t state[16];
    std::memcpy(state, in, 16);
    
    // Add round key 14
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            state[i*4 + j] ^= (roundKeys[56 + i] >> (24 - j*8)) & 0xff;
        }
    }
    
    // 13 rounds in reverse
    for (int round = 13; round >= 1; round--) {
        // Inverse ShiftRows
        uint8_t temp = state[13];
        state[13] = state[9]; state[9] = state[5]; state[5] = state[1]; state[1] = temp;
        
        temp = state[2];
        state[2] = state[10]; state[10] = temp;
        temp = state[6];
        state[6] = state[14]; state[14] = temp;
        
        temp = state[3];
        state[3] = state[7]; state[7] = state[11]; state[11] = state[15]; state[15] = temp;
        
        // Inverse SubBytes
        for (int i = 0; i < 16; i++) {
            state[i] = inv_sbox[state[i]];
        }
        
        // AddRoundKey
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                state[i*4 + j] ^= (roundKeys[round*4 + i] >> (24 - j*8)) & 0xff;
            }
        }
        
        // Inverse MixColumns (skip on last round)
        if (round != 13) {
            uint8_t temp_col[4];
            for (int i = 0; i < 4; i++) {
                temp_col[0] = state[i*4];
                temp_col[1] = state[i*4 + 1];
                temp_col[2] = state[i*4 + 2];
                temp_col[3] = state[i*4 + 3];
                
                // Inverse MixColumns using GF(2^8) multiplication
                // Multiply by inverse matrix: [14 11 13 9; 9 14 11 13; 13 9 14 11; 11 13 9 14]
                state[i*4]     = gf_mul(temp_col[0], 0x0e) ^ gf_mul(temp_col[1], 0x0b) ^ 
                                 gf_mul(temp_col[2], 0x0d) ^ gf_mul(temp_col[3], 0x09);
                state[i*4 + 1] = gf_mul(temp_col[0], 0x09) ^ gf_mul(temp_col[1], 0x0e) ^ 
                                 gf_mul(temp_col[2], 0x0b) ^ gf_mul(temp_col[3], 0x0d);
                state[i*4 + 2] = gf_mul(temp_col[0], 0x0d) ^ gf_mul(temp_col[1], 0x09) ^ 
                                 gf_mul(temp_col[2], 0x0e) ^ gf_mul(temp_col[3], 0x0b);
                state[i*4 + 3] = gf_mul(temp_col[0], 0x0b) ^ gf_mul(temp_col[1], 0x0d) ^ 
                                 gf_mul(temp_col[2], 0x09) ^ gf_mul(temp_col[3], 0x0e);
            }
        }
    }
    
    // Add round key 0
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            state[i*4 + j] ^= (roundKeys[i] >> (24 - j*8)) & 0xff;
        }
    }
    
    std::memcpy(out, state, 16);
}

std::string SimpleAES::encrypt(const std::string& plainText) {
    if (plainText.empty()) {
        return "";
    }
    
    // Convert to bytes
    std::vector<uint8_t> plainBytes(plainText.begin(), plainText.end());
    
    // Apply PKCS7 padding
    plainBytes = pkcs7Pad(plainBytes, 16);
    
    // Prepare output
    std::vector<uint8_t> cipherBytes;
    std::vector<uint8_t> previousBlock = iv;
    
    // Expand key
    std::vector<uint32_t> roundKeys = keyExpansion(key);
    
    // CBC mode encryption
    for (size_t i = 0; i < plainBytes.size(); i += 16) {
        uint8_t block[16];
        uint8_t encrypted[16];
        
        // XOR with previous ciphertext block (CBC)
        for (int j = 0; j < 16; j++) {
            block[j] = plainBytes[i + j] ^ previousBlock[j];
        }
        
        // Encrypt block
        aesEncryptBlock(block, encrypted, roundKeys);
        
        // Store encrypted block
        for (int j = 0; j < 16; j++) {
            cipherBytes.push_back(encrypted[j]);
            previousBlock[j] = encrypted[j];
        }
    }
    
    // Base64 encode
    return base64Encode(cipherBytes);
}

std::string SimpleAES::decrypt(const std::string& cipherText) {
    if (cipherText.empty()) {
        return "";
    }
    
    try {
        // Base64 decode
        std::vector<uint8_t> cipherBytes = base64Decode(cipherText);
        
        if (cipherBytes.size() % 16 != 0) {
            throw std::runtime_error("Invalid ciphertext length");
        }
        
        // Prepare output
        std::vector<uint8_t> plainBytes;
        std::vector<uint8_t> previousBlock = iv;
        
        // Expand key
        std::vector<uint32_t> roundKeys = keyExpansion(key);
        
        // CBC mode decryption
        for (size_t i = 0; i < cipherBytes.size(); i += 16) {
            uint8_t block[16];
            uint8_t decrypted[16];
            
            // Copy encrypted block
            std::memcpy(block, &cipherBytes[i], 16);
            
            // Decrypt block
            aesDecryptBlock(block, decrypted, roundKeys);
            
            // XOR with previous ciphertext block (CBC)
            for (int j = 0; j < 16; j++) {
                plainBytes.push_back(decrypted[j] ^ previousBlock[j]);
            }
            
            // Update previous block
            previousBlock.assign(block, block + 16);
        }
        
        // Remove PKCS7 padding
        plainBytes = pkcs7Unpad(plainBytes);
        
        // Convert to string
        return std::string(plainBytes.begin(), plainBytes.end());
        
    } catch (const std::exception& e) {
        throw std::runtime_error(std::string("Decryption failed: ") + e.what());
    }
}
