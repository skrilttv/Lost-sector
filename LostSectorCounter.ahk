; --- MODIFIED: Check if the custom icon exists before applying it ---
if FileExist("logo.ico")
    Menu, Tray, Icon, logo.ico, , 1

#NoEnv
#SingleInstance, Force
SetBatchLines, -1

; Global variables
global LostSectorsCount := 0
global TotalClears := 0
global CurrentTime := 0
global FastestTime := 0
global PastTime := 0
global TimerRunning := false
global SectorName := ""
global RunCompleted := false
global StartTime := 0
global Paused := false
global PauseStartTime := 0
global TotalPausedTime := 0
global PrimeDrops := 0
global firstDetectionDone := false
global cooldownActive := false
global firstDetectionTime := 0
global postRunCooldownActive := false
global postRunCooldownStartTime := 0
global purpleX := 0
global purpleY := 0
global selectedRes := ""

; Main execution now starts with resolution selection
ShowResolutionSelection()
return

; STEP 1: Resolution Selection GUI
ShowResolutionSelection() {
    if WinExist("LostSectorsCounter")
        Gui, Main:Destroy
    if WinExist("Lost Sector Selection")
        Gui, Select:Destroy
    if WinExist("Keybinds Reference")
        Gui, Keybinds:Destroy
        
    Gui, Res:New, +AlwaysOnTop -Caption +Border
    Gui, Res:+LastFound
    OnMessage(0x201, "WM_LBUTTONDOWN")
    Gui, Res:Color, 212121
    Gui, Res:Font, cWhite s12, Arial
    Gui, Res:Add, Text, x10 y10 w180 Center, Step 1: Select Resolution
    Gui, Res:Font, s10
    Gui, Res:Add, Button, x25 y+20 w150 gSelect1440p, 1440p (2560x1440)
    Gui, Res:Add, Button, x25 y+10 w150 gSelect1080p, 1080p (1920x1080)
    Gui, Res:Show, w200 h130, Resolution Selection
    return
}

Select1440p:
    global selectedRes := "1440p"
    Gui, Res:Destroy
    ShowHudSelection()
return

Select1080p:
    global selectedRes := "1080p"
    Gui, Res:Destroy
    ShowHudSelection()
return

; STEP 2: HUD Zoom Selection GUI
ShowHudSelection() {
    Gui, Hud:New, +AlwaysOnTop -Caption +Border
    Gui, Hud:+LastFound
    OnMessage(0x201, "WM_LBUTTONDOWN")
    Gui, Hud:Color, 212121
    Gui, Hud:Font, cWhite s12, Arial
    Gui, Hud:Add, Text, x10 y10 w180 Center, Step 2: Select HUD Size
    Gui, Hud:Font, s10
    Gui, Hud:Add, Button, x25 y+20 w150 gSelectHudZoomedIn, Default (Zoomed In)
    Gui, Hud:Add, Button, x25 y+10 w150 gSelectHudZoomedOut, Zoomed Out
    Gui, Hud:Show, w200 h130, HUD Selection
    return
}

; --- Handlers with Final Coordinates ---
SelectHudZoomedIn:
    global selectedRes, purpleX, purpleY
    if (selectedRes = "1440p") {
        purpleX := 257 ; Default 1440p coordinates
        purpleY := 189
    } else { ; 1080p
        purpleX := 193 ; Default 1080p coordinates
        purpleY := 142
    }
    Gui, Hud:Destroy
    MsgBox, 262208, Brightness Requirement, NOTE: For the script to function correctly, please ensure your in-game brightness is set to 7.
    ShowSectorSelection()
return

SelectHudZoomedOut:
    global selectedRes, purpleX, purpleY
    if (selectedRes = "1440p") {
        purpleX := 130
        purpleY := 159
    } else { ; 1080p
        purpleX := 97  ; Floor(130 * 0.75)
        purpleY := 119 ; Floor(159 * 0.75)
    }
    Gui, Hud:Destroy
    MsgBox, 262208, Brightness Requirement, NOTE: For the script to function correctly, please ensure your in-game brightness is set to 7.
    ShowSectorSelection()
return

purple_checker()
{
    global purpleX, purpleY
    PixelSearch, Px, Py, purpleX, purpleY, purpleX, purpleY, 0x605D7F, 0, Fast RGB

    if !ErrorLevel
    {
        return 1
    }
    return 0
}

; STEP 3: Sector selection GUI
ShowSectorSelection() {
    global
    
    if WinExist("LostSectorsCounter")
        Gui, Main:Destroy
    if WinExist("Lost Sector Selection")
        Gui, Select:Destroy
    
    Gui, Select:New, +AlwaysOnTop -Caption +Border
    Gui, Select:+LastFound
    OnMessage(0x201, "WM_LBUTTONDOWN")
    Gui, Select:Color, 212121
    Gui, Select:Font, cWhite s10, Arial
    Gui, Select:Add, Text, x10 y10, Step 3: Select Lost Sector
    Gui, Select:Add, DropDownList, vSelectedSector x10 y+10 w180, K1 Logistics||Caldera|Creation|Skywatch|The Salt Mines|The Conflux
    Gui, Select:Add, Button, x10 y+20 w180 gSelectOK, OK
    
    Gui, Keybinds:New, +AlwaysOnTop -Caption +Border +OwnerSelect
    Gui, Keybinds:+LastFound
    OnMessage(0x201, "WM_LBUTTONDOWN")
    Gui, Keybinds:Color, 212121
    Gui, Keybinds:Font, cWhite s10, Arial
    Gui, Keybinds:Add, Text, x10 y10 w200, Keybinds:
    Gui, Keybinds:Add, Text, x10 y+5 w200, F1 - Change Config (Res/HUD)
    Gui, Keybinds:Add, Text, x10 y+5 w200, F2 - Increment Counter
    Gui, Keybinds:Add, Text, x10 y+5 w200, F3 - Reset Counters
    Gui, Keybinds:Add, Text, x10 y+5 w200, F4 - Pause/Unpause Timer
    Gui, Keybinds:Add, Text, x10 y+5 w200, F5 - Change Sector
    Gui, Keybinds:Add, Text, x10 y+5 w200, F6 - Increment Prime Drops
    Gui, Keybinds:Add, Text, x10 y+5 w200, Delete - Exit App
    
    Gui, Select:Show, w200 h120 xCenter y500, Lost Sector Selection
    Gui, Keybinds:Show, w220 h200 xCenter y650, Keybinds Reference
}

SelectOK:
    Gui, Select:Submit
    Gui, Keybinds:Destroy
    SectorName := SelectedSector
    
    IniRead, FastestTime, LostSectors.ini, %SectorName%, FastestTime, 0
    FastestTime := FastestTime ? FastestTime : 0
    IniRead, TotalClears, LostSectors.ini, %SectorName%, TotalClears, 0
    
    LostSectorsCount := 0
    CurrentTime := 0
    PastTime := 0
    TimerRunning := false
    RunCompleted := false
    Paused := false
    TotalPausedTime := 0
    PrimeDrops := 0
    firstDetectionDone := false
    cooldownActive := false
    firstDetectionTime := 0
    postRunCooldownActive := false
    
    CreateOverlay()
return

CreateOverlay() {
    global
    
    if WinExist("LostSectorsCounter")
        Gui, Main:Destroy
    
    Gui, Main:New, +AlwaysOnTop +ToolWindow -Caption +E0x20 +HwndOverlayHwnd
    Gui, Main:+LastFound
    OnMessage(0x201, "WM_LBUTTONDOWN")
    Gui, Main:Color, 000000
    Gui, Main:Margin, 20, 20
    
    Gui, Main:Font, cFF9B2F s28 w700, Arial
    Gui, Main:Add, Text, vSectorNameText Center BackgroundTrans, %SectorName%
    
    Gui, Main:Font, cWhite s28 w700, Arial
    Gui, Main:Add, Text, vTextPart y+10 BackgroundTrans, Clears: 
    Gui, Main:Font, c00FF00 s28 w700, Arial
    Gui, Main:Add, Text, vNumberPart x+5 yp w120 BackgroundTrans, %LostSectorsCount%
    
    Gui, Main:Font, cWhite s14 w700, Arial
    Gui, Main:Add, Text, vTotalClearsLabel x20 y+10 BackgroundTrans, Total Clears:
    Gui, Main:Font, cWhite s14 w700, Arial
    Gui, Main:Add, Text, vTotalClearsValue x+5 yp w120 BackgroundTrans, %TotalClears%

    Gui, Main:Font, cYellow s12 w700, Arial
    Gui, Main:Add, Text, vFastestTimeLabel x20 y+15 BackgroundTrans, Fastest Time:
    Gui, Main:Font, cWhite s12 w700, Arial
    Gui, Main:Add, Text, vFastestTimeValue x+2 yp w80 BackgroundTrans, % (FastestTime ? FormatTime(FastestTime) : "--:--")
    
    Gui, Main:Font, c78C841 s12 w700, Arial
    Gui, Main:Add, Text, vCurrentTimeLabel x20 y+5 BackgroundTrans, Current Time: 
    Gui, Main:Font, cWhite s12 w700, Arial
    Gui, Main:Add, Text, vCurrentTimeValue x+2 yp w80 BackgroundTrans, --:--
    
    Gui, Main:Font, cCCCCCC s12 w700, Arial
    Gui, Main:Add, Text, vPastTimeLabel x20 y+5 BackgroundTrans, Past Time:
    Gui, Main:Font, cWhite s12 w700, Arial
    Gui, Main:Add, Text, vPastTimeValue x+2 yp w80 BackgroundTrans, --:--
    
    Gui, Main:Font, cAA00FF s12 w700, Arial
    Gui, Main:Add, Text, vPrimeDropsLabel x20 y+5 BackgroundTrans, Prime Drops: 
    Gui, Main:Font, cWhite s12 w700, Arial
    Gui, Main:Add, Text, vPrimeDropsValue x+2 yp w80 BackgroundTrans, %PrimeDrops%
    
    Gui, Main:Show, x10 y10 NoActivate, LostSectorsCounter
    WinSet, TransColor, 000000 255, LostSectorsCounter
    
    SetTimer, TimerWatcher, 300
    SetTimer, UpdateDisplay, 100
}

; Hotkeys
F1::
    ShowResolutionSelection()
return

F2::
    if (!RunCompleted) {
        LostSectorsCount++
        TotalClears++
        GuiControl, Main:, NumberPart, %LostSectorsCount%
        GuiControl, Main:, TotalClearsValue, %TotalClears%
        IniWrite, %TotalClears%, LostSectors.ini, %SectorName%, TotalClears
        
        ; --- MODIFIED: Added 50 second check for Fastest Time ---
        if (TimerRunning && CurrentTime >= 50000 && (FastestTime == 0 || CurrentTime < FastestTime)) {
            FastestTime := CurrentTime
            IniWrite, %FastestTime%, LostSectors.ini, %SectorName%, FastestTime
            GuiControl, Main:, FastestTimeValue, % FormatTime(FastestTime)
        }
        
        if (TimerRunning) {
            PastTime := CurrentTime
            GuiControl, Main:, PastTimeValue, % FormatTime(PastTime)
        }
        
        RunCompleted := true
        TimerRunning := false
        Paused := false
        GuiControl, Main:, CurrentTimeValue, --:--
        GuiControl, Main:+cWhite, CurrentTimeValue
    }
return

F3::
    LostSectorsCount := 0
    FastestTime := 0
    PrimeDrops := 0
    PastTime := 0
    IniWrite, 0, LostSectors.ini, %SectorName%, FastestTime
    RunCompleted := false
    Paused := false
    TotalPausedTime := 0
    firstDetectionDone := false
    cooldownActive := false
    firstDetectionTime := 0
    postRunCooldownActive := false
    GuiControl, Main:, NumberPart, 0
    GuiControl, Main:, FastestTimeValue, --:--
    GuiControl, Main:, CurrentTimeValue, --:--
    GuiControl, Main:, PastTimeValue, --:--
    GuiControl, Main:, PrimeDropsValue, 0
    GuiControl, Main:+cWhite, CurrentTimeValue
return

Delete::
    ExitApp
return

F4::
    if (TimerRunning && !RunCompleted) {
        if (!Paused) {
            Paused := true
            PauseStartTime := A_TickCount
            GuiControl, Main:+cRed, CurrentTimeValue
        } else {
            Paused := false
            TotalPausedTime += A_TickCount - PauseStartTime
            GuiControl, Main:+cWhite, CurrentTimeValue
        }
    }
return

F5::
    ShowSectorSelection()
return

F6::
    PrimeDrops++
    GuiControl, Main:, PrimeDropsValue, %PrimeDrops%
return

; --- MODIFIED: TimerWatcher with post-run cooldown logic ---
TimerWatcher:
    if (postRunCooldownActive) {
        if (A_TickCount - postRunCooldownStartTime >= 10000) {
            postRunCooldownActive := false
            firstDetectionDone := false
            CurrentTime := 0
        }
        return
    }

    if (!firstDetectionDone) {
        if (purple_checker()) {
            StartTime := A_TickCount
            TimerRunning := true
            Paused := false
            TotalPausedTime := 0
            firstDetectionDone := true
            cooldownActive := true
            firstDetectionTime := A_TickCount
        }
    }
    else { 
        if (cooldownActive && (A_TickCount - firstDetectionTime >= 10000)) {
            cooldownActive := false
        }

        if (!cooldownActive) {
            if (purple_checker()) {
                TimerRunning := false
                LostSectorsCount++
                TotalClears++
                GuiControl, Main:, NumberPart, %LostSectorsCount%
                GuiControl, Main:, TotalClearsValue, %TotalClears%
                IniWrite, %TotalClears%, LostSectors.ini, %SectorName%, TotalClears
                
                ; --- MODIFIED: Added 50 second check for Fastest Time ---
                if (CurrentTime >= 50000 && (FastestTime == 0 || CurrentTime < FastestTime)) {
                    FastestTime := CurrentTime
                    IniWrite, %FastestTime%, LostSectors.ini, %SectorName%, FastestTime
                    GuiControl, Main:, FastestTimeValue, % FormatTime(FastestTime)
                }
                
                PastTime := CurrentTime
                GuiControl, Main:, PastTimeValue, % FormatTime(PastTime)
                
                GuiControl, Main:, CurrentTimeValue, --:--
                GuiControl, Main:+cWhite, CurrentTimeValue

                postRunCooldownActive := true
                postRunCooldownStartTime := A_TickCount
            }
        }
    }
return

UpdateDisplay:
    if (TimerRunning && !Paused && !RunCompleted) {
        CurrentTime := (A_TickCount - StartTime) - TotalPausedTime
        GuiControl, Main:, CurrentTimeValue, % FormatTime(CurrentTime)
    }
    else if (Paused) {
        CurrentTime := (PauseStartTime - StartTime) - TotalPausedTime
        GuiControl, Main:, CurrentTimeValue, % FormatTime(CurrentTime)
    }
return

FormatTime(milliseconds) {
    seconds := Floor(milliseconds / 1000)
    minutes := Floor(seconds / 60)
    seconds := Mod(seconds, 60)
    return minutes ":" (seconds < 10 ? "0" seconds : seconds)
}

WM_LBUTTONDOWN() {
    PostMessage, 0xA1, 2
}
