#define ProjectRoot "C:\Games\PIF"
#define AppName "Kuray Infinite Fusion"
#define AppVersion "2026.04.22"
#define AppPublisher "Kuray Infinite Fusion"
#define AppExeName "Game.exe"
#define AppCompatExeName "Game-compatibility.exe"
#define AppId "{{F7E2C955-11C8-4D0A-B25B-02AA6DD15C2C}}"
#define OutputBase "PIF-Setup-20260422-no-csf"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={code:GetDefaultInstallDir}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=commandline
Compression=lzma2
SolidCompression=yes
CompressionThreads=auto
LZMANumBlockThreads=8
WizardStyle=modern
UsePreviousAppDir=yes
UsePreviousGroup=yes
UninstallDisplayIcon={app}\{#AppExeName}
SetupLogging=yes
OutputDir={#ProjectRoot}\dist
OutputBaseFilename={#OutputBase}
VersionInfoVersion=2026.4.22.0
VersionInfoDescription={#AppName} Installer
VersionInfoCompany={#AppPublisher}
ArchitecturesAllowed=x86 x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
ChangesAssociations=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"

[Components]
Name: "main"; Description: "Game files"; Types: full; Flags: fixed

[Dirs]
Name: "{app}\Cache"
Name: "{app}\ExportedPokemons"
Name: "{app}\Logs"

[Files]
Source: "{#ProjectRoot}\Audio\*"; DestDir: "{app}\Audio"; Flags: ignoreversion recursesubdirs sortfilesbyextension; Components: main
Source: "{#ProjectRoot}\Data\*"; DestDir: "{app}\Data"; Excludes: ".idea\*,.DS_Store,encounters.json,starter_sets.json,trainer_hooks.json,species\*,sprites\sprites_rate_limit.log"; Flags: ignoreversion recursesubdirs sortfilesbyextension; Components: main
Source: "{#ProjectRoot}\Fonts\*"; DestDir: "{app}\Fonts"; Flags: ignoreversion recursesubdirs sortfilesbyextension; Components: main
Source: "{#ProjectRoot}\Graphics\*"; DestDir: "{app}\Graphics"; Excludes: "Battlers\1202\*,Battlers\1203\*,Battlers\1204\*,Battlers\1205\*,Battlers\1206\*,CustomBattlers\indexed\1202\*,CustomBattlers\indexed\1203\*,CustomBattlers\indexed\1204\*,CustomBattlers\indexed\1205\*,CustomBattlers\indexed\1206\*,Icons\icon1202.png,Icons\icon1203.png,Icons\icon1204.png,Icons\icon1205.png,Icons\icon1206.png,Pokemon\Back\CSF_*.png,Pokemon\Front\CSF_*.png,Pokemon\Icons\CSF_*.png"; Flags: ignoreversion recursesubdirs sortfilesbyextension; Components: main
Source: "{#ProjectRoot}\Libs\*"; DestDir: "{app}\Libs"; Flags: ignoreversion recursesubdirs sortfilesbyextension; Components: main
Source: "{#ProjectRoot}\Mods\*"; DestDir: "{app}\Mods"; Excludes: "compat_report.txt,mod_manager_state.json,custom_species_framework\*"; Flags: ignoreversion recursesubdirs sortfilesbyextension; Components: main
Source: "{#ProjectRoot}\KIFM\*"; DestDir: "{app}\KIFM"; Excludes: "platinum_uuids.txt,discord_ids.txt,pending_discord_link.txt,coop_debug.log,pvp_wins.txt,discord_link.log"; Flags: ignoreversion recursesubdirs sortfilesbyextension; Components: main
Source: "{#ProjectRoot}\Game.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\Game-compatibility.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\Game.ini"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\mkxp.json"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\README.md"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\PIF_readme.txt"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\PIF_Credits.txt"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\RGSS100J.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\RGSS104E.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\Shiny Finder.bat"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\Shiny Finder.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\Shiny Finder.pck"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\x64-msvcrt-ruby300.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\x64-msvcrt-ruby310.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: main
Source: "{#ProjectRoot}\zlib1.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: main

[Icons]
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Comment: "{#AppName}"; IconFilename: "{app}\{#AppExeName}"
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Comment: "{#AppName}"; IconFilename: "{app}\{#AppExeName}"
Name: "{group}\{#AppName} Compatibility Mode"; Filename: "{app}\{#AppCompatExeName}"; WorkingDir: "{app}"; Comment: "{#AppName} Compatibility Mode"; IconFilename: "{app}\{#AppCompatExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent unchecked

[Code]
function GetDefaultInstallDir(Param: string): string;
begin
  Result := GetEnv('USERPROFILE') + '\Games\{#AppName}';
end;
