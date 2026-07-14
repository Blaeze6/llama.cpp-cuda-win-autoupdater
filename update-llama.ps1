$targetDir = "."
$apiUrl = "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"
Write-Host "[INFO] Odpytuję API ggml-org o najnowszy release..." -ForegroundColor Cyan
$release = Invoke-RestMethod -Uri $apiUrl
# Precyzyjne regexy - znak ^ na początku gwarantuje, że nie pomylimy paczek
$binAsset = $release.assets | Where-Object { $_.name -match "^llama-.*-bin-win-cuda-13.*-x64\.zip$" } | Select-Object -First 1
$dllAsset = $release.assets | Where-Object { $_.name -match "^cudart-llama-bin-win-cuda-13.*-x64\.zip$" } | Select-Object -First 1
if (-not $binAsset) {
    Write-Host "[ERROR] Nie znaleziono głównej paczki z CUDA 13!" -ForegroundColor Red
    Exit
}
Write-Host "[INFO] Wykryto build: $($release.tag_name)" -ForegroundColor Green
# 1. Pobieranie i rozpakowywanie głównych binarek
$binZipPath = Join-Path $targetDir $binAsset.name
Write-Host "[INFO] Pobieram binarki ($($binAsset.name))..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $binAsset.browser_download_url -OutFile $binZipPath
tar.exe -xf $binZipPath -C $targetDir
Remove-Item $binZipPath -Force
# 2. Pobieranie i rozpakowywanie DLL-ek CUDA (jeśli są)
if ($dllAsset) {
    $dllZipPath = Join-Path $targetDir $dllAsset.name
    Write-Host "[INFO] Pobieram CUDA DLLs ($($dllAsset.name))..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $dllAsset.browser_download_url -OutFile $dllZipPath
    tar.exe -xf $dllZipPath -C $targetDir
    Remove-Item $dllZipPath -Force
} else {
    Write-Host "[WARN] Nie znaleziono paczki z DLL-kami, pomijam." -ForegroundColor Yellow
}
Write-Host "[SUCCESS] Aktualizacja zakończona pomyślnie! Masz najnowszego builda ze wszystkimi DLL-kami." -ForegroundColor Green