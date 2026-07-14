$targetDir = $PSScriptRoot
$apiUrl = "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"
Write-Host "[INFO] Fetching the latest release from ggml-org API..." -ForegroundColor Cyan
$release = Invoke-RestMethod -Uri $apiUrl
$latestTag = $release.tag_name
# Weryfikacja obecnej wersji
$llamaExe = Join-Path $targetDir "llama.exe"
if (Test-Path $llamaExe) {
    # Pobieramy output i sprawdzamy, czy zaczyna się od najnowszego tagu (np. b10012)
    $localVersion = (& $llamaExe version 2>$null) -join ""
    if ($localVersion -match "^$latestTag") {
        Write-Host "[SUCCESS] System is already up to date! Version $latestTag is installed." -ForegroundColor Green
        Write-Host "[INFO] Zero SSD write cycles wasted. Exiting." -ForegroundColor Cyan
        Exit
    }
}
Write-Host "[INFO] Detected new build: $latestTag" -ForegroundColor Green
$binAsset = $release.assets | Where-Object { $_.name -match "^llama-.*-bin-win-cuda-13.*-x64\.zip$" } | Select-Object -First 1
$dllAsset = $release.assets | Where-Object { $_.name -match "^cudart-llama-bin-win-cuda-13.*-x64\.zip$" } | Select-Object -First 1
if (-not $binAsset) {
    Write-Host "[ERROR] Main CUDA 13 package not found!" -ForegroundColor Red
    Exit
}
$binZipPath = Join-Path $targetDir $binAsset.name
Write-Host "[INFO] Downloading binaries ($($binAsset.name))..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $binAsset.browser_download_url -OutFile $binZipPath
tar.exe -xf $binZipPath -C $targetDir
Remove-Item $binZipPath -Force
if ($dllAsset) {
    $dllZipPath = Join-Path $targetDir $dllAsset.name
    Write-Host "[INFO] Downloading CUDA DLLs ($($dllAsset.name))..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $dllAsset.browser_download_url -OutFile $dllZipPath
    tar.exe -xf $dllZipPath -C $targetDir
    Remove-Item $dllZipPath -Force
} else {
    Write-Host "[WARN] CUDA DLLs package not found, skipping." -ForegroundColor Yellow
}
Write-Host "[SUCCESS] Update to $latestTag completed successfully!" -ForegroundColor Green
