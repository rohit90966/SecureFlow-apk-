#!/bin/bash
# Quick test build script for Strategy Pattern
# Run this to verify everything compiles

echo "🔨 Building Strategy Pattern Test Suite..."
echo ""

# Check if g++ is available
if ! command -v g++ &> /dev/null; then
    echo "❌ g++ not found. Please install a C++ compiler."
    exit 1
fi

echo "✅ Compiler found: $(g++ --version | head -n 1)"
echo ""

# Build test suite (without AES to avoid Crypto++ dependency)
echo "📦 Compiling test suite (XOR + NoEncrypt only)..."
g++ -std=c++17 -Wall -Wextra -o test_strategy \
    test_strategy_pattern.cpp \
    core/EncryptionContext.cpp \
    core/XOREncryptionStrategy.cpp \
    core/NoEncryptionStrategy.cpp

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🧪 Running tests..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ./test_strategy
    exit_code=$?
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ $exit_code -eq 0 ]; then
        echo ""
        echo "🎉 All tests passed! Your implementation is correct!"
        echo ""
        echo "📝 Next steps:"
        echo "   1. Review the code in core/ directory"
        echo "   2. Read SUBMISSION_SUMMARY.md for submission guide"
        echo "   3. Read QUICK_REFERENCE.md for presentation tips"
        echo ""
        echo "✅ Ready for course submission!"
    else
        echo ""
        echo "⚠️  Some tests failed. Please review the output above."
    fi
else
    echo "❌ Build failed. Check error messages above."
    exit 1
fi
