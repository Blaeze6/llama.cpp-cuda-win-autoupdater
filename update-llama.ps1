$targetDir = "."
$apiUrl = "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"
Write-Host "[INFO] Fetching the latest release from ggml-org API..." -ForegroundColor Cyan
$release = Invoke-RestMethod -Uri $apiUrl
$binAsset = $release.assets | Where-Object { $_.name -match "^llama-.*-bin-win-cuda-13.*-x64\.zip$" } | Select-Object -First 1
$dllAsset = $release.assets | Where-Object { $_.name -match "^cudart-llama-bin-win-cuda-13.*-x64\.zip$" } | Select-Object -First 1
if (-not $binAsset) {
    Write-Host "[ERROR] Main CUDA 13 package not found!" -ForegroundColor Red
    Exit
}
Write-Host "[INFO] Detected build: $($release.tag_name)" -ForegroundColor Green
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
Write-Host "[SUCCESS] Update completed successfully! You have the latest build with all necessary DLLs." -ForegroundColor Green