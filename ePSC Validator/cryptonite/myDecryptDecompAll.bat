@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SET fname=default
for %%X in (%1\*.xml.enc) do (
SET fname=%%X
"%~dp0Cryptonite.exe" -C -D "!fname!" "!fname:~0,-4!.epsctmp"
)
ECHO Study Decryption and Decompression complete.