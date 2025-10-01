@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Minecraft 服务端增量更新脚本
:: ---------- 参数检查 ----------
if "%~3"=="" (
echo 用法：%~nx0  ^<源目录^>  ^<目标目录^>  ^<远程仓库^>
exit /b 1
)
set "SRC=%~f1"
set "DST=%~f2"
set "REMOTE=%~3"
if "%DST:~-1%"=="\" set "DST=%DST:~0,-1%"
echo [路径] SRC= "%SRC%\%%D"  DST= "%DST%\%%D"
:: 检查 git 是否存在
where git >nul 2>nul || (
echo 错误：未找到 git.exe，请先安装 Git for Windows 并加入 PATH
exit /b 1
)
:: ---------- 1. 生成 modlist.txt ----------
echo [1/3] 正在生成 mod 列表……
set "MODLIST=%DST%\modlist.txt"
if not exist "%SRC%\mods" (
    echo 警告：源目录未找到 mods 文件夹
    echo. > "%MODLIST%"
) else (
    (for %%F in ("%SRC%\mods\*.jar") do echo %%~nxF) > "%MODLIST%"
)
echo    已输出到 %MODLIST%
:: ---------- 2. 删除并拷贝配置/脚本/世界配置 ----------
echo [2/3] 正在同步配置文件夹……
for %%D in (config kubejs defaultconfigs) do (
    if exist "%DST%\%%D" (
        echo    删除旧 %%D ……
        rmdir /s /q "%DST%\%%D"
    )
    if exist "%SRC%\%%D" (
        echo [路径] SRC= "%SRC%\%%D"  DST= "%DST%\%%D"
        echo    拷贝 %%D ……
        xcopy "%SRC%\%%D" "%DST%\%%D\" /e /y /i >nul
    )
)

:: 只拷 world\serverconfig
if exist "%DST%\world\serverconfig" (
    echo    删除旧 world\serverconfig ……
    rmdir /s /q "%DST%\world\serverconfig"
)
if exist "%SRC%\world\serverconfig" (
    echo [路径] SRC= "%SRC%\world\serverconfig"  DST= "%DST%\world\serverconfig"
    echo    拷贝 world\serverconfig ……
    xcopy "%SRC%\world\serverconfig" "%DST%\world\serverconfig\" /e /y /i >nul
)
:: ---------- 3. Git 仓库初始化与差异提交 ----------
echo [3/3] 正在检查 Git 变更……
pushd "%DST%"
:: 保证远程已存在即可，不再重复添加
git add -A
git diff --quiet --cached
if !errorlevel!==0 (
echo    无变更，跳过提交。
) else (
echo    检测到变更，正在提交……
set "MSG=Auto-update %date:~0,4%-%date:~5,2%-%date:~8,2% %time:~0,2%:%time:~3,2%"
git commit -m "!MSG!"
echo    推送至远程……
git push
)
popd
echo 全部完成！