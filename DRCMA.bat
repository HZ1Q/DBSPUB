@echo off

echo.
echo **********************************************************************
echo This is DB backup script for the RCM server. This script will backup
echo the RCM database every day at midnight. You will be able to customize 
echo some of the backup parameters in the following prompts.
echo **********************************************************************
echo.
pause
cls
echo.
echo **********************************************************************
echo Do you want to install the SQL GURU tool? This tool serves a few functions
echo and is being actively developed. Running the SQL_GURU.bat script from
echo the desktop will open a window to run these queries. All output from the
echo script will be output on your desktop in a folder called "SQL OUTPUT"
echo.
echo The current features of this tool in this version are as follows:
echo Create RCMDB backup on demand
echo Check RCMDB for corruption on demand
echo Audit POS users pin numbers where the length is ^<6 numbers
echo Audit safedrop configuration where configured amount is ^> 600.00
echo View advanced employee information
echo View basic employee information
echo View all configured employees
echo View all globally configured employees
echo **********************************************************************
echo Do you want to install the SQL GURU tool?
set /p installsqlguru=(Y/N?)
cls
echo **********************************************************************
rem Set the company name
echo Enter the comapny name and press enter.
set /p companynameprompt=:
set companyname=%companynameprompt%

rem **********************************************************************
rem Choose the name of the Database to be backed up
set dbname=RCMDB

rem **********************************************************************
rem Choose the login for the database. This will usually be something similar to "RCM\RCM"
set dblogin=RCM\RCM

rem **********************************************************************
rem The db backup file name followed by the date/time of the DB backup. (The date is automatically added. DO NOT ADD THE DATE BELOW!^)
echo Enter the RCM version number and press enter.
set /p rcmversionprompt=:
rem Example: 2019.2.8-CF-RCMDBBackup-20210706.bak
set dbfilename=%companynameprompt%-RCMDBBackup-%rcmversionprompt%

rem **********************************************************************
rem Delete backups older than the amount of days specified here.
echo How many days of DB backups do you want to keep?
echo Recommended value is 60
set rcmdbhistory=:
set dbbackuphistory=%rcmdbhistory%

rem **********************************************************************
rem Choose primary backup location for DB backups
set primarydbbackuploc=C:\Program Files\Microsoft SQL Server\MSSQL14.RCM\MSSQL\Backup\

rem **********************************************************************
rem Choose primary backup location for DB backups for xcopy files. (Xcopy needs the file path without the ending backslash "\".
set primarydbbackuploc1=C:\Program Files\Microsoft SQL Server\MSSQL14.RCM\MSSQL\Backup

rem **********************************************************************
rem Choose which days of the week to backup the DB. ex: MON
rem For multiple days use commas without spaces EX: SUN,WED
set backupdays=SUN,MON,TUE,WED,THU,FRI,SAT

rem **********************************************************************
rem Choose the time you want to backup. Time MUST be in 24hr format. EX: 00:00 for midnight EX: 23:57 for 11:57PM
set backuptime=00:00

rem **********************************************************************
rem Create main folder
	if not exist "C:\%companyname%\" (
		mkdir "C:\%companyname%\"
)
rem **********************************************************************
rem Create scipts folder
	if not exist "C:\%companyname%\Scripts" (
		mkdir "C:\%companyname%\Scripts"
)
rem **********************************************************************
rem Create DB Logs folder
	if not exist "C:\%companyname%\DBLogs\" (
		mkdir "C:\%companyname%\DBLogs\"
)
rem **********************************************************************
rem Create Tasks folder
	if not exist "C:\%companyname%\Tasks" (
		mkdir "C:\%companyname%\Tasks"
)
rem **********************************************************************
rem Create temp folder
	if not exist "C:\%companyname%\Temp\" (
		mkdir "C:\%companyname%\Temp\"
)
rem **********************************************************************
rem Create SQL script to check the RCM DB for corruption
	if not exist "C:\%companyname%\Scripts\Check RCM DB.sql" (
		echo DBCC CHECKDB>> "C:\%companyname%\Scripts\Check RCM DB.sql"
)
rem **********************************************************************
rem Create SQL script to Backup the RCM db
	if not exist "C:\%companyname%\Scripts\Backup RCM DB.sql" (
	(
		echo DECLARE @MyFileName varchar(1000^)
		echo SELECT @MyFileName = (SELECT '%primarydbbackuploc%%dbfilename%' + convert(varchar(500^),GetDate(^),112^) + '.bak'^)
		echo BACKUP DATABASE [%DBNAME%] TO  DISK = @MyFileName WITH checksum, NOFORMAT, NOINIT,  NAME = N'RCMDB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
		echo GO
	) 1>"C:\%companyname%\Scripts\Backup RCM DB.sql"
)

if /I installsqlguru=='n' goto installarchiver
rem **********************************************************************
rem Create AuditSafeDrop.sql query
	if not exist "C:\%companyname%\Scripts\AuditSafeDrop.sql" (
(
		echo SELECT operator.first_name AS "First Name", 
		echo operator.last_name AS "Last Name", 
		echo site.site_number AS "Store Number", 
		echo pos_operator.maximum_safe_drop_amount AS "Safe Drop"
		echo.
		echo FROM RCMDB.dbo.operator
		echo left JOIN RCMDB.dbo.site 
		echo ON RCMDB.dbo.operator.owner_site_hierarchy_id=site.site_hierarchy_id
		echo.
		echo left join POS_Operator
		echo ON RCMDB.dbo.pos_operator.operator_id=RCMDB.dbo.operator.operator_id
		echo.
		echo left join RCM_Operator
		echo ON RCMDB.dbo.pos_operator.operator_id=RCMDB.dbo.RCM_Operator.operator_id
		echo WHERE pos_operator.maximum_safe_drop_amount ^> 600.00
		echo OR pos_operator.maximum_safe_drop_amount IS null
	) 1>"C:\%companyname%\Scripts\AuditSafeDrop.sql"
)

rem **********************************************************************
rem Create AuditUserPin.sql query
	if not exist "C:\%companyname%\Scripts\AuditUserPin.sql" (
(
		echo SELECT operator.first_name AS "First Name", operator.last_name AS "Last Name", site.site_number AS "Store Number", rcm_operator.login AS "RCM Login", pos_operator.pin AS "PIN", operator.external_id AS "External ID"
		echo FROM RCMDB.dbo.operator
		echo left JOIN RCMDB.dbo.site 
		echo ON RCMDB.dbo.operator.owner_site_hierarchy_id=site.site_hierarchy_id
		echo left join POS_Operator
		echo ON RCMDB.dbo.pos_operator.operator_id=RCMDB.dbo.operator.operator_id
		echo left join RCM_Operator
		echo ON RCMDB.dbo.pos_operator.operator_id=RCMDB.dbo.RCM_Operator.operator_id
		echo WHERE LEN^(pos_operator.pin^) ^< 6
	) 1>"C:\%companyname%\Scripts\AuditUserPin.sql"
)

rem **********************************************************************
rem Create ViewAdvancedEmployeeInformation.sql query
	if not exist "C:\%companyname%\Scripts\ViewAdvancedEmployeeInformation.sql" (
(
		echo SELECT operator.first_name AS "First Name", 
		echo operator.last_name AS "Last Name", 
		echo RCMDB.dbo.operator.operator_id,
		echo site.site_number AS "Store Number",
		echo rcm_operator.login AS "RCM Login", 
		echo pos_operator.pin AS "PIN", 
		echo operator.external_id AS "External ID",
		echo pos_operator.maximum_safe_drop_amount AS "Safe Drop"
		echo.
		echo FROM RCMDB.dbo.operator
		echo left JOIN RCMDB.dbo.site 
		echo ON RCMDB.dbo.operator.owner_site_hierarchy_id=site.site_hierarchy_id
		echo.
		echo left join POS_Operator
		echo ON RCMDB.dbo.pos_operator.operator_id=RCMDB.dbo.operator.operator_id
		echo.
		echo left join RCM_Operator
		echo ON RCMDB.dbo.pos_operator.operator_id=RCMDB.dbo.RCM_Operator.operator_id
	) 1>"C:\%companyname%\Scripts\ViewAdvancedEmployeeInformation.sql"
)

rem **********************************************************************
rem Create ViewAllGlobalEmployees.sql query
	if not exist "C:\%companyname%\Scripts\ViewAllGlobalEmployees.sql" (
(
		echo SELECT operator.first_name AS "First Name", operator.last_name AS "Last Name", site.site_number AS "Store Number", operator.external_id AS "External ID"
		echo FROM RCMDB.dbo.operator
		echo left JOIN RCMDB.dbo.site 
		echo ON RCMDB.dbo.operator.owner_site_hierarchy_id=site.site_hierarchy_id
		echo WHERE site_number IS null
	) 1>"C:\%companyname%\Scripts\ViewAllGlobalEmployees.sql"
)

rem **********************************************************************
rem Create ViewAllSiteEmployees.sql query
	if not exist "C:\%companyname%\Scripts\ViewAllSiteEmployees.sql" (
(
		echo SELECT operator.first_name AS "First Name", operator.last_name AS "Last Name", site.site_number AS "Store Number", operator.external_id AS "External ID"
		echo FROM RCMDB.dbo.operator
		echo left JOIN RCMDB.dbo.site 
		echo ON RCMDB.dbo.operator.owner_site_hierarchy_id=site.site_hierarchy_id
		echo WHERE site_number IS not null
	) 1>"C:\%companyname%\Scripts\ViewAllSiteEmployees.sql"
)

rem **********************************************************************
rem Create ViewBasicEmployeeInformation.sql query
	if not exist "C:\%companyname%\Scripts\ViewBasicEmployeeInformation.sql" (
(
		echo SELECT operator.first_name AS "First Name", 
		echo operator.last_name AS "Last Name", 
		echo RCMDB.dbo.operator.operator_id AS "Operator ID",
		echo site.site_number AS "Store Number",
		echo operator.external_id AS "External ID",
		echo pos_operator.maximum_safe_drop_amount AS "Safe Drop"
		echo.
		echo FROM RCMDB.dbo.operator
		echo left JOIN RCMDB.dbo.site 
		echo ON RCMDB.dbo.operator.owner_site_hierarchy_id=site.site_hierarchy_id
		echo.
		echo left join POS_Operator
		echo ON RCMDB.dbo.pos_operator.operator_id=RCMDB.dbo.operator.operator_id
		echo.
		echo left join RCM_Operator
		echo ON RCMDB.dbo.pos_operator.operator_id=RCMDB.dbo.RCM_Operator.operator_id
	) 1>"C:\%companyname%\Scripts\ViewBasicEmployeeInformation.sql"
)
rem **********************************************************************
rem Create SQL_GURU.bat tool
	if not exist "C:\%companyname%\Scripts\SQL_GURU.bat" (
(
		echo @echo off
		echo ^Echo.
		echo rem Script and SQL queries written by Tyler Pierce 09032021.
		echo rem To remove headers ~ -h-1 -s"," -w 1000~ (Remove the tildes^)
		echo rem To include headers ~ -s"," -w 1000 ~ (Remove the tildes^)
		echo set datestamp=%%date:~4,2%%%%date:~7,2%%%%date:~10,4%%
		echo ^Echo.
		echo.
		echo if not exist "C:\Users\%username%\desktop\SQL OUTPUT" (
		echo 	mkdir "C:\Users\%username%\desktop\SQL OUTPUT"
		echo 	^)
		echo ^Echo.
		echo if not exist "C:\Users\%username%\desktop\SQL OUTPUT\%%datestamp%%" (
		echo 	mkdir "C:\Users\%username%\desktop\SQL OUTPUT\%%datestamp%%"
		echo 	^)
		echo ^Echo.
		echo ^mode ^con: cols=70 lines=25
		echo title SQL GURU
		echo ^Echo ****BE SURE TO READ ALL INFORMATION BELOW BEFORE PROCEEDING****
		echo ^Echo.
		echo ^Echo This script will enable you to very easily get Country Fair
		echo ^Echo database information that you cannot view from RCM. 
		echo ^Echo This will also make it very easy to provide Operator IDs 
		echo ^Echo for PDI.
		echo ^Echo All queried output will be created in a .csv document in
		echo ^Echo a folder named "SQL OUTPUT" on the user's desktop.
		echo pause
		echo :start
		echo set tdstamp=%%date:~4,2%%%%date:~7,2%%%%date:~10,4%%_%%time:~0,2%%%%time:~3,2%%%%time:~6,2%%
		echo set outpath=C:\Users\Administrator\Desktop\SQL OUTPUT\%%datestamp%%\
		echo set scriptfolder=C:\Country Fair\Scripts\
		echo cls
		echo Echo Select an item from the list:
		echo ^Echo.
		echo ^Echo 1^) View basic employee information
		echo ^Echo 2^) View advanced employee information
		echo ^Echo 3^) Audit safe drop configuration
		echo ^Echo 4^) Audit User Pin numbers
		echo ^Echo 5^) View global employees
		echo ^Echo 100^) Check RCMDB for corruption
		echo ^Echo 101^) Backup RCMDB now
		echo ^Echo.
		echo ^Echo.
		echo SET /P SELECTION=Selection:
		echo IF /I "%%SELECTION%%" EQU "1" GOTO :1
		echo IF /I "%%SELECTION%%" EQU "2" GOTO :2
		echo IF /I "%%SELECTION%%" EQU "3" GOTO :3
		echo IF /I "%%SELECTION%%" EQU "4" GOTO :4
		echo IF /I "%%SELECTION%%" EQU "5" GOTO :5
		echo IF /I "%%SELECTION%%" EQU "100" GOTO :100
		echo IF /I "%%SELECTION%%" EQU "101" GOTO :101
		echo ^Echo.
		echo :1
		echo cls
		echo sqlcmd -S RCM\RCM -d RCMDB -i "%%SCRIPTFOLDER%%ViewBasicEmployeeInformation.sql" -o "%%OUTPATH%%Basic Employee Information_%%tdstamp%%.csv" -s"," -w 300
		echo goto start
		echo ^Echo.
		echo :2
		echo cls
		echo sqlcmd -S RCM\RCM -d RCMDB -i "%%SCRIPTFOLDER%%ViewAdvancedEmployeeInformation.sql" -o "%%OUTPATH%%View Advanced Employee Information_%%tdstamp%%.csv" -s"," -w 300
		echo goto start
		echo ^Echo.
		echo :3
		echo cls
		echo sqlcmd -S RCM\RCM -d RCMDB -i "%%SCRIPTFOLDER%%AuditSafeDrop.sql" -o "%%OUTPATH%%Audit Safe Drop_%%tdstamp%%.csv" -s"," -w 300
		echo goto start
		echo ^Echo.
		echo :4
		echo cls
		echo sqlcmd -S RCM\RCM -d RCMDB -i "%%SCRIPTFOLDER%%AuditUserPin.sql" -o "%%OUTPATH%%Audit User Pin_%%tdstamp%%.csv" -s"," -w 300
		echo goto start
		echo ^Echo.
		echo :5
		echo cls
		echo sqlcmd -S RCM\RCM -d RCMDB -i "%%SCRIPTFOLDER%%ViewAllGlobalEmployees.sql" -o "%%OUTPATH%%View All Global Employees_%%datestamp%%.csv" -s"," -w 300
		echo goto start
		echo ^Echo.
		echo :100
		echo cls
		echo sqlcmd -S RCM\RCM -d RCMDB -i "%%SCRIPTFOLDER%%Check RCM DB.sql" -o "%%OUTPATH%%Check RCMDB For Corruption_%%tdstamp%%.csv" -s"," -w 300
		echo goto start
		echo ^Echo.
		echo :101
		echo cls
		echo sqlcmd -S RCM\RCM -d RCMDB -i "%%SCRIPTFOLDER%%Backup RCM DB.sql" -o "%%OUTPATH%%Backup RCMDB_%%tdstamp%%.csv" -s"," -w 300
		echo goto start
		echo ^Echo.
		echo :end
		echo ^exit
	) 1>"C:\%companyname%\Scripts\CF_SQL_QRY.bat"
)

:installarchiver
rem **********************************************************************
rem create bat script to check and backup the RCM DB and then archive backups older than 30 days
	if not exist "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat" (
		echo @echo off >> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo set dbscriptfolder=C:\%companyname%\Scripts\>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo set dbtempfolder=C:\%companyname%\Temp\>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo set dblogfolder=C:\%companyname%\DBLogs\>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo set dbtaskfolder=C:\%companyname%\Tasks\>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo set tdstamp=%%date:~4,2%%%%date:~7,2%%%%date:~10,4%%_%%time:~0,2%%%%time:~3,2%%%%time:~6,2%%>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo set currentdate=%%date:~4,2%%-%%date:~7,2%%-%%date:~10,4%%>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo ^mode ^con: ^cols=75 ^lines=15 ^&^& ^color 4f ^&^& title RCM DB CHECK IN PROGRESS....>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo echo *****CHECKING RCM DATABASE*****>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo sqlcmd -S %dblogin% -d %DBNAME% -i "%%dbscriptfolder%%Check RCM DB.sql" -o "%%dbtempfolder%%RCMDBCheckTempFile.txt">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo copy "%%dbtempfolder%%RCMDBCheckTempFile.txt" "%%dblogfolder%%CHECK_RCM-DB_%%tdstamp%%.txt">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo cls>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo copy "%%dbtempfolder%%RCMDBCheckTempFile.txt" "%%rdblogfolder%%CHECK_RCM-DB_%%tdstamp%%.txt">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo cls>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo PING localhost -n 3 ^>NUL>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo del "%%dbtempfolder%%RCMDBCheckTempFile.txt">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo ^mode ^con: ^cols=75 lines=15 ^&^& ^color 4f ^&^& ^title RCM BACKUP IN PROGRESS....>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo echo *****BACKING UP RCM DATABASE*****>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo sqlcmd -S %dblogin% -d %DBNAME% -i "%%dbscriptfolder%%Backup RCM DB.sql" -o "%%dbtempfolder%%RCMBackupTempFile.txt">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo copy "%%dbtempfolder%%RCMBackupTempFile.txt" "%%dblogfolder%%BACKUP_RCM-DB_%%tdstamp%%.txt" >> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo cls>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo copy "%%dbtempfolder%%RCMBackupTempFile.txt" "%%rdblogfolder%%BACKUP_RCM-DB_%%tdstamp%%.txt" >> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo cls>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo PING localhost -n 3 ^>^NUL>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo del "%%dbtempfolder%%RCMBackupTempFile.txt">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo cls>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Delete DB backups older than X days
		echo ForFiles /p "%primarydbbackuploc1%" /s /d -%dbbackuphistory% /c "cmd /c del @file">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo rem **********************************************************************
		Echo @echo off>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo setlocal EnableExtensions DisableDelayedExpansion>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo rem // Define constants here:>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo set "_ROOT=C:\Program Files\Microsoft SQL Server\MSSQL14.RCM\MSSQL\Backup">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo set "_PATTERN=*.bak">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo set "_LIST=%%TEMP%%\%%~n0.tmp">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo set "_ARCHIVER=%%ProgramFiles%%\7-Zip\7z.exe">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo rem // Get current date in locale-independent format:>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo for /F "tokens=2 delims==" %%%%D in ('wmic OS get LocalDateTime /VALUE'^) do set "TDATE=%%%%D">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo set "TDATE=%%TDATE:~,8%%">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo rem // Create a list file containing all files to move to the archive:>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo ^> "%%_LIST%%" ^(>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo     for /F "delims=" %%%%F in ^('>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo         forfiles /S /P "%%_ROOT%%" /M "%%_PATTERN%%" /D -30 /C "cmd /C echo @path">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo     '^) do echo^(%%%%~F>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo ^) ^&^& ^(>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo     rem // Archive all listed files at once and delete the processed files finally:>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo     "%%_ARCHIVER%%" a -sdel "C:\Program Files\Microsoft SQL Server\MSSQL14.RCM\MSSQL\Backup\Archive\RCMDB_ARCHIVE_%%TDATE%%.zip" @"%%_LIST%%">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo     rem // Delete the list file:>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo     rem del "%%_LIST%%">> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo ^)>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo PING localhost -n 4 ^>NUL>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo PING localhost -n 4 ^>NUL>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo ^) ELSE ^(>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo goto next>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		echo ^)>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		:next
		Echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo endlocal>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo exit /B>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
		Echo.>> "C:\%companyname%\Tasks\RCM-DB-BACKUP.bat"
)

rem **********************************************************************
rem Create scheduled task to backup RCM DB and transfer backups to external drive
	SCHTASKS /DELETE /TN "RCM DB BACKUP" /F
	SCHTASKS /CREATE /SC WEEKLY /D %backupdays% /TN "RCM DB BACKUP" /TR "C:\%companyname%\tasks\RCM-DB-BACKUP.bat" /ST %backuptime%
