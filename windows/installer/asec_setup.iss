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
; ONE place for everyone (06/11/2026, from ENGX): the "for me only / for all
; users" question let updates land in a SECOND folder, leaving an old copy
; next to the new one — two copies crash each other. Always for this user
; (AppData\Local\Programs\ASEC): no admin needed.
PrivilegesRequired=lowest
; Always the app's own folder — never a folder remembered from an install
; entry another app wrote under the same old ID (ASEC / Eduneers shared one).
UsePreviousAppDir=no
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[InstallDelete]
; CLEAN UPDATE: the previous version's program files go first, so an update
; never runs new code next to old DLLs / data. Sign-in, settings and offline
; lessons ({userappdata}) are KEPT.
Type: filesandordirs; Name: "{app}\data"
Type: files; Name: "{app}\*.dll"
Type: files; Name: "{app}\{#AppExe}"
; Old caches (rebuilt by the app) and Firebase's local counters.
Type: filesandordirs; Name: "{localappdata}\com.asec\ASEC"
Type: filesandordirs; Name: "{localappdata}\firebase-heartbeat"

[UninstallDelete]
; UNINSTALL REMOVES EVERYTHING of ASEC: program, settings, sign-in, offline
; lessons, caches, start / crash journals.
Type: filesandordirs; Name: "{app}"
Type: filesandordirs; Name: "{userappdata}\com.asec\ASEC"
Type: dirifempty; Name: "{userappdata}\com.asec"
Type: filesandordirs; Name: "{localappdata}\com.asec\ASEC"
Type: dirifempty; Name: "{localappdata}\com.asec"
Type: filesandordirs; Name: "{localappdata}\ASEC"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[Code]
const
  UninstRoot = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\';
  OwnKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{6F3A2B9E-4C1D-4E7A-9B52-1D8E0A5C7F31}_is1';
  { The ID older ASEC installers used. Eduneers was copied from ASEC and had
    ASEC's ID, so an entry under it is only ASEC's when its name says so. }
  LegacyKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{6F3A2B9E-4C1D-4E7A-9B52-1D8E0A5C7F31}_is1';

{ The install entry at [Key] belongs to ASEC (not to another app). }
function IsOurs(RootKey: Integer; const Key: String): Boolean;
var
  name: String;
begin
  Result := RegQueryStringValue(RootKey, Key, 'DisplayName', name) and
            (Pos(Lowercase('{#AppName}'), Lowercase(Trim(name))) = 1);
end;

{ An old ASEC installed "for all users" (Program Files), if any. }
function OldAllUsersUninstaller(var Cmd: String): Boolean;
begin
  Result := False;
  if IsOurs(HKLM64, OwnKey) then Result := RegQueryStringValue(HKLM64, OwnKey, 'UninstallString', Cmd)
  else if IsOurs(HKLM32, OwnKey) then Result := RegQueryStringValue(HKLM32, OwnKey, 'UninstallString', Cmd)
  else if (LegacyKey <> OwnKey) and IsOurs(HKLM64, LegacyKey) then Result := RegQueryStringValue(HKLM64, LegacyKey, 'UninstallString', Cmd)
  else if (LegacyKey <> OwnKey) and IsOurs(HKLM32, LegacyKey) then Result := RegQueryStringValue(HKLM32, LegacyKey, 'UninstallString', Cmd);
end;

{ ASEC must not be running while its files are replaced or removed. }
procedure KillApp();
var
  rc: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /T /IM {#AppExe}', '', SW_HIDE, ewWaitUntilTerminated, rc);
  Sleep(800);
end;

{ Firestore's local database (found by the Firebase project id asec-a811b).
  Old CPUs crash reading it (0xc000001d); the app rebuilds what it needs. }
procedure DeleteFirestoreCache(const Dir: String; Depth: Integer);
var
  fr: TFindRec;
begin
  if Depth > 3 then exit;
  if FindFirst(Dir + '\*', fr) then
  try
    repeat
      if (fr.Name <> '.') and (fr.Name <> '..') and
         ((fr.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0) then
      begin
        if Pos('asec-a811b', Lowercase(fr.Name)) > 0 then
          DelTree(Dir + '\' + fr.Name, True, True, True)
        else
          DeleteFirestoreCache(Dir + '\' + fr.Name, Depth + 1);
      end;
    until not FindNext(fr);
  finally
    FindClose(fr);
  end;
end;

{ Before any file is copied: close ASEC, forget its entry under the old
  shared ID, remove an old "all users" copy (two copies crash each other),
  clear the old Firestore cache. }
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  cmd: String;
  rc, waited: Integer;
begin
  Result := '';
  KillApp();
  { This user's ASEC entry under the old ID: same folder, so the files are
    simply replaced — only the stale entry in "Installed apps" goes. }
  if (LegacyKey <> OwnKey) and IsOurs(HKCU, LegacyKey) then
    RegDeleteKeyIncludingSubkeys(HKCU, LegacyKey);
  if OldAllUsersUninstaller(cmd) then
  begin
    { Windows asks once for permission (it is in Program Files). }
    if ShellExec('runas', RemoveQuotes(cmd), '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART', '',
                 SW_HIDE, ewWaitUntilTerminated, rc) then
    begin
      { The uninstaller hands over to a temporary copy: wait until it is done. }
      waited := 0;
      while OldAllUsersUninstaller(cmd) and (waited < 60) do
      begin
        Sleep(500);
        waited := waited + 1;
      end;
    end
    else
      MsgBox('An older ASEC is also installed for all users (in Program Files).' + #13#10 + #13#10 +
        'Please remove it after this update:' + #13#10 +
        'Windows Settings > Apps > Installed apps > ASEC (the older one) > Uninstall.' + #13#10 + #13#10 +
        'Two copies of ASEC on one PC can make it close by itself.', mbInformation, MB_OK);
  end;
  DeleteFirestoreCache(ExpandConstant('{localappdata}\firestore'), 0);
end;

{ 07/11/2026 (from ENGX): before copying, nothing of an older version stays
  in the program folder (only when that folder is really this app's, never a
  folder someone picked like the Desktop); after copying, every file the app
  needs to start must be there — an antivirus that quarantined one makes the
  app close at once or show a white window, so say so now. }
{ NO GRAPHICS DRIVER (11/11/2026): Windows lists only "Microsoft Basic
  Display Adapter" / "Basic Render Driver". Lessons then failed with "Could
  not open codec". The app now decodes them on the CPU by itself; the
  member is told once here that installing the driver makes them smoother. }
function NoGraphicsDriver(): Boolean;
var
  Locator, Service, Items, Item: Variant;
  i, n: Integer;
  name: String;
begin
  Result := False;
  try
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    Service := Locator.ConnectServer('.', 'root\CIMV2');
    Items := Service.ExecQuery('SELECT Name FROM Win32_VideoController');
    n := Items.Count;
    if n = 0 then exit;
    Result := True;
    for i := 0 to n - 1 do
    begin
      Item := Items.ItemIndex(i);
      name := Lowercase(Item.Name);
      if (Pos('basic display', name) = 0) and (Pos('basic render', name) = 0) then
        Result := False;
    end;
  except
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  missing, dir: String;
  i: Integer;
  need: array of String;
begin
  if CurStep = ssInstall then
  begin
    dir := ExpandConstant('{app}');
    if (CompareText(ExtractFileName(RemoveBackslashUnlessRoot(dir)), 'ASEC') = 0) and DirExists(dir) then
      DelTree(dir + '\*', False, True, True);
    exit;
  end;
  if CurStep <> ssPostInstall then exit;
  SetArrayLength(need, 8);
  need[0] := '{#AppExe}';
  need[1] := 'flutter_windows.dll';
  need[2] := 'data\app.so';
  need[3] := 'data\icudtl.dat';
  need[4] := 'msvcp140.dll';
  need[5] := 'vcruntime140.dll';
  need[6] := 'vcruntime140_1.dll';
  need[7] := 'libmpv-2.dll';
  missing := '';
  for i := 0 to GetArrayLength(need) - 1 do
    if not FileExists(ExpandConstant('{app}\') + need[i]) then
      missing := missing + #13#10 + '  ' + need[i];
  if missing <> '' then
    MsgBox('Some ASEC files were not installed:' + missing + #13#10 + #13#10 +
      'Usually an antivirus removed them. Add the ASEC folder as an exception in the antivirus, ' +
      'then run the installer again.', mbError, MB_OK);
  if (not WizardSilent()) and NoGraphicsDriver() then
    MsgBox('This PC has no graphics driver installed (Windows shows "Microsoft Basic Display Adapter").' + #13#10 + #13#10 +
      'ASEC will still play lessons, using the processor instead of the graphics card, but video ' +
      'is smoother with the driver. Install it from Windows Update (Settings > Windows Update > ' +
      'Advanced options > Optional updates) or from the Intel / AMD / NVIDIA website.', mbInformation, MB_OK);
end;

function InitializeUninstall(): Boolean;
begin
  Result := True;
  KillApp();
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    DeleteFirestoreCache(ExpandConstant('{localappdata}\firestore'), 0);
end;
