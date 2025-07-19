# Script para aplicar patches ao plugin Mapbox GL e suas dependências
$ErrorActionPreference = "Stop"

Write-Host "Iniciando aplicação de patches para o Mapbox GL e suas dependências..."

# Encontrar o diretório do plugin Mapbox GL no cache do pub.dev
$mapboxDir = Get-ChildItem -Path "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev" -Filter "mapbox_gl-0.15.0" -Directory -Recurse | Select-Object -First 1

if ($null -eq $mapboxDir) {
    Write-Host "Diretório do plugin Mapbox GL não encontrado no cache do pub.dev"
    exit 1
}

$mapboxPath = $mapboxDir.FullName
Write-Host "Diretório do plugin Mapbox GL encontrado: $mapboxPath"

# Encontrar o diretório do plugin Mapbox GL Platform Interface no cache do pub.dev
$platformInterfaceDir = Get-ChildItem -Path "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev" -Filter "mapbox_gl_platform_interface-0.15.0" -Directory -Recurse | Select-Object -First 1

if ($null -eq $platformInterfaceDir) {
    Write-Host "Diretório do plugin Mapbox GL Platform Interface não encontrado no cache do pub.dev"
    exit 1
}

$platformInterfacePath = $platformInterfaceDir.FullName
Write-Host "Diretório do plugin Mapbox GL Platform Interface encontrado: $platformInterfacePath"

# Diretório de origem dos patches
$patchesDir = ".\patches\mapbox_gl"

# Diretório de destino para os arquivos Java
$javaDir = "$mapboxPath\android\src\main\java\com\mapbox\mapboxgl"

# Verificar se o diretório de destino existe
if (-not (Test-Path $javaDir)) {
    Write-Host "Diretório Java não encontrado: $javaDir"
    exit 1
}

Write-Host "Copiando arquivos Java para $javaDir"
Copy-Item -Path "$patchesDir\MapboxMapsPlugin.java" -Destination "$javaDir\MapboxMapsPlugin.java" -Force
Copy-Item -Path "$patchesDir\GlobalMethodHandler.java" -Destination "$javaDir\GlobalMethodHandler.java" -Force
Copy-Item -Path "$patchesDir\MapboxMapFactory.java" -Destination "$javaDir\MapboxMapFactory.java" -Force
Copy-Item -Path "$patchesDir\MapboxMapBuilder.java" -Destination "$javaDir\MapboxMapBuilder.java" -Force
Copy-Item -Path "$patchesDir\MapboxMapController.java" -Destination "$javaDir\MapboxMapController.java" -Force

Write-Host "Patches para o plugin Mapbox GL aplicados com sucesso!"

# Atualizar o build.gradle do plugin Mapbox GL
$buildGradlePath = "$mapboxPath\android\build.gradle"

if (Test-Path $buildGradlePath) {
    $buildGradle = Get-Content $buildGradlePath -Raw
    
    # Verificar se o namespace já existe
    if ($buildGradle -notmatch "namespace\s*=") {
        Write-Host "Adicionando namespace ao build.gradle..."
        $buildGradle = $buildGradle -replace "android\s*\{", "android {`n    namespace `"com.mapbox.mapboxgl`""
    }
    
    # Atualizar compileSdkVersion e targetSdkVersion
    $buildGradle = $buildGradle -replace "compileSdkVersion\s+\d+", "compileSdkVersion 35"
    $buildGradle = $buildGradle -replace "minSdkVersion\s+\d+", "minSdkVersion 21"
    
    # Adicionar targetSdkVersion se não existir
    if ($buildGradle -notmatch "targetSdkVersion") {
        $buildGradle = $buildGradle -replace "minSdkVersion\s+\d+", "minSdkVersion 21`n        targetSdkVersion 35"
    } else {
        $buildGradle = $buildGradle -replace "targetSdkVersion\s+\d+", "targetSdkVersion 35"
    }
    
    # Atualizar as configurações de compatibilidade do Java
    $buildGradle = $buildGradle -replace "sourceCompatibility JavaVersion.VERSION_1_8", "sourceCompatibility JavaVersion.VERSION_17"
    $buildGradle = $buildGradle -replace "targetCompatibility JavaVersion.VERSION_1_8", "targetCompatibility JavaVersion.VERSION_17"
    
    # Salvar as alterações
    Set-Content -Path $buildGradlePath -Value $buildGradle

    Write-Host "Build.gradle atualizado com sucesso!"

    # Aplicar patches ao mapbox_gl_platform_interface
    Write-Host "Aplicando patches ao mapbox_gl_platform_interface..."

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

    Write-Host "Patches aplicados com sucesso ao mapbox_gl_platform_interface!"
    Write-Host "Todos os patches foram aplicados com sucesso!"
} else {
    Write-Host "Arquivo build.gradle não encontrado: $buildGradlePath"
}

Write-Host "Processo de patch concluído!"
