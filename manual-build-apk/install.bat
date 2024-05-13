@echo off

set apk=%~dp0out\manual-build-aligned-signed.apk

echo install %apk% to connected phone
if not exist "%apk%" goto fail

call adb install %apk%
goto end

:fail
echo apk file not existed
exit 1

:end
echo install success