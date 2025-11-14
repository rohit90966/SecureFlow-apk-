package com.example.last_final

class NativePasswordService {
    // Existing native methods
    external fun createManager(): Long
    external fun destroyManager(managerPtr: Long)
    external fun setDatabasePath(managerPtr: Long, dbPath: String)
    external fun addPassword(managerPtr: Long, title: String, username: String,
                             password: String, category: Int, website: String, notes: String): Boolean
    external fun deletePassword(managerPtr: Long, id: Int): Boolean
    external fun getAllPasswordsJson(managerPtr: Long): String
    external fun getPasswordsByCategoryJson(managerPtr: Long, category: Int): String
    external fun searchPasswordsJson(managerPtr: Long, query: String): String
    external fun getCategoryStatsJson(managerPtr: Long): String
    external fun getTotalPasswordCount(managerPtr: Long): Int
    external fun analyzePassword(managerPtr: Long, password: String): String
    external fun generateRandomPassword(managerPtr: Long, length: Int): String
    external fun generateFromFavorite(managerPtr: Long, favorite: String, length: Int): String
    external fun generateMemorablePassword(managerPtr: Long): String
    external fun generatePin(managerPtr: Long, length: Int): String

    // NEW METHODS FOR PASSWORD SUGGESTIONS
    external fun analyzePasswordDetailed(managerPtr: Long, password: String): String
    external fun getPasswordStrength(password: String): String
    external fun generateStrongPassword(managerPtr: Long, length: Int,
                                        includeUpper: Boolean, includeLower: Boolean,
                                        includeDigits: Boolean, includeSymbols: Boolean): String

    companion object {
        init {
            System.loadLibrary("advanced_password_manager")
        }
    }
}