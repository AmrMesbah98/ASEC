; ASEC — Windows installer (Inno Setup 6).
;
; Built by .github/workflows/windows-release.yml after `flutter build windows`:
;   iscc /DAppVersion=1.0.2 /DSourceDir=<Release folder> /DOutputDir=<out> asec_setup.iss
; Produces ASEC-Setup.exe: installs to Program Files\ASEC, adds Start-menu
; and (optional) desktop shortcuts and an uninstaller, and offers to start
; the app at the end. Installing a newer version over an older one upgrades
; it in place (same AppId — never change it).

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\installer"
#endif

#define AppName "ASEC"
#define AppPublisher "ASEC Engineering Consultants"
#define AppExe "ASEC.exe"

[Setup]
AppId={{6F3A2B9E-4C1D-4E7A-9B52-1D8E0A5C7F31}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://asecbim.com
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#AppExe}
SetupIconFile=..\runner\resources\app_icon.ico
OutputDir={#OutputDir}
OutputBaseFilename=ASEC-Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
