# Script para corrigir dados do dashboard
Write-Host "🔄 Corrigindo dados do dashboard..." -ForegroundColor Blue

# Navegar para o diretório do projeto
Set-Location "C:\Users\fortu\fortsmart_agro_new"

# Executar o script de correção
Write-Host "📋 Executando correção dos dados..." -ForegroundColor Yellow
flutter run --dart-define=ENABLE_DASHBOARD_FIX=true lib/scripts/fix_dashboard_data.dart

Write-Host "✅ Correção concluída!" -ForegroundColor Green
Write-Host "📱 Reinicie o aplicativo para ver as atualizações" -ForegroundColor Cyan
