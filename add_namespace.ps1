$cachePath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\mapbox_gl-0.15.0\android\build.gradle"

if (Test-Path $cachePath) {
    Write-Host "Arquivo encontrado: $cachePath"
    $content = Get-Content $cachePath -Raw
    
    # Verifica se o namespace já existe
    if ($content -match "namespace\s*=") {
        Write-Host "Namespace já existe no arquivo."
    } else {
        # Adiciona o namespace após a linha "android {"
        $newContent = $content -replace "android\s*\{", "android {`n    namespace = `"com.mapbox.mapboxgl`""
        
        # Atualiza o compileSdkVersion e targetSdkVersion para 35
        $newContent = $newContent -replace "compileSdkVersion\s+\d+", "compileSdkVersion 35"
        $newContent = $newContent -replace "targetSdkVersion\s+\d+", "targetSdkVersion 35"
        
        # Escreve o conteúdo modificado de volta ao arquivo
        $newContent | Set-Content $cachePath
        Write-Host "Namespace adicionado com sucesso e SDK atualizado para 35."
    }
} else {
    Write-Host "Arquivo não encontrado: $cachePath"
}
