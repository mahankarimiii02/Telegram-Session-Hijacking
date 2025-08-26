# Introducation 
As you may know your Telegram Desktop has a tdata folder (can be find in installation path) witch datas are saved 
Ofcourse that datas are encrypted and for reading them we need to decrypt it using telegram keys ... but what if we don't want to read any file and just get the session? The intersting part is that for getting access to an account you don't need to decrypt anything ... the only thing you want is a 1~4 KB folder :)

# How Does it work? 
* It uploads the **tdata folder** of Telegram into your github account. Then you can just download the folder and replace the current tdata folder with the new one in your telegram path 
* The tdata contains three critical files :
  1. key_data
  2. maps
  3. session related file
  
* It uses **wininet.dll** for creating an internet connection











