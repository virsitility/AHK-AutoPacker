update(lversion, logurl="", rfile="github", vline=5){
    global s_author, s_name
    s_author = virsitility
	s_name = AHK
    `(rfile = "github") ? logurl := "https://www.github.com/" s_author "/" s_name "/raw/master/Changelog.txt"
	
    RunWait %ComSpec% /c "Ping -n 1 -w 3000 google.com",, Hide  ; Check if we are connected to the internet

    if connected := !ErrorLevel
    {
		;msgbox, % logurl
        UrlDownloadToFile, %logurl%, %a_temp%\logurl
        FileReadLine, logurl, %a_temp%\logurl, %vline%
        RegexMatch(logurl, "v(.*)", Version)
        if (rfile = "github"){
            if (a_iscompiled)
                rfile := "https://github.com/downloads/" s_author "/" s_name "/" s_name "-" Version "-Compiled.zip"
            else 
                rfile := "https://github.com/" s_author "/" s_name "/zipball/" Version
        }
        if (Version1 > lversion){
            Msgbox, 68, % "New Update Available"
                      , % "There is a new update available for this application.`n"
                        . "Do you wish to upgrade to " Version "?"
                      , 10 ; 10s timeout
            IfMsgbox, Timeout
                return debug ? "* Update message timed out" : 1
            IfMsgbox, No
                return debug ? "* Update aborted by user" : 2
            FileSelectFile, lfile, S16, %a_temp%
            UrlDownloadToFile, %rfile%, %lfile%
            Msgbox, 64, % "Download Complete"
                      , % "To install the new version simply replace the old file with the one`n"
                      .   "that was downloaded.`n`n The application will exit now."
            Run, %lfile%
            ExitApp
        }
        return debug ? "* update() [End]" : 0
    }
    else
        return debug ? "* Connection Failed" : 3
}
update("1.0")