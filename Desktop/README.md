# Introducation 
As you may know Telegram Desktop has a tdata folder (can be find in installation path) witch datas are saved.
Ofcourse that datas are encrypted with Telegram keys ... good news is that for doing a session hijack we just need to have some files, not to decrypt them :) 


# How Does it work? 
* It uploads the **tdata folder** of Telegram into your github account. Then you can just download the folder and replace the current tdata folder with the new one in your telegram path 
* The tdata contains three critical files :
 1. key_datas
 2. maps
 3. session related file
  
* It uses **wininet.dll** for creating an internet connection
















