; --- NEW: Set the custom tray icon ---
; This command loads 'logo.ico' from the script's folder.
; Make sure the icon file is in the same directory as this script!
Menu, Tray, Icon, logo.ico, , 1

#NoEnv
#SingleInstance, Force
SetBatchLines, -1

; Global variables
global LostSectorsCount := 0
global TotalClears := 0
global CurrentTime := 0
global FastestTime := 0
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
global purpleX := 0
global purpleY := 0

; Main execution starts with resolution selection
ShowResolutionSelection()
return

; Function to show resolution selection GUI
ShowResolutionSelection() {
    ; Destroy other GUIs if they exist
    if WinExist("LostSectorsCounter")
        Gui, Main:Destroy
    if WinExist("Lost Sector Selection")
        Gui, Select:Destroy
    if WinExist("Keybinds Reference")
        Gui, Keybinds:Destroy
        
    Gui, Res:New, +AlwaysOnTop -Caption +Border
    Gui, Res:+LastFound
    OnMessage(0x201, "WM_LBUTTONDOWN") ; Make it draggable
    Gui, Res:Color, 212121
    Gui, Res:Font, cWhite s12, Arial
    Gui, Res:Add, Text, x10 y10 w180 Center, Select your resolution:
    Gui, Res:Font, s10
    Gui, Res:Add, Button, x25 y+20 w150 gSelect1440p, 1440p (2560x1440)
    Gui, Res:Add, Button, x25 y+10 w150 gSelect1080p, 1080p (1920x1080)
    Gui, Res:Show, w200 h130, Resolution Selection
    return
}

; Handlers for resolution selection buttons
Select1440p:
    global purpleX := 257
    global purpleY := 189
    Gui, Res:Destroy
    ShowSectorSelection()
return

Select1080p:
    ; Coordinates are scaled down from 1440p originals
    global purpleX := 193 ; Scaled from 1440p: 257 * (1920/2560)
    global purpleY := 142 ; Scaled from 1440p: 189 * (1080/1440)
    Gui, Res:Destroy
    ShowSectorSelection()
return

; This function now uses dynamic coordinates
purple_checker()
{
    global purpleX, purpleY
    PixelSearch, Px, Py, purpleX, purpleY, purpleX, purpleY, 0x605D7F, 0, Fast RGB

    if !ErrorLevel
    {
        SoundBeep
        return 1
    }
    return 0
}

; Sector selection GUI
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
    Gui, Select:Add, Text, x10 y10, Select Lost Sector:
    Gui, Select:Add, DropDownList, vSelectedSector x10 y+10 w180, K1 Logistics||Caldera|Creation|Skywatch|The Salt Mines|The Conflux
    Gui, Select:Add, Button, x10 y+20 w180 gSelectOK, OK
    
    Gui, Keybinds:New, +AlwaysOnTop -Caption +Border +OwnerSelect
    Gui, Keybinds:+LastFound
    OnMessage(0x201, "WM_LBUTTONDOWN")
    Gui, Keybinds:Color, 212121
    Gui, Keybinds:Font, cWhite s10, Arial
    Gui, Keybinds:Add, Text, x10 y10 w200, Keybinds:
    Gui, Keybinds:Add, Text, x10 y+5 w200, F1 - Change Resolution
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
    TimerRunning := false
    RunCompleted := false
    Paused := false
    TotalPausedTime := 0
    PrimeDrops := 0
    firstDetectionDone := false
    cooldownActive := false
    firstDetectionTime := 0
    
    CreateOverlay()
return

; Main overlay GUI
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
        
        if (TimerRunning && (FastestTime == 0 || CurrentTime < FastestTime)) {
            FastestTime := CurrentTime
            IniWrite, %FastestTime%, LostSectors.ini, %SectorName%, FastestTime
            GuiControl, Main:, FastestTimeValue, % FormatTime(FastestTime)
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
    IniWrite, 0, LostSectors.ini, %SectorName%, FastestTime
    RunCompleted := false
    Paused := false
    TotalPausedTime := 0
    firstDetectionDone := false
    cooldownActive := false
    firstDetectionTime := 0
    GuiControl, Main:, NumberPart, 0
    GuiControl, Main:, FastestTimeValue, --:--
    GuiControl, Main:, CurrentTimeValue, --:--
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

; Timer functions
TimerWatcher:
    if (RunCompleted)
        return

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
        if (cooldownActive && (A_TickCount - firstDetectionTime >= 60000)) {
            cooldownActive := false
        }

        if (!cooldownActive) {
            if (purple_checker()) {
                TimerRunning := false
                RunCompleted := true
                LostSectorsCount++
                TotalClears++
                GuiControl, Main:, NumberPart, %LostSectorsCount%
                GuiControl, Main:, TotalClearsValue, %TotalClears%
                IniWrite, %TotalClears%, LostSectors.ini, %SectorName%, TotalClears
                
                if (CurrentTime > 0 && (FastestTime == 0 || CurrentTime < FastestTime)) {
                    FastestTime := CurrentTime
                    IniWrite, %FastestTime%, LostSectors.ini, %SectorName%, FastestTime
                    GuiControl, Main:, FastestTimeValue, % FormatTime(FastestTime)
                }
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

; Helper function
FormatTime(milliseconds) {
    seconds := Floor(milliseconds / 1000)
    minutes := Floor(seconds / 60)
    seconds := Mod(seconds, 60)
    return minutes ":" (seconds < 10 ? "0" seconds : seconds)
}

; Universal function to make a GUI draggable
WM_LBUTTONDOWN() {
    PostMessage, 0xA1, 2
}
