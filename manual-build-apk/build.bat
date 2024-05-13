@echo off
SETLOCAL EnableDelayedExpansion

set tag="[PG][ManualBuild]"
@REM: echo to stdout of bat bash
echo %tag% Start

set buildDir=%~dp0out
rmdir /s /q "%buildDir%"
mkdir "%buildDir%"
echo %tag% created build dirs at %buildDir%

set sdk=D:\AndroidSdk
set androidJar=%sdk%\platforms\android-30\android.jar

@REM build resources
echo %tag% compile resources
set mainDir=%~dp0app\src\main
set appResDir=%mainDir%\res
set manifest=%mainDir%\AndroidManifest.xml
set compileTargetArchive=%buildDir%\compiledRes
mkdir %compileTargetArchive%
set compileTargetArchiveUnzip=%buildDir%\compiledResDir
mkdir %compileTargetArchiveUnzip%
set linkTarget=%buildDir%\res.apk
set r=%buildDir%\r

@REM compile
echo %tag% aapt2 compiling
aapt2 compile -o "%compileTargetArchive%" --dir "%appResDir%"
echo %tag% aapt2 comiled finished
@REM powershell -Command "Expand-Archive -Path %compileTargetArchive% -DestinationPath %compileTargetArchiveUnzip%"

@REM link
echo %tag% aapt2 linking

set linkInputs=
for /f %%i in ('dir /b /a-d %compileTargetArchive%') do (
    set "linkInputs=!linkInputs! "%compileTargetArchive%\%%i""
)
@REM echo linking inputs %linkInputs% 
aapt2 link -o %linkTarget% -I %androidJar% --manifest %manifest% --java %r% %linkInputs%
echo %tag% aapt2 generated -R.java: %r% -res: %linkTarget% -jar: %androidJar% -manifest: %manifest%

@REM compile java classes
echo %tag% compile java classes
set classesOutput=%buildDir%\classes
set package=me\ikvarxt\manualbuildapp
set mainClassesInput=%mainDir%\java\%package%\MainActivity.java
set rDotJava=%r%\%package%\R.java
mkdir %classesOutput%
echo %tag% create classesOutput dir at %classesOutput%

@REM .java -- .class
echo %tag% javac .java -- .class
javac -d %classesOutput% %mainClassesInput% %rDotJava% -classpath %androidJar%
echo %tag% javac generated %classesOutput%

echo %tag% D8 .class -- .dex
set dexOutput=%buildDir%\dex
mkdir %dexOutput%
call d8 %classesOutput%\%package%\*.class --lib %androidJar% --output %dexOutput%
echo %tag% d8 generated %dexOutput%\classes.dex

@REM build apk
echo %tag% package and sign the apk
set tools=%sdk%\tools\lib
set originApk=%buildDir%\manual-build-unaligned-unsigned.apk
set alignedApk=%buildDir%\manual-build-aligned-unsigned.apk
set zipAlignedSignedApk=%buildDir%\manual-build-aligned-signed.apk

@REM package apk zip file
echo %tag% packaging
set packagingJars=
for /f %%i in ('dir /b /a-d %tools%\*.jar') do (
    set "packagingJars=!packagingJars!;%tools%\%%i"
)
echo %tag% package jars: %packagingJars%
java -cp %packagingJars% com.android.sdklib.build.ApkBuilderMain %originApk% -u -v -z %linkTarget% -f %dexOutput%\classes.dex
echo %tag% build apk by ApkBuilderMain at %originApk%

@REM zipalign the original APK
echo %tag% zip Aligning apk
zipalign 4 %originApk% %alignedApk%
echo %tag% APk aligned %alignedApk%

@REM sign the aligned apk
echo %tag% Sign APK
call apksigner sign --ks debug.keystore --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out %zipAlignedSignedApk% %alignedApk%
echo %tag% APK signed 
echo %tag% Build completed, check the apk %zipAlignedSignedApk%