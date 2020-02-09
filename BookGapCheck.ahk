#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1
#SingleInstance force

info =
(C
;BookGapCheck
Quickly check if there are gaps or duplicates 
in a set of book page scan images.

version 2018-10-26
by Nod5
Free Software GPLv3
AutoHotkey
made in Windows 10

HOW TO USE
1. Drag and drop one jpg, tif or png from a folder 
   with book page scan images.
2. Click and draw a rectangle around the page number.
3. BookGapCheck shows the same area from every 
   10th image in an overview image grid.
   
If all grid image numbers increment by 10 then
the set of scanned pages is likely complete.
Example: 10 20 30 40 ... 480

Input image via command line:
BookGapCheck.exe "C:\folder\0001.jpg"

Output file format: 
gridimage_20181004174937.jpg

)

wintitle = BookGapCheck
DetectHiddenWindows, On
guinum := 5

;read output folder from ini, else default to the script's folder
FileEncoding, UTF-16
IniRead, output_folder, %A_ScriptFullPath%.ini ,options, output_folder, %A_Space%
if !InStr(FileExist(output_folder), "D")
  output_folder := ""
FileEncoding, UTF-8

;parse command line parameters
if A_Args[1]
  goto param_started

;gui to drag drop images onto
Gui,6: font, s8 cgray
Gui,6: Add, Text,x290 y345 ghelpwindow, ?
Gui,6: font, s12 bold ;cblack
Gui,6: Add, GroupBox, x5 y2 w290 h300
if A_IsCompiled
  Gui,6: Add, Picture,x130 y75, %A_ScriptName%  ;embedded icon
Gui,6: Add, Text,x56 y130,Drop book page image
Gui,6: Add, Button, x130, Crop
GuiControl,6: Disable, Button2
Gui,6: Show,h360 w300 y200,%wintitle%
return

helpwindow:
Gui 7:+LastFoundExist
IfWinExist
{
  gui,7: destroy
  return
}
;get pos for main gui (preview or empty)
WinGetPos,mainx,mainy, mainw,, %wintitle% ahk_class AutoHotkeyGUI
;make helpwin
Gui, 7: +ToolWindow -SysMenu -Caption -resize +AlwaysOnTop +0x800000 -DPIScale
Gui, 7: Font, bold s12
Gui, 7: Add, Text,, %wintitle%
Gui, 7: Font, normal s10
Gui, 7: Add, Text,, %info%

Gui, 7: Add, Text,h1, %space%
Gui, 7: Add, Text,yp-15 vtext_var, Custom output folder:
Gui, 7: Add, Edit, yp+20 w260 r1 vedit gedit, % output_folder ? output_folder : ""
Gui, 7: Font, cblue
Gui, 7: Add, Text,yp+45 xm gwebsite, github.com/nod5/%wintitle%
;show helpwin to the right of main gui
Gui, 7: show, % "x" mainx+mainw " y" mainy
;move focus from editbox
GuiControl, 7: Focus, text_var
return

website:
Run https://github.com/nod5/%wintitle%
return

7GuiEscape:
gui,7: destroy
return

;helpwin editbox to change custom output folder
edit:
Gui, Submit, NoHide
FileEncoding, UTF-16
;if box string matches existing folder then keep it, else use the script's folder
output_folder := InStr(FileExist(edit_box), "D") ? edit_box : ""
IniWrite, % output_folder, %A_ScriptFullPath%.ini ,options, output_folder
FileEncoding, UTF-8
return

#If WinActive(wintitle " ahk_class AutoHotkeyGUI")
Tab:: goto helpwindow
#If
return

6GuiClose:
5GuiClose:
ExitApp


;file drop event
6GuiDropFiles:
5GuiDropFiles:
param_started:

;inputfiles from parameters or dropped
inputfiles := a_ThisLabel = "param_started" ? A_Args[1] : A_GuiEvent

Loop, parse, inputfiles, `n
{
  SplitPath, A_LoopField,filename,folder,ext
  if ext in tif,jpg,png
    if FileExist(A_LoopField)
      file := A_LoopField
  break
}
if !file
  return

;get image source dimensions and calculate gui pic dimensions (ByRef)
getdim(file, prop, pic_w, pic_h, imgw, imgh)
;create/show new preview pic window
makegui(file, pic_h, pic_w, wintitle, 5, %guinum%MainhWnd)
gui, 6: destroy
return


#If WinActive(wintitle " ahk_class AutoHotkeyGUI")

;mouse click on pic
~*LButton::
sleep 50
;click in pic or on old rect
MouseGetPos,,,,clickedcontrol
if clickedcontrol in Static1,AutohotkeyGUI1,AutohotkeyGUI2,AutohotkeyGUI3,AutohotkeyGUI4
  goto pic  ;start drawing new rect
return


;cancel ongoing selection rectangle
*RButton::
5GuiEscape:
25GuiEscape:
cancel_rectangle:
Loop 4
  Gui, %A_Index%: destroy

;prevent crop
block_crop := 1
;cancel ongoing rect
SetTimer, lusr_update, Off
sleep 100
return


;show next/previous image in folder
WheelUp::
WheelDown::
PgDn::      ;next image
PgUp::      ;previous
If InStr ( GetKeyState("Lbutton", "P") , "D" )
  goto cancel_rectangle

next := prev := ""
InStr(a_thislabel, "Up") ? prev := 1 : next := 1

Loop, Files, % folder "\*." ext
{
  prevfile := thisfile
  thisfile := A_LoopFilePath

  if (thisfile = file) and prev and prevfile
    ;reload with previous file
    Run %A_ScriptFullPath% "%prevfile%"

  if (prevfile = file) and next
    ;reload with next file
    Run %A_ScriptFullPath% "%thisfile%"
}
return


;user clicks on overlay preview pic
pic:

;close help gui
gui,7: destroy
block_crop := 0

;get vars for transform from screen relative x/y to pic relative x/y
;pic control x/y/w/h relative to gui window top left
ControlGetPos, xpic, ypic,wpic,hpic, Static1, %wintitle% --
;gui x/y/w/h relative to screen
WinGetPos, xwin, ywin, wwin, hwin, %wintitle% --
;pic edges relative to screen
edgex1 := xwin   + xpic  ;pic  left edge relative to screen
edgey1 := ywin   + ypic  ;pic   top edge
edgex2 := edgex1 + wpic  ;pic right edge
edgey2 := edgey1 + hpic  ;pic   low edge

;Draw rectangle as mouse moves. Return rectangle on Lbutton release.
;returns via ByRef
;returns rect corners relative to screen
LetUserSelectRect(screenx1, screeny1, screenx2, screeny2)

;cancel if no rectangle was made
if (screenx1 = screenx2 or screeny1 = screeny2)
  return

;cancel if rclick or other hotkey was pressed
if (block_crop = 1)
  return

;rect corners relative to pic top left
picx1 := screenx1 - edgex1
picx2 := screenx2 - edgex1
picy1 := screeny1 - edgey1
picy2 := screeny2 - edgey1

;upscale for crop
;rect corners relative to full img top left
x1 := Round(picx1/prop)
x2 := Round(picx2/prop)
y1 := Round(picy1/prop)
y2 := Round(picy2/prop)
w := x2 - x1
h := y2 - y1

;remove existing bookgapcheck_ file since WIA crop cannot overwrite
FileDelete, % folder "\bookgapcheck_" filename

;crop file
;ImgCrop(target, PxLeft, PxTop, PxRight, PxBottom)
ImgCrop(file, x1, y1, imgw-x2, imgh-y2)
;note: WIA crop preserves input bitdepth value

;close all gui
Loop 12
  Gui, %A_Index%: destroy

tooltip, `n`n Cropping ... `n `n `n

;crop every 10th subsequent using same rect area
;note: works well only if images have similar dimensions
filecount := 0
Loop, Files, % folder "\*." ext
{
  ;skip own output images
  if InStr(A_LoopFileName, "bookgapcheck_") or InStr(A_LoopFileName, "gridimage_")
    continue

  if (A_LoopFilePath = file)
    startfile := 1
  else if startfile
    filecount++
  
  if filecount and !Mod(filecount, 10)
  {
    ;crop at filecount 10 20 30 ...
    FileDelete, % folder "\bookgapcheck_" A_LoopFileName
    ;getdim for each new crop image source
    ;needed in case images diff in width/height
    getdim(A_LoopFilePath, prop, pic_w, pic_h, imgw, imgh)
    ;msgbox % x1 " | " imgw-x2 "|imgw=" imgw " |imgh=" imgh
    ImgCrop(A_LoopFilePath, x1, y1, imgw-x2, imgh-y2)
  }
}

;merge crops into one grid image

tooltip, `n`n Merging ... `n `n `n

;prepare big image
cropcount := 0
Loop, Files, % folder "\bookgapcheck_*." ext
  cropcount++
rows := 5
cols := ceil(cropcount / rows)
pad := 30
bigimg_w := ((w+pad)*cols)+pad
bigimg_h := ((h+pad)*rows)+pad

;black background
ARGB := [0x000000]
;create small img object as jpg
bigimgObj := WIA_CreateImage(4, 4, ARGB)
;format img object
imgext := ext = "jpg" ? "JPEG" : ext = "png" ? "PNG" : "TIFF"
bigimgObj := WIA_ConvertImage(bigimgObj, imgext)
;scale up  ;workaround since WIA_CreateImage is very slow if big w/h
bigimgObj := WIA_ScaleImage(bigimgObj, bigimg_w, bigimg_h)

;stamp crops onto big img object
Loop, Files, % folder "\bookgapcheck_*." ext
{
  StampObj := []
  StampObj := WIA_LoadImage(A_LoopFilePath)

  ;calculate stampposition for this crop
  if (a_index = 1)
    x := pad, y := pad
  else
  {
    ;note: Mod(A_Index, rows) is 0 when A_Index divided by rows has no remainder
    ;That means 0 when A_Index is last  item on a row
    ;       and 1 when A_Index is first item on a row
    ;Use that to condition x/y update:
    ;- x constant if on same row  , x increase if first on new row
    ;- y reset if first on new row, y increase if on same row
    x := Mod(A_Index, rows) = 1 ? x+w+pad : x
    y := Mod(A_Index, rows) = 1 ? pad : y+h+pad
  }
  ;stamp onto big img
  ;note: silently fails if any stamp is outside bigimgObj bounds
  bigimgObj := WIA_StampImage(bigimgObj, StampObj, x, y)
}

tooltip, `n`n saving ... `n `n `n

;save grid image
if !InStr(FileExist(output_folder), "D")
  output_folder := A_ScriptDir
gridimage := output_folder "\gridimage_" A_Now "." ext
WIA_SaveImage(bigimgObj, gridimage)

;show grid image
Loop, 40
  sleep 200
Until FileExist(gridimage)

if FileExist(gridimage)
  Run % gridimage

tooltip
sleep 1000

;remove crop images
FileDelete, % folder "\bookgapcheck_*." ext
exitapp

#If 


;function: get image source dimensions and calculate gui pic dimensions
getdim(xdimfile, ByRef prop, ByRef pic_w, ByRef pic_h, Byref imgw, Byref imgh) {
  Img := ComObjCreate("WIA.ImageFile")
  Img.LoadFile(xdimfile)

  ;image dimensions
  imgw := Img.Width , imgh := Img.Height

  ;try: fit image pic to screen height
  pic_h := A_ScreenHeight-145
  ;exact proportion, used later to upscale rectangle before crop
  prop :=  pic_h/imgh
  pic_w := imgw*prop

  ;if too wide, fit pic to screen width instead (landscape image)
  pic_wmax := A_ScreenWidth-100
  if pic_w > pic_wmax
    pic_w := A_ScreenWidth-100, prop := pic_w/imgw, pic_h := imgh*prop

  ;pic dimensions
  pic_h := Round(pic_h), pic_w := Round(pic_w)
}


;function: make preview pic window
makegui(picfile, pic_h, pic_w, title, guinum, ByRef MainhWnd) {
  hhh := pic_h + 80
  www := pic_w + 80

  ;outer parent window
  Gui,%guinum%: font, s8 cgray norm
  Gui,%guinum%: -DPIScale
  Gui,%guinum%: Show, h%hhh% w%www%,%title% -- %picfile%
  Gui,%guinum%: +LastFound
  MainhWnd := WinExist()

  ;inner child pic window
  picguinum := guinum + 50   ;55 for gui 5 , 75 for gui 25
  Gui,%picguinum%: Destroy
  Gui,%picguinum%: Margin,0,0
  Gui,%picguinum%: +Owner -Caption +ToolWindow -DPIScale ;+0x800000
  Gui,%picguinum%: Add, pic,x0 y0 w%pic_w% h%pic_h% AltSubmit, %picfile%
  Gui,%picguinum%: +Parent%MainhWnd%   ;turn pic gui into a child
  Gui,%picguinum%: Show, x40 y40 w%pic_w% h%pic_h%

  ;move ? help button position to lower right corner in new gui
  ControlGetPos, , ,wpic,hpic, Static1, %title% --
  xpos := wpic+70 ,   ypos := hpic+65
  static helpbutton
  GuiControlGet, helpexist, %guinum%: Enabled, helpbutton  ;exist already?
  if helpexist
    GuiControl, %guinum%: move, helpbutton, x%xpos% y%ypos%
  else
    Gui,%guinum%: Add, Text,x%xpos% y%ypos% vhelpbutton ghelpwindow, ?
}


; FUNCTION: SHOW SELECTION RECTANGLE
; first corner set from mouse start position
; other corner tracks user mouse move
; click fixates second corner and returns screen relative rect corners
; note: x1 x2 y1 y2 are local vars for rect corners relative to screen
; they are ByRef returned into screenx1 screenx2 ...

; based on LetUserSelectRect function by Lexikos
; www.autohotkey.com/community/viewtopic.php?t=49784

LetUserSelectRect(ByRef x1, ByRef y1, ByRef x2, ByRef y2)
{
  CoordMode, Mouse, Screen
  static r := 2  ;line thickness
  xcol := "Red"

  Loop 4 {
    Gui, %A_Index%: -Caption +ToolWindow +AlwaysOnTop -DPIScale
    Gui, %A_Index%: Color, %xcol%
  }

  if (GetKeyState("Lbutton", "P") = "U")
    return ;user already released button (quick click)

  MouseGetPos, xo, yo             ;first click position
  SetTimer, lusr_update, 10      ;selection rectangle update timer
  KeyWait, LButton                ;wait for LButton release
  SetTimer, lusr_update, Off
  Loop 4
    Gui, %A_Index%: Destroy        ;Destroy selection rectangles
  return

  lusr_update:
  CoordMode, Mouse, Screen
  MouseGetPos, x, y
  ;flip x1/x2 y1/y2 if negative rect draw
  y1 := y<yo ? y:yo , y2 := y<yo ? yo:y
  x1 := x<xo ? x:xo , x2 := x<xo ? xo:x

  ;pic edges relative to screen
  global edgex1, edgey1, edgex2, edgey2
  ;bound draw at pic edges
  x1 := x1<edgex1 ? edgex1:x1 ,  x2 := x2>edgex2 ? edgex2:x2
  y1 := y1<edgey1 ? edgey1:y1 ,  y2 := y2>edgey2 ? edgey2:y2

  ;Update selection rectangle
  Gui, 1:Show, % "NA X" x1 " Y" y1 " W" x2-x1 " H" r
  Gui, 2:Show, % "NA X" x1 " Y" y2-r " W" x2-x1 " H" r
  Gui, 3:Show, % "NA X" x1 " Y" y1 " W" r " H" y2-y1
  Gui, 4:Show, % "NA X" x2-r " Y" y1 " W" r " H" y2-y1
  return
}



;function: crop image using WIA
;parameters: distance from each img edge to crop
ImgCrop(target, PxLeft, PxTop, PxRight, PxBottom) {
  SplitPath, target, name, dir
  ImgObj := []
  ImgObj := WIA_LoadImage(target)
  ImgObj := WIA_CropImage(ImgObj, PxLeft, PxTop, PxRight, PxBottom)
  WIA_SaveImage(ImgObj, dir "\bookgapcheck_" name)
}



; WIA image functions
; a subset of the WIA library WIA.ahk v1.0.02.00/2015-05-03 by just me
; https://autohotkey.com/boards/viewtopic.php?t=7254
; License: The Unlicense , https://unlicense.org/

WIA_CropImage(ImgObj, PxLeft, PxTop, PxRight, PxBottom) {
   If (ComObjType(ImgObj, "Name") <> "IImageFile")
      Return False
   If !WIA_IsInteger(PxLeft, PxTop, PxRight, PxBottom) || !WIA_IsPositive(PxLeft, PxTop, PxRight, PxBottom)
      Return False
   If ((ImgObj.Width - PxLeft - PxRight) < 0) || ((ImgObj.Height - PxTop - PxBottom) < 0)
      Return False
   ImgProc := WIA_ImageProcess()
   ImgProc.Filters.Add(ImgProc.FilterInfos("Crop").FilterID)
   ImgProc.Filters[1].Properties("Left") := PxLeft
   ImgProc.Filters[1].Properties("Top") := PxTop
   ImgProc.Filters[1].Properties("Right") := PxRight
   ImgProc.Filters[1].Properties("Bottom") := PxBottom
   Return ImgProc.Apply(ImgObj)
}

WIA_LoadImage(ImgPath) {
   ImgObj := ComObjCreate("WIA.ImageFile")
   ComObjError(0)
   ImgObj.LoadFile(ImgPath)
   ComObjError(1)
   Return A_LastError ? False : ImgObj
}

WIA_SaveImage(ImgObj, ImgPath) {
   If (ComObjType(ImgObj, "Name") <> "IImageFile")
      Return False
   SplitPath, ImgPath, FileName, FileDir, FileExt
   If (ImgObj.FileExtension <> FileExt)
      Return False
   ComObjError(0)
   ImgObj.SaveFile(ImgPath)
   ComObjError(1)
   Return !A_LastError
}

WIA_StampImage(ImgObj, StampObj, PxLeft, PxTop) {
   If (ComObjType(ImgObj, "Name") <> "IImageFile") || (ComObjType(StampObj, "Name") <> "IImageFile")
      Return False
   If ((PxLeft + StampObj.Width) > ImgObj.Width) || ((PxTop + StampObj.Height) > ImgObj.Height)
      Return False
   ImgProc := WIA_ImageProcess()
   ImgProc.Filters.Add(ImgProc.FilterInfos("Stamp").FilterID)
   ImgProc.Filters[1].Properties("ImageFile") := StampObj
   ImgProc.Filters[1].Properties("Left") := PxLeft
   ImgProc.Filters[1].Properties("Top") := PxTop
   Return ImgProc.Apply(ImgObj)
}

WIA_ScaleImage(ImgObj, PxWidth, PxHeight) {
   If (ComObjType(ImgObj, "Name") <> "IImageFile")
      Return False
   If !WIA_IsInteger(PxWidth, PxHeight) || ((PxWidth < 1) && (PxHeight < 1))
      Return False
   KeepRatio := (PxWidth < 1) || (PxHeight < 1) ? True : False
   ImgProc := WIA_ImageProcess()
   ImgProc.Filters.Add(ImgProc.FilterInfos("Scale").FilterID)
   ImgProc.Filters[1].Properties("MaximumWidth") := PxWidth > 0 ? PxWidth : PxHeight
   ImgProc.Filters[1].Properties("MaximumHeight") := PxHeight > 0 ? PxHeight : PxWidth
   ImgProc.Filters[1].Properties("PreserveAspectRatio") := KeepRatio
   Return ImgProc.Apply(ImgObj)
}


WIA_CreateImage(PxWidth, PxHeight, ARGBData) {
   If !WIA_IsInteger(PxWidth, PxHeight) || !WIA_IsPositive(PxWidth, PxHeight)
      Return False
   DataCount := PxWidth * PxHeight
   Vector := ComObjCreate("WIA.Vector")
   I := 1
   Loop
      For Each, ARGB In ARGBData
         Vector.Add(ComObject(0x3, ARGB))
      Until (++I > DataCount)
   Until (I > DataCount)
   Return Vector.ImageFile(PxWidth, PxHeight)
}

WIA_ConvertImage(ImgObj, NewFormat, Quality := 100, Compression := "LZW") {
   Static FormatID := {BMP: "{B96B3CAB-0728-11D3-9D7B-0000F81EF32E}"
                     , JPEG: "{B96B3CAE-0728-11D3-9D7B-0000F81EF32E}"
                     , GIF: "{B96B3CB0-0728-11D3-9D7B-0000F81EF32E}"
                     , PNG: "{B96B3CAF-0728-11D3-9D7B-0000F81EF32E}"
                     , TIFF: "{B96B3CB1-0728-11D3-9D7B-0000F81EF32E}"}
   Static Comp := {CCITT3: 1, CCITT4: 1, LZW: 1, RLE: 1, Uncompressed: 1}
   If (ComObjType(ImgObj, "Name") <> "IImageFile")
      Return False
   If ((NewFormat := FormatID[NewFormat]) = "")
      Return False
   If Quality Not Between 1 And 100
      Return False
   If (Comp[Compression] = "")
      Return False
   ImgProc := WIA_ImageProcess()
   ImgProc.Filters.Add(ImgProc.FilterInfos("Convert").FilterID)
   ImgProc.Filters[1].Properties("FormatID") := NewFormat
   ImgProc.Filters[1].Properties("Quality") := Quality
   ImgProc.Filters[1].Properties("Compression") := Compression
   Return ImgProc.Apply(ImgObj)
}


WIA_ImageProcess() {
   Static ImageProcess := ComObjCreate("WIA.ImageProcess")
   While (ImageProcess.Filters.Count)
      ImageProcess.Filters.Remove(1)
   Return ImageProcess
}

WIA_IsInteger(Values*) {
   If Values.MaxIndex() = ""
      Return False
   For Each, Value In Values
      If Value Is Not Integer
         Return False
   Return True
}

WIA_IsPositive(Values*) {
   If Values.MaxIndex() = ""
      Return False
   For Each, Value In Values
      If (Value < 0)
         Return False
   Return True
}
