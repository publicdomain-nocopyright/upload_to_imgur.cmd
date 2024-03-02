@ECHO OFF

:: Imgur Client ID
:: https://api.imgur.com/oauth2/addclient

REM   Imgur Client ID can be passed before running this script
REM SET "your_client_id=caff63f7ee5ede2"

REM Imgur Client ID, only if Annonymous account is exhausted.
REM IF NOT DEFINED too_many_requests_your_client_id SET "too_many_requests_your_client_id=d6e4fbc968dfde0"

::  Empty: limited - Annonymous uploader
IF NOT DEFINED your_client_id SET "your_client_id="

:Enable_batch_script_delayed_variables
:: Allows for variables to mutate inside code blocks scope: 
:: delays execution; to scan for variable mutations in code blocks scope.
SETLOCAL EnableDelayedExpansion

:: Workaround for limited limited %* functionality by using a variable
IF NOT DEFINED IS_MINIMIZED (
	SET "Command_line_arguments=%~1"
)

:Usage_page
IF NOT DEFINED IS_MINIMIZED (
	IF "!Command_line_arguments!"=="" (
		ECHO Program: upload_to_imgur.cmd
		ECHO Description: Uploads .mp4 .gif .png .jpg file to Imgur.com using curl.exe
		ECHO License: Public Domain
		ECHO Please provide filename.
		ECHO Usage:
		ECHO   upload_to_imgur Untitled.png
		ECHO   upload_to_imgur.cmd .\Untitled.mp4
		ECHO   upload_to_imgur.cmd "C:\Users\Windows10\Desktop\New folder\Untitled.mp4"
		ECHO  Drag N Drop is also supported.
		EXIT /B
	)
)



IF NOT DEFINED IS_MINIMIZED (
	IF "%~x1"=="" (
		ECHO Remember to type file extension, like: .png .mp4 and .gif
		EXIT /B
	)

	
	IF "%~x1"==".jpeg" SET "image=0" && GOTO :File_type_is_supported
	IF "%~x1"==".jpg"  SET "image=0" && GOTO :File_type_is_supported
	IF "%~x1"==".png"  SET "image=0" && GOTO :File_type_is_supported
	IF "%~x1"==".gif"  SET "image=0" && GOTO :File_type_is_supported
	IF "%~x1"==".mp4"  SET "video=0" && GOTO :File_type_is_supported
	
	ECHO ERROR IN: %0
	ECHO   Your Command Line: %0 %1
	ECHO     The file you selected to upload: %1
	ECHO       The file type "%~x1" is not supported.
	IF /I NOT "%CMDCMDLINE:"=%" == "%COMSPEC% " PAUSE && EXIT
	IF /I  "%CMDCMDLINE:"=%" == "%COMSPEC% " EXIT /B
)
:File_type_is_supported

:Check_if_file_exists_by_using_size_parameter_extension
IF NOT DEFINED IS_MINIMIZED (
	IF "%~z1"=="" (
		ECHO ERROR IN: %0
		ECHO   Your Command Line: %0 %1
		ECHO     The file "%~f1" does not exist.
		EXIT /B
	)
)

:Notice_about_upload_to_be_started
IF NOT DEFINED IS_MINIMIZED (
	ECHO Starting to upload "%~f1" to imgur.com
)


:Add_title_to_the_window_after_minimization
IF DEFINED IS_MINIMIZED (
	TITLE Imgur Uploader [depends on curl.exe]
)

:Relaunch_the_script_in_a_Minimized_Command_Prompt_Window_if_double_clicked_as_a_Desktop_Icon
IF /I NOT "%CMDCMDLINE:"=%" == "%COMSPEC% " (
	IF NOT DEFINED IS_MINIMIZED (
		SET "IS_MINIMIZED=1" 
		START "" /min "%~dpnx0"
		EXIT /B
	)
)

:Parse_passed_arguments_as_files
FOR %%G IN ("!Command_line_arguments!") DO (
	ECHO File: "%%~fG" 
	ECHO File name: "%%~nG"	
	ECHO File type: "%%~xG" 
	ECHO File size: "%%~zG" bytes
	SET "selected_file=%%~fG"
	
)
echo !selected_file!

SET "add_random_digits_to_filename_in_case_of_already_in_use=%RANDOM%"

IF DEFINED image (
	curl --request POST -H "Authorization: Client-ID !your_client_id!"  -F "image=@!selected_file!" --url "https://api.imgur.com/3/upload" > "%temp%\%add_random_digits_to_filename_in_case_of_already_in_use%upload_information.json"
)


IF DEFINED video (
	curl --request POST -H "Authorization: Client-ID !your_client_id!"  -F "video=@!selected_file!" --url "https://api.imgur.com/3/upload" > "%temp%\%add_random_digits_to_filename_in_case_of_already_in_use%upload_information.json"
)


:Get_uploaded_URL
SETLOCAL EnableDelayedExpansion
FOR /F " tokens=7 delims=:," %%I IN (%temp%\%add_random_digits_to_filename_in_case_of_already_in_use%upload_information.json) DO IF NOT DEFINED UPLOAD_URL_ID SET "UPLOAD_URL_ID=%%I"
SET "UPLOAD_URL_ID=%UPLOAD_URL_ID:"=%"
SET "UPLOAD_URL_ID=%UPLOAD_URL_ID: =%"
ECHO !UPLOAD_URL_ID!

IF "!UPLOAD_URL_ID!"=="TooManyRequests" (
	ECHO Imgur.com says there are too many requests from your computer, please wait: five or more minutes.
	IF DEFINED too_many_requests_your_client_id  SET "your_client_id=!too_many_requests_your_client_id!"
	ECHO Too many requests for "!your_client_id!"
	
	
	IF DEFINED too_many_requests_your_client_id (
		IF NOT "!too_many_requests_your_client_id!" == "Already tried client ID" (
			SET "too_many_requests_your_client_id=Already tried client ID"
			GOTO :Enable_batch_script_delayed_variables
		)
	)
	IF /I NOT "%CMDCMDLINE:"=%" == "%COMSPEC% " PAUSE && EXIT
	IF /I  "%CMDCMDLINE:"=%" == "%COMSPEC% " EXIT /B
)

IF DEFINED video (
	CALL :Wait_for_upload
	explorer https://i.imgur.com/!UPLOAD_URL_ID!.mp4
)

IF DEFINED image (
	explorer https://i.imgur.com/!UPLOAD_URL_ID!
)

IF NOT DEFINED IS_MINIMIZED EXIT /B
IF DEFINED IS_MINIMIZED (
	PAUSE
	EXIT
)


EXIT
:Wait_for_upload
curl --fail-with-body --head --silent "https://i.imgur.com/!UPLOAD_URL_ID!.mp4"
IF ERRORLEVEL 22 (
	TIMEOUT /t 1
	CALL :Wait_for_upload
) ELSE (
	FOR /F "USEBACKQ" %%a in (`curl --silent --output nul --verbose --write-out "%%{http_code}" "https://i.imgur.com/!UPLOAD_URL_ID!.mp4"`) DO (
		SET "HTTP=%%a"
		TIMEOUT /t 1
		ECHO %%a HTTPCODE
	)
	IF "!HTTP!" == "" CALL :Wait_for_upload
	IF NOT "!HTTP!" == "302" (
		ECHO TRUE
	) ELSE (
		ECHO FALSE
		CALL :Wait_for_upload
	)
)
