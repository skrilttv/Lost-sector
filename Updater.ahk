#NoEnv
#SingleInstance, Force
SetBatchLines, -1

; --- CONFIGURATION ---
GitHub_User := "skrilttv"
GitHub_Repo := "Lost-sector"

; --- SCRIPT VARIABLES ---
LocalScriptFile := "LostSectorCounter.ahk"
LocalVersionFile := "version.txt"
LocalLogoFile := "Logo.ico"

RemoteVersionURL := "https://raw.githubusercontent.com/" . GitHub_User . "/" . GitHub_Repo . "/main/version.txt"
RemoteScriptURL := "https://raw.githubusercontent.com/" . GitHub_User . "/" . GitHub_Repo . "/main/LostSectorCounter.ahk"
RemoteLogoURL := "https://raw.githubusercontent.com/" . GitHub_User . "/" . GitHub_Repo . "/main/Logo.ico"


; --- NEW, MORE ROBUST LOGIC ---

; 1. First-time run / Recovery check: Does the main script exist?
if !FileExist(LocalScriptFile)
{
    MsgBox, 48, First-Time Setup, The main script file is missing.`n`nThe updater will now download all necessary files from GitHub.
    DownloadAllFiles()
    RunLocalScript()
    ExitApp
}

; 2. If the script exists, proceed with the normal update check.
; Read local version
FileRead, localVersion, %LocalVersionFile%
if (ErrorLevel) { ; Handle case where version file is missing but script exists
    localVersion := "0"
}

; Download and read remote version
TempRemoteVersionFile := A_Temp . "\lsc_remote_version.tmp"
UrlDownloadToFile, %RemoteVersionURL%, %TempRemoteVersionFile%
if (ErrorLevel) {
    MsgBox, 16, Update Check Failed, Could not connect to GitHub. Please check your internet connection.`n`nStarting the existing local version.
    RunLocalScript()
    ExitApp
}
FileRead, remoteVersion, %TempRemoteVersionFile%
FileDelete, %TempRemoteVersionFile%

; Compare versions
if (remoteVersion > localVersion)
{
    MsgBox, 36, Update Available!, A new version (%remoteVersion%) is available. Your current version is %localVersion%.`n`nWould you like to download it now?
    IfMsgBox, Yes
    {
        DownloadAllFiles()
    }
}

; 3. Run the script
RunLocalScript()
ExitApp

; --- FUNCTIONS ---

DownloadAllFiles() {
    global
    SplashTextOn, 200, 50, Downloading..., Please wait...
    
    ; Download Script
    UrlDownloadToFile, %RemoteScriptURL%, %LocalScriptFile%
    if (ErrorLevel) {
        SplashTextOff
        MsgBox, 16, Error, Failed to download LostSectorCounter.ahk. Please check your internet connection and firewall settings.
        ExitApp
    }
    
    ; Download Version File
    UrlDownloadToFile, %RemoteVersionURL%, %LocalVersionFile%
    
    ; Download Logo
    UrlDownloadToFile, %RemoteLogoURL%, %LocalLogoFile%
    
    SplashTextOff
    MsgBox, 64, Download Complete, All files have been downloaded successfully.
}

RunLocalScript() {
    global LocalScriptFile
    if FileExist(LocalScriptFile) {
        Run, %LocalScriptFile%
    } else {
        MsgBox, 16, Critical Error, Could not find or download the main script file. Please check your internet connection and firewall settings, then try running the updater again.
    }
}