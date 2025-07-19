# Script para adicionar namespace a todos os plugins Flutter que não possuem
# Este script procura por arquivos build.gradle em plugins e adiciona a linha namespace

Write-Host "Iniciando correção de namespace em plugins Flutter..." -ForegroundColor Green

$pubCacheDir = "$env:USERPROFILE\.pub-cache"
if (-not (Test-Path $pubCacheDir)) {
    $pubCacheDir = "$env:APPDATA\Pub\Cache"
}
if (-not (Test-Path $pubCacheDir)) {
    $pubCacheDir = "$env:LOCALAPPDATA\Pub\Cache"
}

$hostedDir = Join-Path $pubCacheDir "hosted\pub.dev"

if (-not (Test-Path $hostedDir)) {
    Write-Host "Diretório de cache de plugins não encontrado: $hostedDir" -ForegroundColor Red
    exit 1
}

$pluginsFixed = 0

# Encontrar todos os arquivos build.gradle em plugins
$buildGradleFiles = Get-ChildItem -Path $hostedDir -Filter "build.gradle" -Recurse

foreach ($file in $buildGradleFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    
    # Verificar se já tem namespace
    if ($content -notmatch "namespace\s+['\"]") {
        # Determinar o namespace com base no nome do plugin
        $pluginDir = Split-Path -Parent $file.FullName
        $pluginName = Split-Path -Leaf (Split-Path -Parent (Split-Path -Parent $pluginDir))
        $pluginVersion = Split-Path -Leaf (Split-Path -Parent $pluginDir)
        
        # Encontrar a linha que contém "android {"
        $lines = $content -split "`n"
        $androidBlockIndex = -1
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "android\s*\{") {
                $androidBlockIndex = $i
                break
            }
        }
        
        if ($androidBlockIndex -ne -1) {
            # Determinar o namespace com base no grupo do plugin
            $namespace = ""
            
            # Tentar encontrar o grupo no arquivo
            foreach ($line in $lines) {
                if ($line -match "group\s+['\"]([^'\"]+)['\"]") {
                    $namespace = $matches[1]
                    break
                }
            }
            
            # Se não encontrou grupo, usar um padrão baseado no nome do plugin
            if ([string]::IsNullOrEmpty($namespace)) {
                $namespace = "io.flutter.plugins.$($pluginName -replace '-', '_' -replace '\s+', '_')"
            }
            
            # Inserir a linha de namespace após "android {"
            $lines[$androidBlockIndex] = $lines[$androidBlockIndex] + "`n    namespace '$namespace'"
            
            # Salvar o arquivo modificado
            $lines -join "`n" | Set-Content -Path $file.FullName
            
            Write-Host "Adicionado namespace '$namespace' ao plugin $pluginName v$pluginVersion" -ForegroundColor Green
            $pluginsFixed++
        }
    }
}

Write-Host "Correção de namespace concluída. $pluginsFixed plugins foram corrigidos." -ForegroundColor Green

# Adicionar a configuração para desabilitar a verificação de namespace no build.gradle do projeto
Write-Host "Desabilitando verificação de namespace no projeto..." -ForegroundColor Yellow
