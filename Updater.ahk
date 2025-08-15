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
; --- NEW: GitHub API URL for commits (changelog) ---
RemoteChangelogURL := "https://api.github.com/repos/" . GitHub_User . "/" . GitHub_Repo . "/commits"


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
    ; --- NEW: Fetch and display changelog ---
    changelog := GetChangelog()
    MsgBox, 36, Update Available!, A new version (%remoteVersion%) is available. Your current version is %localVersion%.`n`nRecent Changes:`n%changelog%`n`nWould you like to download it now?
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

; --- NEW: FUNCTION TO GET CHANGELOG ---
GetChangelog() {
    global RemoteChangelogURL
    TempChangelogFile := A_Temp . "\lsc_changelog.tmp"
    UrlDownloadToFile, %RemoteChangelogURL%, %TempChangelogFile%
    if (ErrorLevel) {
        return "Could not retrieve changelog."
    }
    
    FileRead, json_data, %TempChangelogFile%
    FileDelete, %TempChangelogFile%
    
    commits := JSON.Load(json_data)
    changelogText := ""
    
    ; Loop through the 5 most recent commits
    Loop, % (commits.MaxIndex() > 5 ? 5 : commits.MaxIndex())
    {
        commit_message := commits[A_Index].commit.message
        changelogText .= "- " . commit_message . "`n"
    }
    
    return RTrim(changelogText, "`n")
}

; --- NEW: EMBEDDED JSON PARSER ---
; JSON.ahk by Coco - https://github.com/cocobelgica/AutoHotkey-JSON
class JSON {
    Load(ByRef str) {
        static q := Chr(34)
        str := Trim(str)
        If (SubStr(str, 1, 1) = "[" && SubStr(str, 0) = "]")
            return this.ParseArray(str)
        If (SubStr(str, 1, 1) = "{" && SubStr(str, 0) = "}")
            return this.ParseObject(str)
    }
    
    ParseObject(ByRef str) {
        obj := {}
        str := SubStr(str, 2, -1)
        Loop {
            p1 := InStr(str, ":")
            key := Trim(SubStr(str, 1, p1-1), " " . this.q)
            str := SubStr(str, p1+1)
            p2 := this.FindBalanced(str)
            val := SubStr(str, 1, p2)
            obj[key] := this.ParseValue(val)
            str := SubStr(str, p2+1)
            If (SubStr(Trim(str), 1, 1) = ",")
                str := SubStr(Trim(str), 2)
            Else
                break
        }
        return obj
    }
    
    ParseArray(ByRef str) {
        arr := []
        str := SubStr(str, 2, -1)
        Loop {
            p := this.FindBalanced(str)
            val := SubStr(str, 1, p)
            arr.Push(this.ParseValue(val))
            str := SubStr(str, p+1)
            If (SubStr(Trim(str), 1, 1) = ",")
                str := SubStr(Trim(str), 2)
            Else
                break
        }
        return arr
    }
    
    ParseValue(ByRef str) {
        str := Trim(str)
        first_char := SubStr(str, 1, 1)
        last_char := SubStr(str, 0)
        
        If (first_char = "{" && last_char = "}")
            return this.ParseObject(str)
        If (first_char = "[" && last_char = "]")
            return this.ParseArray(str)
        If (first_char = this.q && last_char = this.q)
            return this.Unescape(SubStr(str, 2, -1))
        If (str = "true")
            return true
        If (str = "false")
            return false
        If (str = "null")
            return ""
        If str is number
            return str + 0
        return str
    }
    
    FindBalanced(ByRef str) {
        len := StrLen(str)
        p := 1
        in_string := false
        brace_level := 0
        bracket_level := 0
        
        Loop, % len {
            char := SubStr(str, A_Index, 1)
            
            if (in_string) {
                if (char = this.q && SubStr(str, A_Index-1, 1) != "\")
                    in_string := false
            } else {
                if (char = this.q)
                    in_string := true
                else if (char = "{")
                    brace_level++
                else if (char = "}")
                    brace_level--
                else if (char = "[")
                    bracket_level++
                else if (char = "]")
                    bracket_level--
                else if (char = "," && brace_level = 0 && bracket_level = 0)
                    return A_Index - 1
            }
        }
        return len
    }
    
    Unescape(ByRef str) {
        static replacements := {b: "`b", f: "`f", n: "`n", r: "`r", t: "`t", q: """", bs: "\"}
        For k, v in replacements
            str := StrReplace(str, "\" . k, v)
        return str
    }
}
