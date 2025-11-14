# Minimal build script for Strategy Pattern Demo
# For Windows PowerShell

Write-Host "🔨 Building Strategy Pattern Encryption Demo..." -ForegroundColor Cyan

# Compiler (adjust if needed)
$compiler = "g++"
$cppStandard = "-std=c++17"
$outputExe = "strategy_demo.exe"

# Source files
$sources = @(
    "strategy_pattern_demo.cpp",
    "core/EncryptionContext.cpp",
    "core/XOREncryptionStrategy.cpp",
    "core/NoEncryptionStrategy.cpp"
)

# Check if AES should be included (requires Crypto++)
$includeAES = Read-Host "Include AES encryption? (requires Crypto++) [y/N]"
if ($includeAES -eq "y" -or $includeAES -eq "Y") {
    $sources += "core/AESEncryptionStrategy.cpp"
    $cryptoLib = "-lcryptopp"
    Write-Host "✅ Including AES-256 encryption (Crypto++ library)" -ForegroundColor Green
} else {
    $cryptoLib = ""
    Write-Host "ℹ️  Building without AES (XOR and NoEncrypt only)" -ForegroundColor Yellow
}

# Build command
$buildCmd = "$compiler $cppStandard -o $outputExe $($sources -join ' ') $cryptoLib"

Write-Host "Command: $buildCmd" -ForegroundColor Gray
Write-Host ""

# Compile
try {
    Invoke-Expression $buildCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Build successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Run with: ./$outputExe" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Build error: $_" -ForegroundColor Red
}
