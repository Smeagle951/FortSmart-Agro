# Script PowerShell para corrigir IDs das culturas
# Este script executa a correção de alinhamento dos IDs das culturas com pragas e doenças

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORREÇÃO DE IDS DAS CULTURAS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script irá:" -ForegroundColor Yellow
Write-Host "  1. Limpar todas as culturas, pragas e doenças existentes" -ForegroundColor Yellow
Write-Host "  2. Recriar tudo com IDs corretos" -ForegroundColor Yellow
Write-Host "  3. Verificar a integridade dos dados" -ForegroundColor Yellow
Write-Host ""
Write-Host "ATENÇÃO: Todos os dados de culturas serão recriados!" -ForegroundColor Red
Write-Host ""

$confirmation = Read-Host "Deseja continuar? (S/N)"

if ($confirmation -ne 'S' -and $confirmation -ne 's') {
    Write-Host "Operação cancelada." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Executando correção..." -ForegroundColor Green
Write-Host ""

# Executar o script de correção
flutter run lib/scripts/fix_crop_ids_alignment.dart

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORREÇÃO CONCLUÍDA!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Abra o aplicativo" -ForegroundColor Yellow
Write-Host "  2. Acesse o módulo 'Culturas da Fazenda'" -ForegroundColor Yellow
Write-Host "  3. Verifique se as pragas e doenças aparecem para cada cultura" -ForegroundColor Yellow
Write-Host ""
Write-Host "Leia o arquivo CORRECAO_IDS_CULTURAS_PRAGAS_DOENCAS.md para mais detalhes" -ForegroundColor Cyan
Write-Host ""

pause

