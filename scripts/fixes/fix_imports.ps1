# Script para corrigir importações no projeto FortSmart Agro
# Este script substituirá todas as referências de 'fortsmartagro' para 'fortsmart_agro_new'

$projectPath = "c:\Users\fortu\fortsmart_agro_new"
$dartFiles = Get-ChildItem -Path $projectPath -Filter "*.dart" -Recurse

$count = 0
foreach ($file in $dartFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($content -match "package:fortsmartagro/") {
        Write-Host "Corrigindo importações em: $($file.FullName)"
        $newContent = $content -replace "package:fortsmartagro/", "package:fortsmart_agro_new/"
        Set-Content -Path $file.FullName -Value $newContent
        $count++
    }
}

Write-Host "Concluído! $count arquivos foram atualizados."
