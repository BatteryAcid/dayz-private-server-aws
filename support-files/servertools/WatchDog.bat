@echo off

:: // General references (locations)
:: Fields: [ Scrip home(Homedir), arma2oaserver.exe(GameServerPath), MySQL.exe(MYSQLPath), BEC.exe(BECPath) ]
set Homedir=%CD%
set GameServerPath="C:\arma2oa"
set GameServerExe="C:\arma2oa\arma2oaserver.exe"
set MYSQLPath="C:\Program Files\MySQL\MySQL Server 5.7\bin\"
set MYSQLExe="C:\Program Files\MySQL\MySQL Shell 8.0\bin\mysqlsh.exe"
set BECPath="C:\ServerTools\BEC\"
set BlockerPath="C:\ServerTools\Restart\"

:: // Arma2oa Server Configuration location(s). 
:: Fields: [ Root folder(configloc), Configuration(servercfg), Basic(basiccfg), BattlEye filters(BattlEyePath), PID creation path(PIDPath) ]
:: <comment> (please note that the suffix '\' should be excluded) </comment>
set configloc=C:\cfgdayz\
set servercfg=C:\cfgdayz\server.cfg
set basiccfg=C:\cfgdayz\basic.cfg
set BattlEyePath=C:\cfgdayz\BattlEye
set PIDPath=C:\cfgdayz\
set LogPath=C:\cfgdayz


:: // Arma2oa Server Settings. 
:: Fields: [ Name(servername), IP(serverip), Port(serverport), Launch paramters(addpar) ]
set servername=MYSERVERNAME
set serverip=127.0.0.1
set serverport=2302
set addpar=-maxMem=2047 -bandwidthAlg=2 -cpuCount=2 -exThreads=1 -malloc=tbb4malloc_bi -nosplash -noSound -pid=%PIDPath%server_pid.txt


:: // MySQL Settings.
:: Fields: [ IP(mysqlhost), Port(mysqlport), Username(mysqlusr), Password(mysqlpwd), Database name(mysqldb), Game instance-ID(instanceid) ]
set mysqlhost=CHANGEME
set mysqlport=3306
set mysqlusr=dayzhivemind
set mysqlpwd=dayzhivemind
set mysqldb=dayz_db
set instanceid=1337


cls
echo Protecting Server: [ %servername% ] from crashes...
title DayZMod_%serverip%_%serverport% Watchdog
timeout /T 5
goto logrotation
 
:update
::not doing this automatically
::D:\GameServers\SteamCMD\steamcmd.exe +runscript "D:\GameServers\steamCMD\steamapps\Common\DayZMod_%serverip%_%serverport%\DayZMod_%serverip%_%serverport%.cfg
::timeout /T 5
goto StartMysql
 
:StartMysql
echo Executing spawn script...
%MYSQLExe% --user=%mysqlusr% --password=%mysqlpwd% --host=%mysqlhost% --port=%mysqlport% --database=%mysqldb% --sql --execute="call pMain(%instanceid%)"
timeout /T 5
goto StartServer

:StartServer
echo DayZMod_%serverip%_%serverport% started.
"C:\Windows\System32\cmd.exe" /C start "DayZMod_%serverip%_%serverport%" /HIGH %GameServerExe% -port=%serverport% -config=%servercfg% -cfg=%basiccfg% -profiles=%configloc% -bepath=%BattlEyePath% -name=prod -mod=@DayZ;@Hive %addpar%
:: Removed for testing /AFFINITY %affinity01%
echo (%date%) (%time%) Waiting for Dayz to start.
TIMEOUT /T 20
goto StartBEC

:StartBEC
echo Starting BEC
start /D %BECPath% "BEC MYSERVERNAME" Bec.exe -f Config.cfg
TIMEOUT /T 20
goto armaloop

:armaloop
for /f %%a in (%PIDPath%\server_pid.txt) do (
SET pid=%%a
)
taskkill /f /fi "status eq not responding" /im arma2oaserver.exe
echo (%date%) (%time%) ATTENTION: trying loop
TIMEOUT /T 30
tasklist /fi "PID eq %pid%" /FO TABLE | find /i "arma2oaserver.exe"
if "%ERRORLEVEL%"=="0" goto armaloop
if "%ERRORLEVEL%"=="1" goto armacrashed
exit
 
:armacrashed
IF NOT EXIST Watchdog_Logs (
	mkdir %LogPath%\Watchdog_Logs\
)
echo (%datestamp%) (%timestamp%) ATTENTION: ArmA closed or crashed, restarting.
echo (%datestamp%) (%timestamp%) ATTENTION: ArmA closed or crashed > %LogPath%\Watchdog_Logs\%fullstamp%_Crash.txt
TIMEOUT /T 30
goto logrotation
 
:logrotation
:: Declare how date / time should be handled.
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "datestamp=%YYYY%%MM%%DD%" & set "timestamp=%HH%%Min%%Sec%" & set "fullstamp=%YYYY%-%MM%-%DD%_%HH%%Min%-%Sec%"

cls
echo (%datestamp%) (%timestamp%) Starting Log Rotation.
 
IF NOT EXIST Watchdog_Logs (
Mkdir Watchdog_Logs
)

:: Check / Copy / Clear Server Logs

	:: arma2oaserver.RPT
	IF EXIST %LogPath%\arma2oaserver.RPT (
		Echo Copying arma2oaserver.RPT from (%timestamp%)
		IF NOT EXIST %LogPath\%datestamp%\%timestamp%\ (
			mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
		)
		copy %LogPath%\arma2oaserver.RPT %LogPath%\Logs\%datestamp%\%timestamp%\arma2oaserver.RPT /Y
		break>%LogPath%\arma2oaserver.RPT
	)
	
	:: HiveExt.log
	IF EXIST %LogPath%\HiveExt.log (
	Echo Copying HiveExt.log from (%timestamp%)
	IF NOT EXIST %LogPath\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %LogPath%\HiveExt.log %LogPath%\Logs\%datestamp%\%timestamp%\HiveExt.log /Y
	break>%LogPath%\HiveExt.log
	
	:: server_console.log
	IF EXIST %LogPath%\server_console.log (
	Echo Copying server_console.log from (%timestamp%)
	IF NOT EXIST %LogPath\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %LogPath%\server_console.log %LogPath%\Logs\%datestamp%\%timestamp%\server_console.log /Y
	break>%LogPath%\server_console.log
)

:: Check / Copy / BattlEye Logs

	:: waypointstatements.log
	IF EXIST %BattlEyePath%\waypointstatements.log (
	Echo Copying waypointstatements.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\waypointstatements.log %LogPath%\Logs\%datestamp%\%timestamp%\waypointstatements.log /Y
	break>%BattlEyePath%\rcon_elite.log
)

	:: teamswitch.log
	IF EXIST %BattlEyePath%\teamswitch.log (
	Echo Copying teamswitch.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\teamswitch.log %LogPath%\Logs\%datestamp%\%timestamp%\teamswitch.log /Y
	break>%BattlEyePath%\teamswitch.log
)

	:: setvariable.log
	IF EXIST %BattlEyePath%\setvariable.log (
	Echo Copying setvariable.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\setvariable.log %LogPath%\Logs\%datestamp%\%timestamp%\setvariable.log /Y
	break>%BattlEyePath%\setvariable.log
)

	:: setpos.log
	IF EXIST %BattlEyePath%\setpos.log (
	Echo Copying setpos.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\setpos.log %LogPath%\Logs\%datestamp%\%timestamp%\setpos.log /Y
	break>%BattlEyePath%\setpos.log
)

	:: setdamage.log
	IF EXIST %BattlEyePath%\setdamage.log (
	Echo Copying setdamage.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\setdamage.log %LogPath%\Logs\%datestamp%\%timestamp%\setdamage.log /Y
	break>%BattlEyePath%\setdamage.log
)

	:: selectplayer.log
	IF EXIST %BattlEyePath%\selectplayer.log (
	Echo Copying selectplayer.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\selectplayer.log %LogPath%\Logs\%datestamp%\%timestamp%\selectplayer.log /Y
	break>%BattlEyePath%\selectplayer.log
)

	:: scripts.log
	IF EXIST %BattlEyePath%\scripts.log (
	Echo Copying scripts.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\scripts.log %LogPath%\Logs\%datestamp%\%timestamp%\scripts.log /Y
	break>%BattlEyePath%\scripts.log
)

	:: remoteexec.log
	IF EXIST %BattlEyePath%\remoteexec.log (
	Echo Copying remoteexec.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\remoteexec.log %LogPath%\Logs\%datestamp%\%timestamp%\remoteexec.log /Y
	break>%BattlEyePath%\remoteexec.log
)

	:: remotecontrol.log
	IF EXIST %BattlEyePath%\remotecontrol.log (
	Echo Copying remotecontrol.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\remotecontrol.log %LogPath%\Logs\%datestamp%\%timestamp%\remotecontrol.log /Y
	break>%BattlEyePath%\remotecontrol.log
)

	:: publicvariable.log
	IF EXIST %BattlEyePath%\publicvariable.log (
	Echo Copying publicvariable.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\publicvariable.log %LogPath%\Logs\%datestamp%\%timestamp%\publicvariable.log /Y
	break>%BattlEyePath%\publicvariable.log
)

	:: mpeventhandler.log
	IF EXIST %BattlEyePath%\mpeventhandler.log (
	Echo Copying mpeventhandler.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\mpeventhandler.log %LogPath%\Logs\%datestamp%\%timestamp%\mpeventhandler.log /Y
	break>%BattlEyePath%\mpeventhandler.log
)

	:: deletevehicle.log
	IF EXIST %BattlEyePath%\deletevehicle.log (
	Echo Copying deletevehicle.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\deletevehicle.log %LogPath%\Logs\%datestamp%\%timestamp%\deletevehicle.log /Y
	break>%BattlEyePath%\deletevehicle.log
)

	:: createvehicle.log
	IF EXIST %BattlEyePath%\createvehicle.log (
	Echo Copying createvehicle.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\createvehicle.log %LogPath%\Logs\%datestamp%\%timestamp%\createvehicle.log /Y
	break>%BattlEyePath%\createvehicle.log
)

	:: attachto.log
	IF EXIST %BattlEyePath%\attachto.log (
	Echo Copying attachto.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\attachto.log %LogPath%\Logs\%datestamp%\%timestamp%\attachto.log /Y
	break>%BattlEyePath%\attachto.log
)

	:: addweaponcargo.log
	IF EXIST %BattlEyePath%\addweaponcargo.log (
	Echo Copying addweaponcargo.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\addweaponcargo.log %LogPath%\Logs\%datestamp%\%timestamp%\addweaponcargo.log /Y
	break>%BattlEyePath%\addweaponcargo.log
)

	:: addmagazinecargo.log
	IF EXIST %BattlEyePath%\addmagazinecargo.log (
	Echo Copying addmagazinecargo.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\addmagazinecargo.log %LogPath%\Logs\%datestamp%\%timestamp%\addmagazinecargo.log /Y
	break>%BattlEyePath%\addmagazinecargo.log
)

	:: addbackpackcargo.log
	IF EXIST %BattlEyePath%\addbackpackcargo.log (
	Echo Copying addbackpackcargo.log from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\addbackpackcargo.log %LogPath%\Logs\%datestamp%\%timestamp%\addbackpackcargo.log /Y
	break>%BattlEyePath%\addbackpackcargo.log
)

:: Check / Copy / Bans and Localbans for reference.
:: Special handling apply where the file is not breaked.

	:: bans.txt
	IF EXIST %BattlEyePath%\bans.txt (
	Echo Copying bans.txt from (%timestamp%)
	IF NOT EXIST %LogPath%\%datestamp%\%timestamp%\ (
		mkdir %LogPath%\Logs\%datestamp%\%timestamp%\
	)
	copy %BattlEyePath%\bans.txt %LogPath%\Logs\%datestamp%\%timestamp%\bans.txt /Y
)

TIMEOUT /T 3
cls
goto update
 
exit