# ==============================================================================
# Gyawun Music - Windows Build and Installer Script
# This script builds the Flutter Windows app and creates both .exe and .msi
# installers.
#
# Prerequisites:
#   - Flutter SDK (3.41.4+ recommended, use FVM)
#   - Visual Studio 2022 with C++ Desktop Development workload
#   - Inno Setup 6+ (for .exe installer)
#   - WiX Toolset v4+ (for .msi installer)
#   - .NET SDK 6+ (for WiX)
#
# Usage:
#   .\build_windows.ps1              # Build everything
#   .\build_windows.ps1 -SkipBuild   # Skip Flutter build, only create installers
#   .\build_windows.ps1 -ExeOnly     # Only create .exe installer
#   .\build_windows.ps1 -MsiOnly     # Only create .msi installer
# ==============================================================================

param(
    [switch]$SkipBuild = $false,
    [switch]$ExeOnly = $false,
    [switch]$MsiOnly = $false,
    [string]$BuildMode = "release",
    [string]$OutputDir = ".\releases"
)

$ErrorActionPreference = "Stop"

# ==============================================================================
# Configuration
# ==============================================================================
$AppName = "Gyawun Music"
$AppExeName = "gyawun.exe"
$AppVersion = "2.0.18"
$Publisher = "Jhelum"
$BuildDir = ".\build\windows\x64\runner\Release"
$InstallerDir = ".\installer"
$InnoSetupScript = "$InstallerDir\gyawun_setup.iss"
$WixScript = "$InstallerDir\gyawun_setup.wxs"

# ==============================================================================
# Helper Functions
# ==============================================================================
function Write-Step {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Error-Msg {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# ==============================================================================
# Step 1: Verify Prerequisites
# ==============================================================================
Write-Step "Checking Prerequisites"

# Check Flutter
if (Test-Command "flutter") {
    $flutterVersion = flutter --version | Select-String "Flutter" | Select-Object -First 1
    Write-Success "Flutter found: $flutterVersion"
} elseif (Test-Command "fvm") {
    Write-Host "Using FVM..." -ForegroundColor Yellow
    fvm flutter --version | Select-Object -First 1
} else {
    Write-Error-Msg "Flutter SDK not found! Please install Flutter and add it to PATH."
    exit 1
}

# Check Visual Studio
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsInstall = & $vsWhere -latest -property installationPath 2>$null
    if ($vsInstall) {
        Write-Success "Visual Studio found: $vsInstall"
    }
} else {
    Write-Error-Msg "Visual Studio not found! Install VS 2022 with C++ Desktop Development workload."
    Write-Host "Download: https://visualstudio.microsoft.com/downloads/" -ForegroundColor Yellow
    exit 1
}

# Check Inno Setup (for .exe)
if (-not $ExeOnly -eq $false) {
    $innoSetupPath = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    if (-not (Test-Path $innoSetupPath)) {
        $innoSetupPath = "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
    }
    if (Test-Path $innoSetupPath) {
        Write-Success "Inno Setup found: $innoSetupPath"
    } else {
        Write-Host "[WARN] Inno Setup not found. .exe installer will be skipped." -ForegroundColor Yellow
        Write-Host "Download: https://jrsoftware.org/isinfo.php" -ForegroundColor Yellow
        $script:InnoSetupAvailable = $false
    }
}

# Check WiX (for .msi)
if (-not $MsiOnly -eq $false) {
    if (Test-Command "wix") {
        Write-Success "WiX Toolset found"
    } elseif (Test-Command "candle") {
        Write-Success "WiX Toolset (legacy) found"
    } else {
        Write-Host "[WARN] WiX Toolset not found. .msi installer will be skipped." -ForegroundColor Yellow
        Write-Host "Install: dotnet tool install --global wix" -ForegroundColor Yellow
        $script:WixAvailable = $false
    }
}

# ==============================================================================
# Step 2: Build Flutter Windows App
# ==============================================================================
if (-not $SkipBuild) {
    Write-Step "Building Flutter Windows App ($BuildMode)"

    # Get dependencies
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    if (Test-Command "fvm") {
        fvm flutter pub get
    } else {
        flutter pub get
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Msg "Failed to install dependencies!"
        exit 1
    }
    Write-Success "Dependencies installed"

    # Generate localization
    Write-Host "Generating localization files..." -ForegroundColor Yellow
    if (Test-Command "fvm") {
        fvm dart run intl_utils:generate
    } else {
        dart run intl_utils:generate
    }

    # Build the Windows app
    Write-Host "Building Windows app..." -ForegroundColor Yellow
    if (Test-Command "fvm") {
        fvm flutter build windows --$BuildMode
    } else {
        flutter build windows --$BuildMode
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Msg "Flutter build failed!"
        exit 1
    }
    Write-Success "Flutter Windows build completed"
} else {
    Write-Host "[SKIP] Flutter build (using existing build)" -ForegroundColor Yellow
}

# ==============================================================================
# Step 3: Verify Build Output
# ==============================================================================
Write-Step "Verifying Build Output"

if (-not (Test-Path "$BuildDir\$AppExeName")) {
    Write-Error-Msg "Build output not found at: $BuildDir\$AppExeName"
    Write-Host "Please run the Flutter build first." -ForegroundColor Yellow
    exit 1
}
Write-Success "Build output found: $BuildDir\$AppExeName"

# List build contents
Write-Host "`nBuild contents:" -ForegroundColor Gray
Get-ChildItem $BuildDir -Recurse | Select-Object FullName, Length | Format-Table -AutoSize

# Calculate total size
$totalSize = (Get-ChildItem $BuildDir -Recurse | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "Total build size: $totalSizeMB MB" -ForegroundColor Gray

# ==============================================================================
# Step 4: Create .exe Installer (Inno Setup)
# ==============================================================================
if (-not $MsiOnly) {
    Write-Step "Creating .exe Installer (Inno Setup)"

    $innoSetupPath = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    if (-not (Test-Path $innoSetupPath)) {
        $innoSetupPath = "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
    }

    if (Test-Path $innoSetupPath) {
        # Create output directory
        if (-not (Test-Path $OutputDir)) {
            New-Item -ItemType Directory -Path $OutputDir | Out-Null
        }

        # Run Inno Setup
        Write-Host "Compiling Inno Setup script..." -ForegroundColor Yellow
        & $innoSetupPath $InnoSetupScript /DMyAppVersion=$AppVersion /O"$OutputDir"

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Msg "Inno Setup compilation failed!"
        } else {
            Write-Success "Inno Setup installer created successfully"
            $exeInstaller = Get-ChildItem "$OutputDir\GyawunMusic-Setup-*.exe" | Select-Object -First 1
            if ($exeInstaller) {
                Write-Success "Installer: $($exeInstaller.FullName)"
                Write-Success "Size: $([math]::Round($exeInstaller.Length / 1MB, 2)) MB"
            }
        }
    } else {
        Write-Error-Msg "Inno Setup not found! Skipping .exe installer."
        Write-Host "Install from: https://jrsoftware.org/isinfo.php" -ForegroundColor Yellow
    }
}

# ==============================================================================
# Step 5: Create .msi Installer (WiX Toolset)
# ==============================================================================
if (-not $ExeOnly) {
    Write-Step "Creating Setup.msi Installer (WiX Toolset)"

    if (Test-Command "wix") {
        # WiX v4
        Write-Host "Building with WiX v4..." -ForegroundColor Yellow

        # Create output directory
        if (-not (Test-Path $OutputDir)) {
            New-Item -ItemType Directory -Path $OutputDir | Out-Null
        }

        # Build MSI
        wix build $WixScript -out "$OutputDir\Setup.msi" -arch x64

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Msg "WiX build failed!"
        } else {
            Write-Success "WiX MSI installer created successfully"
            $msiInstaller = Get-Item "$OutputDir\Setup.msi" -ErrorAction SilentlyContinue
            if ($msiInstaller) {
                Write-Success "Installer: $($msiInstaller.FullName)"
                Write-Success "Size: $([math]::Round($msiInstaller.Length / 1MB, 2)) MB"
            }
        }
    } elseif (Test-Command "candle") {
        # WiX v3 (legacy)
        Write-Host "Building with WiX v3..." -ForegroundColor Yellow

        $wixObjFile = "$InstallerDir\gyawun_setup.wixobj"

        # Compile
        candle $WixScript -out $wixObjFile -arch x64
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Msg "WiX candle failed!"
            exit 1
        }

        # Link
        light $wixObjFile -out "$OutputDir\Setup.msi" -ext WixUIExtension
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Msg "WiX light failed!"
        } else {
            Write-Success "WiX MSI installer created successfully"
        }

        # Clean up
        Remove-Item $wixObjFile -ErrorAction SilentlyContinue
    } else {
        Write-Error-Msg "WiX Toolset not found! Skipping .msi installer."
        Write-Host "Install: dotnet tool install --global wix" -ForegroundColor Yellow
    }
}

# ==============================================================================
# Step 6: Summary
# ==============================================================================
Write-Step "Build Summary"

Write-Host "Application:  $AppName v$AppVersion" -ForegroundColor White
Write-Host "Publisher:    $Publisher" -ForegroundColor White
Write-Host "Build Mode:   $BuildMode" -ForegroundColor White
Write-Host "Output Dir:   $OutputDir" -ForegroundColor White

$installers = @()
if (Test-Path "$OutputDir\GyawunMusic-Setup-*.exe") {
    $exeFile = Get-ChildItem "$OutputDir\GyawunMusic-Setup-*.exe" | Select-Object -First 1
    $installers += $exeFile
    Write-Host "`n[.EXE Installer]" -ForegroundColor Green
    Write-Host "  File: $($exeFile.Name)" -ForegroundColor White
    Write-Host "  Size: $([math]::Round($exeFile.Length / 1MB, 2)) MB" -ForegroundColor White
}

if (Test-Path "$OutputDir\Setup.msi") {
    $msiFile = Get-Item "$OutputDir\Setup.msi"
    $installers += $msiFile
    Write-Host "`n[.MSI Installer]" -ForegroundColor Green
    Write-Host "  File: $($msiFile.Name)" -ForegroundColor White
    Write-Host "  Size: $([math]::Round($msiFile.Length / 1MB, 2)) MB" -ForegroundColor White
}

if ($installers.Count -eq 0) {
    Write-Host "`nNo installers were created. Check errors above." -ForegroundColor Red
    exit 1
}

Write-Host "`nBuild completed successfully!" -ForegroundColor Green
