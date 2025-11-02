# 📊 Dashboard Informativa - FortSmart Agro

## Visão Geral

A Dashboard Informativa é uma nova funcionalidade que exibe cards informativos com dados reais de todos os módulos do sistema FortSmart Agro. Cada card mostra informações atualizadas em tempo real do banco de dados, proporcionando uma visão completa e atualizada do estado da fazenda.

## 🎯 Funcionalidades

### Cards Informativos

A dashboard apresenta 6 cards principais organizados em um grid 2x3:

#### 1. **Card da Fazenda** 🏡
- **Status**: Configurada ou não configurada
- **Informações exibidas**:
  - Nome da fazenda
  - Proprietário
  - Localização (cidade/UF)
  - Área total em hectares
- **Cor**: Verde quando configurada, cinza quando não configurada
- **Ação**: Navega para configurações da fazenda

#### 2. **Card de Alertas** ⚠️
- **Status**: Número de alertas ativos
- **Informações exibidas**:
  - Total de alertas ativos
  - Alertas de baixo estoque
  - Monitoramentos pendentes
- **Cor**: Vermelho para alertas críticos, laranja para alertas normais, cinza quando não há alertas
- **Ação**: Navega para tela de alertas

#### 3. **Card de Talhões** 📐
- **Status**: Número de talhões cadastrados
- **Informações exibidas**:
  - Total de talhões cadastrados
  - Área total em hectares
  - Talhões ativos
  - Data da última atualização
- **Cor**: Azul quando há talhões, cinza quando não há
- **Ação**: Navega para tela de talhões

#### 4. **Card de Plantios** 🌱
- **Status**: Número de culturas ativas
- **Informações exibidas**:
  - Total de culturas plantadas
  - Área plantada em hectares
  - Cultura principal
  - Variedade principal
- **Cor**: Verde quando há plantios, cinza quando não há
- **Ação**: Navega para tela de plantios

#### 5. **Card de Monitoramentos** 🔍
- **Status**: Número de monitoramentos realizados
- **Informações exibidas**:
  - Monitoramentos pendentes
  - Monitoramentos realizados
  - Último talhão monitorado
- **Cor**: Laranja quando há pendências, roxo quando há monitoramentos, cinza quando não há
- **Ação**: Navega para tela de monitoramentos

#### 6. **Card de Estoque** 📦
- **Status**: Número de itens em estoque
- **Informações exibidas**:
  - Total de itens
  - Itens com baixo estoque
  - Item principal
- **Cor**: Vermelho quando há baixo estoque, laranja quando há itens, cinza quando não há
- **Ação**: Navega para tela de estoque

## 🚀 Ações Rápidas

A dashboard inclui seções de ações rápidas que permitem acesso direto às principais funcionalidades:

### Grid de Ações Rápidas
- **Novo Monitoramento**: Inicia um novo monitoramento
- **Cadastrar Talhão**: Adiciona um novo talhão
- **Registrar Plantio**: Registra um novo plantio
- **Adicionar Estoque**: Adiciona itens ao estoque

### Botão Flutuante (FAB)
- **Menu de Ações**: Abre um menu com todas as ações rápidas disponíveis

## 📈 Distribuição de Atividades

A dashboard inclui uma seção visual que mostra:
- **Gráfico circular** com o total de atividades
- **Legenda** com breakdown por tipo:
  - Talhões
  - Plantios
  - Monitoramentos

## 🔄 Atualização Automática

### Cache Inteligente
- **Duração do cache**: 2 minutos
- **Atualização automática**: A cada 5 minutos
- **Refresh manual**: Pull-to-refresh disponível

### Dados em Tempo Real
- Todos os dados são buscados diretamente do banco de dados
- Não utiliza dados simulados ou fictícios
- Integração completa com todos os módulos do sistema

## 🛠️ Implementação Técnica

### Arquivos Principais

1. **`lib/services/dashboard_data_service.dart`**
   - Serviço principal para buscar dados do banco
   - Cache inteligente para otimização
   - Integração com todos os serviços existentes

2. **`lib/widgets/dashboard/informative_dashboard_cards.dart`**
   - Widgets dos cards informativos
   - Design responsivo e moderno
   - Cores dinâmicas baseadas no status

3. **`lib/screens/dashboard/informative_dashboard_screen.dart`**
   - Tela principal da dashboard
   - Layout responsivo
   - Integração com ações rápidas

4. **`lib/models/dashboard/dashboard_data.dart`**
   - Modelos de dados para a dashboard
   - Estruturas para todos os tipos de informações

### Integração com Módulos

A dashboard se integra com os seguintes módulos:
- **Fazenda**: `FarmService`
- **Talhões**: `TalhaoService`
- **Plantios**: `PlantingService`
- **Monitoramentos**: `MonitoringService`
- **Estoque**: `InventoryService`

## 🎨 Design e UX

### Características Visuais
- **Design moderno**: Cards com bordas arredondadas e sombras
- **Cores dinâmicas**: Baseadas no status de cada módulo
- **Ícones intuitivos**: Representam visualmente cada funcionalidade
- **Layout responsivo**: Adapta-se a diferentes tamanhos de tela

### Experiência do Usuário
- **Navegação intuitiva**: Tap nos cards para acessar módulos
- **Feedback visual**: Cores e badges indicam status
- **Ações rápidas**: Acesso direto às principais funcionalidades
- **Atualização suave**: Pull-to-refresh e atualização automática

## 📱 Como Acessar

### Via Menu Drawer
1. Abra o menu lateral (hamburger menu)
2. Selecione "Dashboard Informativa" na seção "Gerenciamento"

### Via Rota Direta
```dart
Navigator.pushNamed(context, AppRoutes.informativeDashboard);
```

## 🔧 Configuração

### Pré-requisitos
- Banco de dados configurado
- Módulos do sistema funcionando
- Serviços de dados ativos

### Personalização
Os cards podem ser personalizados modificando:
- Cores em `informative_dashboard_cards.dart`
- Layout em `informative_dashboard_screen.dart`
- Dados em `dashboard_data_service.dart`

## 🐛 Solução de Problemas

### Cards não carregam
- Verifique se os serviços estão funcionando
- Confirme se o banco de dados está acessível
- Verifique logs de erro no console

### Dados desatualizados
- Use pull-to-refresh para atualizar manualmente
- Verifique se o cache não está corrompido
- Reinicie o aplicativo se necessário

### Performance lenta
- Verifique se há muitos dados no banco
- Considere otimizar consultas no `dashboard_data_service.dart`
- Monitore uso de memória

## 🚀 Próximas Melhorias

### Funcionalidades Planejadas
- **Gráficos avançados**: Mais visualizações de dados
- **Filtros**: Por período, talhão, cultura, etc.
- **Exportação**: Relatórios em PDF/Excel
- **Notificações push**: Alertas em tempo real
- **Widgets personalizáveis**: Usuário pode escolher quais cards exibir

### Otimizações
- **Lazy loading**: Carregamento sob demanda
- **Background sync**: Sincronização em segundo plano
- **Offline support**: Funcionamento sem internet
- **Performance**: Otimização de consultas e cache

## 📞 Suporte

Para dúvidas ou problemas com a Dashboard Informativa:
1. Verifique este documento
2. Consulte os logs do aplicativo
3. Entre em contato com a equipe de desenvolvimento

---

**Versão**: 1.0.0  
**Última atualização**: Janeiro 2025  
**Compatibilidade**: Flutter 3.0+
