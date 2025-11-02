# Script simplificado para corrigir o namespace do plugin Mapbox GL local

# Corrigir a versão local do plugin
$localMapboxGlPath = "plugins\mapbox_gl\android\build.gradle"

if (Test-Path $localMapboxGlPath) {
    Write-Host "Arquivo build.gradle local encontrado em: $localMapboxGlPath"
    
    # Ler o conteúdo do arquivo
    $content = Get-Content $localMapboxGlPath -Raw
    
    # Substituir a linha do namespace ou adicionar se não existir
    if ($content -match "namespace\s*=\s*[`"']com\.mapbox\.mapboxgl[`"']") {
        Write-Host "O namespace já está definido corretamente no plugin local."
    } 
    elseif ($content -match "namespace\s*[`"']com\.mapbox\.mapboxgl[`"']") {
        # Corrigir a sintaxe do namespace (adicionar o sinal de igual)
        $newContent = $content -replace "(namespace)\s*([`"']com\.mapbox\.mapboxgl[`"'])", "namespace = `$2"
        $newContent | Set-Content $localMapboxGlPath -Force
        Write-Host "Sintaxe do namespace corrigida no plugin local."
    }
    else {
        # Adicionar o namespace ao bloco android
        $newContent = $content -replace "(android\s*\{)", "`$1`r`n    namespace = `"com.mapbox.mapboxgl`"`r`n"
        $newContent | Set-Content $localMapboxGlPath -Force
        Write-Host "Namespace adicionado com sucesso ao plugin local."
    }
} else {
    Write-Host "Arquivo build.gradle local não encontrado."
}

Write-Host "Processo concluído. Execute 'flutter clean && flutter pub get && flutter build apk --debug' para verificar se o problema foi resolvido."
