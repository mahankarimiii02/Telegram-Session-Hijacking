# Telegram Session Hijacker
This project has two parts : 
1. Telegram Desktop session hijacker
2. Telegram Web session hijacker 

For now, this project is written in PowerShell. I may rewrite it in other languages in the future.

# How it works?
* In Web version it checks for a file (leveldb) in Chrome Local Storage path, then if any Telegram session details were found there, it will uploads the file into your github repo
* In Desktop version at first it checks if tdata folder path is available, if the path be available then it uploads some files from the path (including maps, key_datas, etc) into your github repo

notice that :
1. In both versions we use **wininet.dll** for creating the connection
2. The Chrome Local Storage is a temporary memory, so before using the Web version make sure that the target system has been used telegram web recently
3. This is a session hijacker, not a session decrypter. So if the session uses Local Passcode, you should use **tdata decrypters** after you get the session file. They can be find by a simple search in github

## Requirements
* Works on **Powershell version 3+**
* You need to have a **GitHub Account** and also **GitHub API Key**

## Warning 
This project is for **Educational Purposes Only**. Any abuse of this project is not my responsibility and is taken at your own risk.
