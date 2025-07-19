$mapboxGradlePath = "C:\Users\fortu\AppData\Local\Pub\Cache\hosted\pub.dev\mapbox_gl-0.16.0\android\build.gradle"

# Ler o conteúdo do arquivo
$content = Get-Content $mapboxGradlePath -Raw

# Verificar se o arquivo já contém a configuração de namespace
if ($content -notmatch "namespace") {
    # Adicionar a configuração de namespace após a linha "apply plugin: 'com.android.library'"
    $newContent = $content -replace "apply plugin: 'com.android.library'", "apply plugin: 'com.android.library'`r`n`r`nandroid {`r`n    namespace 'com.mapbox.mapboxgl'`r`n}"
    
    # Escrever o conteúdo modificado de volta para o arquivo
    Set-Content -Path $mapboxGradlePath -Value $newContent
    
    Write-Host "Namespace adicionado ao arquivo build.gradle do plugin mapbox_gl."
} else {
    Write-Host "O arquivo build.gradle do plugin mapbox_gl já contém a configuração de namespace."
}
