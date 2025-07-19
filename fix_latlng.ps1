$files = Get-ChildItem -Path "c:\Users\fortu\fortsmart_agro_new\lib" -Recurse -Filter "*.dart" | Where-Object { (Get-Content $_.FullName | Select-String -Pattern "import 'package:latlong2/latlong.dart'") -and (Get-Content $_.FullName | Select-String -Pattern "const LatLng") }

foreach ($file in $files) {
    Write-Host "Processando arquivo: $($file.FullName)"
    $content = Get-Content $file.FullName -Raw
    $newContent = $content -replace "const LatLng\(", "LatLng("
    Set-Content -Path $file.FullName -Value $newContent
    Write-Host "Arquivo atualizado: $($file.FullName)"
}

Write-Host "Processo concluído!"
