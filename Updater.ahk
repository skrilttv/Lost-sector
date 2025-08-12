#NoEnv
#SingleInstance, Force
SetBatchLines, -1

; --- CONFIGURATION: Automatically filled out for you ---
GitHub_User := "skrilttv"
GitHub_Repo := "Lost-sector"

; --- SCRIPT VARIABLES ---
LocalScriptFile := "LostSectorCounter.ahk"
LocalVersionFile := "version.txt"
RemoteVersionURL := "https://raw.githubusercontent.com/" . GitHub_User . "/" . GitHub_Repo . "/main/version.txt"
RemoteScriptURL := "https://raw.githubusercontent.com/" . GitHub_User . "/" . GitHub_Repo . "/main/LostSectorCounter.ahk"

; --- CHECK FOR UPDATES ---

; 1. Read the local version
localVersion := "0" ; Default to 0 if no local version file exists
if FileExist(LocalVersionFile)
    FileRead, localVersion, %LocalVersionFile%

; 2. Download and read the remote (GitHub) version
TempRemoteVersionFile := A_Temp . "\lsc_remote_version.tmp"
UrlDownloadToFile, %RemoteVersionURL%, %TempRemoteVersionFile%

; Check if the download was successful
if (ErrorLevel) {
    MsgBox, 16, Update Check Failed, Could not download the version file from GitHub. Please check your internet connection.`n`nWill now attempt to start the local version.
    RunLocalScript()
    ExitApp
}

FileRead, remoteVersion, %TempRemoteVersionFile%
FileDelete, %TempRemoteVersionFile% ; Clean up the temporary file

; 3. Compare versions
if (remoteVersion > localVersion)
{
    ; New version found, prompt the user to update
    MsgBox, 36, Update Available!, A new version (%remoteVersion%) is available. Your current version is %localVersion%.`n`nWould you like to download it now?
    IfMsgBox, No
    {
        ; User declined update, run the existing local script
        RunLocalScript()
        ExitApp
    }
    
    ; User agreed, download the new script and version file
    SplashTextOn, 200, 50, Updating..., Downloading new version, please wait...
    UrlDownloadToFile, %RemoteScriptURL%, %LocalScriptFile%
    if (ErrorLevel) {
        MsgBox, 16, Update Failed, Could not download the new script file. The program will not be updated.
    } else {
        UrlDownloadToFile, %RemoteVersionURL%, %LocalVersionFile% ; Update the local version file
        MsgBox, 64, Update Complete, The script has been updated to version %remoteVersion%.
    }
    SplashTextOff
}

; 4. Run the main script (either the old or the newly updated one)
RunLocalScript()
ExitApp


; --- Function to run the main script ---
RunLocalScript() {
    global LocalScriptFile
    if FileExist(LocalScriptFile) {
        Run, %LocalScriptFile%
    } else {
        MsgBox, 16, Error, Could not find the main script file (%LocalScriptFile%). The updater may need to run again to download it.
    }
}
