# Gyawun Music - Windows Build Guide

Complete guide for building Gyawun Music for Windows and creating installers (.exe and .msi).

## Prerequisites

### Required Software

| Software | Version | Purpose | Download |
|----------|---------|---------|----------|
| **Flutter SDK** | 3.41.4+ | Build framework | [flutter.dev](https://flutter.dev) |
| **FVM** | Latest | Flutter version manager | [fvm.app](https://fvm.app) |
| **Visual Studio 2022** | 17.0+ | C++ build tools | [visualstudio.microsoft.com](https://visualstudio.microsoft.com) |
| **Inno Setup** | 6.0+ | .exe installer creator | [jrsoftware.org](https://jrsoftware.org/isinfo.php) |
| **WiX Toolset** | 4.0+ | .msi installer creator | [wixtoolset.org](https://wixtoolset.org) |
| **.NET SDK** | 6.0+ | WiX dependency | [dotnet.microsoft.com](https://dotnet.microsoft.com) |

### Visual Studio Workloads

When installing Visual Studio 2022, make sure to select:
- **Desktop development with C++** workload
- Windows 10/11 SDK

## Quick Start

### Option 1: Automated Build (PowerShell)

```powershell
# Build everything (Flutter app + .exe + .msi)
.\installer\build_windows.ps1

# Skip Flutter build, only create installers
.\installer\build_windows.ps1 -SkipBuild

# Only create .exe installer
.\installer\build_windows.ps1 -ExeOnly

# Only create .msi installer
.\installer\build_windows.ps1 -MsiOnly
```

### Option 2: GitHub Actions (Automated CI/CD)

Push a tag with `-win` suffix to trigger the Windows release workflow:

```bash
git tag v2.0.18-win.1
git push origin v2.0.18-win.1
```

Or trigger manually via GitHub Actions UI with "Run workflow".

### Option 3: Manual Step-by-Step

```powershell
# Step 1: Get dependencies
flutter pub get

# Step 2: Generate localization
dart run intl_utils:generate

# Step 3: Build the Windows app
flutter build windows --release

# Step 4: Create .exe installer (Inno Setup)
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\gyawun_setup.iss

# Step 5: Create .msi installer (WiX)
wix build installer\gyawun_setup.wxs -out releases\Setup.msi -arch x64
```

## Build Output

After a successful build, the following files are generated:

| File | Location | Description |
|------|----------|-------------|
| `gyawun.exe` | `build\windows\x64\runner\Release\` | Main application executable |
| `GyawunMusic-Setup-v*.exe` | `releases\` | Inno Setup installer (recommended) |
| `Setup.msi` | `releases\` | WiX MSI installer (enterprise) |
| `GyawunMusic-v*-Portable.zip` | `releases\` | Portable version (no install) |

## Installer Features

### .exe Installer (Inno Setup)
- Professional installation wizard
- Multiple language support (English, Arabic, French, Spanish, Turkish, Hindi)
- Desktop and Start Menu shortcuts
- Auto-detects and installs Visual C++ Redistributable
- Clean uninstall with option to remove app data
- LZMA2 compression for smaller file size

### .msi Installer (WiX Toolset)
- Enterprise deployment support (Group Policy)
- Major upgrade support
- File type associations (.mp3, .m4a, .flac)
- Custom installation directory
- Silent install support: `msiexec /i Setup.msi /quiet`

## System Requirements

- Windows 10 64-bit or later
- 200 MB free disk space
- Internet connection for streaming
- Microsoft Visual C++ Redistributable 2022 (auto-installed)

## Project Structure

```
gyawun_music/
├── installer/
│   ├── gyawun_setup.iss          # Inno Setup script (.exe installer)
│   ├── gyawun_setup.wxs          # WiX Toolset script (.msi installer)
│   ├── heat_transform.xslt       # WiX heat transform
│   └── build_windows.ps1         # Automated build script
├── windows/
│   ├── CMakeLists.txt            # Windows CMake build
│   └── runner/
│       ├── main.cpp              # Win32 entry point
│       ├── Runner.rc             # Windows resources & version info
│       └── resources/
│           └── app_icon.ico      # Application icon
├── .github/workflows/
│   └── windows-release.yml       # GitHub Actions CI/CD
└── releases/                     # Output directory for installers
```

## Troubleshooting

### Build Errors

**"Visual Studio not found"**
- Install Visual Studio 2022 with "Desktop development with C++" workload
- Restart your terminal after installation

**"Flutter build failed"**
- Run `flutter doctor` to check your setup
- Make sure Windows desktop support is enabled: `flutter config --enable-windows-desktop`

**"Inno Setup not found"**
- Install Inno Setup 6 from https://jrsoftware.org/isinfo.php
- The script looks for it at `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`

**"WiX not found"**
- Install WiX: `dotnet tool install --global wix`
- Make sure .NET SDK 6+ is installed

### Runtime Errors

**"VCRUNTIME140.dll not found"**
- Install Microsoft Visual C++ Redistributable 2022
- Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe

**"Media player not working"**
- Make sure `mpv-2.dll` and `media_kit_*.dll` are in the same directory as `gyawun.exe`
