@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
SET fname=default
for %%X in (%1\*.xml.enc) do (
SET fname=%%X
Cryptonite -C -D "!fname!" "!fname:~0,-4!.epsctmp"
)
CLS
ECHO Study Decryption and Decompression complete.