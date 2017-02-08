#Noenv						;不檢查空變數是否為環境變數
#SingleInstance, force		;不允許副本執行

;--INITIALIZE TEXTURE PACKER GLOBAL-----
; GLOBAL 參數需要打在最前面
; texturepacker 安裝路徑
cmd = C:\Program Files (x86)\TexturePacker\bin\TexturePacker.exe
ifNotExist, %cmd%
	cmd = %A_ScriptDir%\TexturePacker\bin\TexturePacker.exe

; 輸出格式
format = --format cocos2d
; 輸出尺寸
size = --max-width 8192 --max-height 8192
; 元件旋轉
rotation = --disable-rotation
; 增加元件邊緣透明象素的顏色
alphableed = --reduce-border-artifacts
; 演算法
algorithm = --algorithm Basic
; 依元件排列長寬做輸出尺寸而非2的幕次方
freesize = --allow-free-size
; 元件排列方法
sort = --basic-sort-by best
; 是否移除透明象素
; trim ="--no-trim" ;不裁切Alpha
trim = --trim

WinGet, id, list,ahk_exe TexturePacker.exe	;偵測當前是否有打包視窗
CompressArray := Object()					;儲存壓縮清單用陣列


; 在按鈕屬性後方加上g-label可以將按鈕導向下方的script
;--GUI---------------
Gui, Add, GroupBox, x12 y70 w180 h70 , 純壓縮
Gui, Add, Text, x22 y170 w160 h90 , 1. 自動偵測是否有子資料夾，執行批次/獨立打包。`n2. 若有未壓縮到的圖片，再拖曳執行一次。
Gui, Add, Button, x20 y25 w70 h40 gsub1, 是`n(Enter)
Gui, Add, Button, x110 y25 w70 h40 gsub2, 否`n(Esc)
Gui, Add, GroupBox, x12 y10 w180 h60 , 打包完成後是否壓縮?
Gui, Add, Button, x22 y90 w160 h40 gsub3, PNG壓縮 (C)
Gui, Add, GroupBox, x12 y150 w180 h110 , Info:
Gui, Show, x852 y390 h276 w210, 打包壓縮
Return

GuiClose:
	ExitApp

;--SCRIPT-----
enter::
NumpadEnter::
sub1:
	suspend									; 關閉所有熱鍵
	Loop %0%  								; %0%是參數數量(此為拖曳檔案數量) %1%之後是參數數值(此為拖曳檔案路徑)
	{
		; === 環境設定 ===
		GivenPath := %A_Index%				; 
		Loop, %GivenPath%\*,2				; 將拖曳的資料夾用loop檢查內部是否有子資料夾
			CheckSub = %A_LoopFileFullPath%
			
		if ( CheckSub = "")	{				; 若無子資料夾，
			SplitPath, GivenPath,, splitDir	; 	取出拖曳的檔案之路徑
			DomainFolder = %splitDir%\		; 	Domain 設為當前拖曳的檔案路徑
		} else {							; 若不為空(有子資料夾)
			DomainFolder = %GivenPath%\		; 	Domain 設為當前拖曳的檔案內路徑
			GivenPath = %GivenPath%\*		; 	將拖曳之檔案的路徑加上萬用字元以loop其子資料夾
		}
		; === 開始打包循環 ===
		Loop %GivenPath%, 2,1				; Loop 目錄, 2=只找文件夾, 1=遞迴內部子資料夾
		{	
			Folder = %DomainFolder%%A_LoopFileName%
			LongPath = %A_LoopFileLongPath%
			; 打包指令，直接run texture packer比叫cmd出來還快，雖然cmd有內建自動等待迴圈完成效果，
			; 但叫出cmd後指令需模擬按鍵單個輸入，太緩慢
			run "%cmd%" --data "%Folder%.plist" --sheet "%Folder%.png" "%LongPath%" %format% %size% %rotation% %alphableed% %algorithm% %freesize% %sort% %trim%
			sleep 300
			While (not id = 0){
				Sleep 250
				WinGet, id, list,ahk_exe TexturePacker.exe		; 重新抓取當前是否有打包視窗，若有則回頭等待
			}
			CompressArray.insert(Folder ".png")				; 將打包產出的圖片加入陣列等等壓縮用
			;msgbox % "path: " CompressArray[CompressArray.MinIndex()] "`nIndex: " A_Index
		}
	}
	
	sleep 300
	
	; === 等待打包 === 以防丟單一檔案時馬上進入壓縮程序
	WinGet, id, list,ahk_exe TexturePacker.exe	;偵測當前是否有打包視窗
	While (not id = 0){
		Sleep 250
		WinGet, id, list,ahk_exe TexturePacker.exe		; 重新抓取當前是否有打包視窗，若有則回頭等待
	}

	; === 壓縮PNG ===
	for index, element in CompressArray
	{	
		;msgbox % "compressing: " element
		WinGet, id, list,ahk_exe TexturePacker.exe	;偵測當前是否有打包視窗
		While (not id = 0){
			Sleep 250
			WinGet, id, list,ahk_exe TexturePacker.exe
		}
		run "%A_ScriptDir%\pngquant\pngquant.exe" --force --ext .png --verbose 256 "%element%"
		;str=run %A_ScriptDir%\pngquant.exe --force --ext .png --verbose 256 %element%
		;FileAppend, %str%`n`n, %A_WorkingDir%\NewTextFile.txt
	}
	exitapp
return

esc::
sub2:
	suspend									; 關閉所有熱鍵
	Loop %0%  ; %0%是參數數量(此為拖曳檔案數量) %1%之後是參數數值(此為拖曳檔案路徑)
	{
		; === 環境設定 ===
		GivenPath := %A_Index%				; 
		Loop, %GivenPath%\*,2				; 將拖曳的資料夾用loop檢查內部是否有子資料夾
			CheckSub = %A_LoopFileFullPath%
			
		if ( CheckSub = "")	{				; 若無子資料夾，
			SplitPath, GivenPath,, splitDir	; 	取出拖曳的檔案之路徑
			DomainFolder = %splitDir%\		; 	Domain 設為當前拖曳的檔案路徑
		} else {							; 若不為空(有子資料夾)
			DomainFolder = %GivenPath%\		; 	Domain 設為當前拖曳的檔案內路徑
			GivenPath = %GivenPath%\*		; 	將拖曳之檔案的路徑加上萬用字元以loop其子資料夾
		}
		
		; === 開始打包循環 ===
		Loop %GivenPath%, 2,1
		{	
			Folder = %DomainFolder%%A_LoopFileName%
			LongPath = %A_LoopFileLongPath%
			run "%cmd%" --data "%Folder%.plist" --sheet "%Folder%.png" "%LongPath%" %format% %size% %rotation% %alphableed% %algorithm% %freesize% %sort% %trim%
			sleep 300
			
			WinGet, id, list,ahk_exe TexturePacker.exe	;偵測當前是否有打包視窗
			While (not id = 0){
				Sleep 250
				WinGet, id, list,ahk_exe TexturePacker.exe
			}
		}
	}
	
	exitapp
return

c::
sub3:
	suspend									; 關閉所有熱鍵
	Loop %0%  ; %0%是參數數量(此為拖曳檔案數量) %1%之後是參數數值(此為拖曳檔案路徑)
	{
		GivenFile := %A_Index%	
		SplitPath, GivenFile,, OutDir, OutExt	; 	取出拖曳的檔案之參數
		StringLower, OutExtLower, OutExt
		if (OutExtLower = "png"){
			run "%A_ScriptDir%\pngquant\pngquant.exe" --force --ext .png --verbose 256 "%GivenFile%"
		}
	}	
	exitapp
return