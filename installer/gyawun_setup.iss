; ==============================================================================
; Gyawun Music - Inno Setup Installer Script
; Creates: GyawunMusic-Setup.exe
; ==============================================================================

#define MyAppName "Gyawun Music"
#define MyAppVersion "2.0.18"
#define MyAppPublisher "Jhelum"
#define MyAppURL "https://github.com/sheikhhaziq/gyawun_music"
#define MyAppExeName "gyawun.exe"
#define MyAppCopyright "Copyright (C) 2026 Jhelum. All rights reserved."
#define MyAppDescription "Ad-free YouTube Music streaming and download app"

[Setup]
; Basic application info
AppId={{B8E3F2A1-9C4D-4E5F-A6B7-C8D9E0F1A2B3}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\LICENSE
OutputDir=..\releases
OutputBaseFilename=GyawunMusic-Setup-v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

; Windows version requirements (Windows 10+)
MinVersion=10.0

; Privileges
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog commandline

; Architecture
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Uninstall info
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}

; UI settings
SetupLogging=yes
CloseApplications=force
RestartApplications=no

; Size estimate (approx 200 MB for Flutter Windows app with media_kit)
ExtraDiskSpaceRequired=209715200

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "hindi"; MessagesFile: "compiler:Languages\Hindi.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode
Name: "startmenuicon"; Description: "Create Start Menu shortcut"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Main executable
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; Flutter engine DLL
Source: "..\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion

; Media kit libraries
Source: "..\build\windows\x64\runner\Release\media_kit_*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "..\build\windows\x64\runner\Release\mpv-2.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

; All other DLLs in the release directory
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion

; Data folder (Flutter assets)
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Check if Visual C++ Redistributable is installed
function IsVCRedistInstalled: Boolean;
var
  ResultCode: Integer;
begin
  // Check for VC++ 2022 x64
  Result := RegKeyExists(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64');
  if not Result then
    Result := RegKeyExists(HKLM, 'SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64');
end;

// Download and install VC++ Redistributable if needed
procedure InstallVCRedist;
var
  ResultCode: Integer;
  TempPath: string;
begin
  TempPath := ExpandConstant('{tmp}\vc_redist.x64.exe');
  // Download VC++ Redistributable 2022
  DownloadTemporaryFile('https://aka.ms/vs/17/release/vc_redist.x64.exe', TempPath, '', nil);
  Exec(TempPath, '/install /quiet /norestart', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
end;

function InitializeSetup: Boolean;
begin
  Result := True;
  // Warn user if VC++ Redistributable is not installed
  if not IsVCRedistInstalled then
  begin
    if MsgBox('Microsoft Visual C++ Redistributable is not installed. ' +
              'Gyawun Music requires it to run. Do you want to install it now?',
              mbConfirmation, MB_YESNO) = IDYES then
    begin
      InstallVCRedist;
    end
    else
    begin
      MsgBox('Gyawun Music may not work correctly without Visual C++ Redistributable.',
             mbInformation, MB_OK);
    end;
  end;
end;

// Clean up app data on uninstall if user chooses
function UninstallAppData: Boolean;
var
  AppDataPath: string;
begin
  Result := False;
  AppDataPath := ExpandConstant('{userappdata}\com.jhelum.gyawun');
  if DirExists(AppDataPath) then
  begin
    if MsgBox('Do you want to remove all Gyawun Music data including downloads, playlists, and settings?',
              mbConfirmation, MB_YESNO) = IDYES then
    begin
      DelTree(AppDataPath, True, True, True);
      Result := True;
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    UninstallAppData;
  end;
end;
