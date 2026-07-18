!include "nsDialogs.nsh"

Var ShortcutsDialog
Var StartMenuCheckbox
Var DesktopCheckbox
Var StartMenuChecked
Var DesktopChecked

!macro customPageAfterChangeDir
  Page custom ShortcutsPage ShortcutsPageLeave
!macroend

Function ShortcutsPage
  nsDialogs::Create 1018
  Pop $ShortcutsDialog
  ${If} $ShortcutsDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 24u "Choose which shortcuts to create. Both are optional."
  Pop $0

  ${NSD_CreateCheckbox} 0 30u 100% 12u "Add a Start Menu shortcut"
  Pop $StartMenuCheckbox
  ${NSD_SetState} $StartMenuCheckbox ${BST_CHECKED}

  ${NSD_CreateCheckbox} 0 50u 100% 12u "Add a Desktop shortcut"
  Pop $DesktopCheckbox
  ${NSD_SetState} $DesktopCheckbox ${BST_UNCHECKED}

  nsDialogs::Show
FunctionEnd

Function ShortcutsPageLeave
  ${NSD_GetState} $StartMenuCheckbox $StartMenuChecked
  ${NSD_GetState} $DesktopCheckbox $DesktopChecked
FunctionEnd

!macro customInstall
  ${If} $StartMenuChecked == ${BST_CHECKED}
    CreateShortCut "$newStartMenuLink" "$appExe" "" "$appExe" 0 "" "" "${APP_DESCRIPTION}"
    WinShell::SetLnkAUMI "$newStartMenuLink" "${APP_ID}"
  ${EndIf}
  ${If} $DesktopChecked == ${BST_CHECKED}
    CreateShortCut "$newDesktopLink" "$appExe" "" "$appExe" 0 "" "" "${APP_DESCRIPTION}"
    WinShell::SetLnkAUMI "$newDesktopLink" "${APP_ID}"
  ${EndIf}
!macroend

!macro customUnInstall
  WinShell::UninstAppUserModelId "${APP_ID}"
  WinShell::UninstShortcut "$oldStartMenuLink"
  Delete "$oldStartMenuLink"
  WinShell::UninstShortcut "$oldDesktopLink"
  Delete "$oldDesktopLink"
!macroend
