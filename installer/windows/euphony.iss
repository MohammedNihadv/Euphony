; Inno Setup script for Euphony — produces a one-click Windows installer.
; Version is passed on the command line: iscc /DAppVersion=0.2.10 euphony.iss
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{9C4E2A61-3F7B-4E2D-9A1C-EUPHONYMUSIC01}
AppName=Euphony
AppVersion={#AppVersion}
AppPublisher=Euphony (Community)
AppPublisherURL=https://github.com/MohammedNihadv/Euphony
DefaultDirName={autopf}\Euphony
DefaultGroupName=Euphony
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\euphony.exe
OutputDir=installer_out
OutputBaseFilename=euphony-windows-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
; The whole Flutter release bundle.
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\Euphony"; Filename: "{app}\euphony.exe"
Name: "{group}\Uninstall Euphony"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Euphony"; Filename: "{app}\euphony.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\euphony.exe"; Description: "Launch Euphony"; Flags: nowait postinstall skipifsilent
