# Script para corrigir DashboardCPM.vue

# Ler o arquivo
$content = Get-Content "src/components/dashboard/DashboardCPM.vue" -Raw

# Substituir as linhas problemáticas
$fixed = $content -replace 'await this\.carregarEstatisticasLembretes\(\)', '// await this.carregarEstatisticasLembretes()'
$fixed = $fixed -replace 'await this\.carregarRdmsPendentes\(\)', '// await this.carregarRdmsPendentes()'

# Salvar o arquivo corrigido
$fixed | Set-Content "src/components/dashboard/DashboardCPM.vue" -NoNewline

Write-Host "✅ Arquivo corrigido! As linhas problemáticas foram comentadas." 