# Define the GitHub repository owner and name
$owner = "RickHuijsmans"
$repo = "zed"

# Get the latest release information from GitHub API
$releaseUrl = "https://api.github.com/repos/$owner/$repo/releases/latest"
$response = Invoke-RestMethod -Uri $releaseUrl -Method Get

# Extract the asset URL and name of the latest release containing "windows" in its filename
$assetUrl = $response.assets | Where-Object { $_.name -match "windows" } | Select-Object -ExpandProperty browser_download_url -First 1
$fileName = $response.assets | Where-Object { $_.name -match "windows" } | Select-Object -ExpandProperty name -First 1

# Log the file name being downloaded
Write-Host "Downloading $fileName..."

# Download the latest release to the current directory
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $assetUrl -OutFile "$PWD\$fileName"

Write-Host "Installing Zed..."

# Define the path to the downloaded file and the extracted executable
$zipPath = "$PWD\$fileName"
$exePath = "$PWD\zed.exe"
$wasRunning = $false

# If the exe already exists, terminate any running processes using it
if (Test-Path $exePath) {
    $processes = Get-Process -Name $([System.IO.Path]::GetFileNameWithoutExtension($exePath)) -ErrorAction SilentlyContinue
    if ($processes) {
        foreach ($process in $processes) {
            Write-Host "Terminating running process $($process.ProcessName)"
            Stop-Process -Id $process.Id -Force

            $wasRunning = $true
        }
    }
}

$outputPath = [System.IO.Path]::GetFileNameWithoutExtension($zipPath)

# Extract the ZIP file if it doesn't already exist, or override the existing exe if it does
Expand-Archive -Path $zipPath -DestinationPath $outputPath -Force
Get-ChildItem -Path "$outputPath\*.exe" -Recurse | Move-Item -Destination "$PWD\" -Force

# Delete the ZIP file after extraction
Remove-Item $zipPath -Force
Remove-Item $outputPath -Force -Recurse

if($wasRunning){
    Write-Host "Restarting Zed..."
    Invoke-Expression $exePath
}