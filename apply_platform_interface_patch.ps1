# Script para aplicar patches ao pacote mapbox_gl_platform_interface
$ErrorActionPreference = "Stop"

# Encontrar o diretório do pacote mapbox_gl_platform_interface no cache do pub.dev
$platformInterfaceDir = Get-ChildItem -Path "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev" -Filter "mapbox_gl_platform_interface-0.15.0" -Directory -Recurse | Select-Object -First 1

if ($null -eq $platformInterfaceDir) {
    Write-Host "Diretório do pacote mapbox_gl_platform_interface não encontrado no cache do pub.dev"
    exit 1
}

$platformInterfacePath = $platformInterfaceDir.FullName
Write-Host "Diretório do pacote mapbox_gl_platform_interface encontrado: $platformInterfacePath"

# Arquivos que precisam ser corrigidos
$cameraFile = "$platformInterfacePath\lib\src\camera.dart"
$locationFile = "$platformInterfacePath\lib\src\location.dart"
$uiFile = "$platformInterfacePath\lib\src\ui.dart"

# Função para substituir a chamada hashValues por Object.hash
function Update-HashValues {
    param (
        [string]$FilePath
    )
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        
        # Substituir hashValues por Object.hash
        $content = $content -replace "hashValues\((.*?)\)", "Object.hash(`$1)"
        
        # Substituir hashList por Object.hashAll
        $content = $content -replace "hashList\((.*?)\)", "Object.hashAll(`$1)"
        
        # Adicionar import para dart:ui no início do arquivo se não existir
        if ($content -notmatch "import 'dart:ui'") {
            $content = "import 'dart:ui' as ui;`n$content"
        }
        
        # Salvar as alterações
        $content | Set-Content $FilePath
        
        Write-Host "Arquivo $FilePath atualizado com sucesso!"
    } else {
        Write-Host "Arquivo $FilePath não encontrado!"
    }
}

# Atualizar os arquivos
Update-HashValues -FilePath $cameraFile
Update-HashValues -FilePath $locationFile
Update-HashValues -FilePath $uiFile

Write-Host "Patches aplicados com sucesso ao pacote mapbox_gl_platform_interface!"
