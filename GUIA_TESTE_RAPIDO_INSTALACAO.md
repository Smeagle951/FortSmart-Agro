# 🧪 Guia de Teste Rápido - Sistema de Custos

## 🚀 Teste de Compilação

### 1. Análise do Código
```bash
flutter analyze
```
**Resultado esperado:** Sem erros ou apenas warnings menores

### 2. Build de Debug
```bash
flutter build apk --debug
```
**Resultado esperado:** Build concluído com sucesso

## 📱 Teste de Navegação

### 1. Teste das Rotas
Adicione este código temporariamente em qualquer tela para testar:

```dart
// Botões de teste
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/custos/dashboard'),
  child: Text('Teste Dashboard'),
),
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/custos/historico'),
  child: Text('Teste Histórico'),
),
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/custos/menu'),
  child: Text('Teste Menu'),
),
```

### 2. Verificação de Rotas
```dart
// Verificar se as rotas estão registradas
print('Dashboard: ${AppRoutes.hasRoute('/custos/dashboard')}');
print('Histórico: ${AppRoutes.hasRoute('/custos/historico')}');
print('Menu: ${AppRoutes.hasRoute('/custos/menu')}');
```

## 🔍 Verificação de Arquivos

### 1. Verificar se os arquivos existem
```bash
ls lib/modules/application/models/
ls lib/services/custo_aplicacao_integration_service.dart
ls lib/screens/custos/
ls lib/screens/historico/
ls lib/utils/date_utils.dart
```

### 2. Verificar imports no routes.dart
```bash
grep -n "custo_por_hectare_dashboard_screen" lib/routes.dart
grep -n "historico_custos_talhao_screen" lib/routes.dart
grep -n "main_menu_with_costs_integration" lib/routes.dart
```

## ⚡ Teste Rápido de Funcionalidade

### 1. Teste do Serviço
```dart
// Em qualquer tela, adicione temporariamente:
final custoService = CustoAplicacaoIntegrationService();
print('Serviço criado com sucesso');

// Teste de carregamento de dados
try {
  final talhoes = await custoService.carregarTalhoes();
  print('Talhões carregados: ${talhoes.length}');
} catch (e) {
  print('Erro ao carregar talhões: $e');
}
```

### 2. Teste dos Modelos
```dart
// Teste dos modelos
final produto = ApplicationProduct(
  id: '1',
  nome: 'Teste',
  unidade: 'L',
  dosePorHa: 2.0,
  precoUnitario: 50.0,
  estoqueAtual: 100.0,
);

print('Produto criado: ${produto.nome}');
print('Custo por hectare: R\$ ${produto.custoPorHectare.toStringAsFixed(2)}');
```

## 🎯 Checklist de Teste

### ✅ Compilação
- [ ] `flutter analyze` sem erros
- [ ] `flutter build apk --debug` bem-sucedido

### ✅ Navegação
- [ ] Rota `/custos/dashboard` funciona
- [ ] Rota `/custos/historico` funciona
- [ ] Rota `/custos/menu` funciona

### ✅ Funcionalidade
- [ ] Serviço `CustoAplicacaoIntegrationService` instancia
- [ ] Modelos `ApplicationProduct` e `ApplicationCalculationModel` funcionam
- [ ] Telas carregam sem erros

### ✅ Integração
- [ ] Imports corretos no `routes.dart`
- [ ] Configuração de módulo ativa
- [ ] Rotas registradas corretamente

## 🐛 Solução de Problemas Comuns

### Erro: "Target of URI doesn't exist"
**Solução:** Verificar se o arquivo existe e o caminho está correto

### Erro: "The method 'xxx' isn't defined"
**Solução:** Verificar se o método existe no serviço/modelo

### Erro: "No such file or directory"
**Solução:** Criar o arquivo que está faltando

### Erro: "The getter 'xxx' isn't defined"
**Solução:** Verificar se a propriedade existe no modelo

## 📞 Próximos Passos

Após os testes bem-sucedidos:

1. **Integração com dados reais** - Seguir `GUIA_INTEGRACAO_DADOS_REAIS.md`
2. **Personalização de cores** - Seguir `GUIA_PERSONALIZACAO_CORES_ESTILOS.md`
3. **Testes completos** - Seguir `GUIA_TESTES_VALIDACAO_COMPLETA.md`

## 🎉 Sucesso!

Se todos os testes passarem, o sistema de custos está instalado e funcionando corretamente!

**Status:** ✅ Pronto para uso
