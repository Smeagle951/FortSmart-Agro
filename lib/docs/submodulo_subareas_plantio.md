# 🌾 SUBMÓDULO DE SUBÁREAS DE PLANTIO - FORTSMART

## 📋 Visão Geral

O submódulo de subáreas permite que usuários autorizados (Agrônomo/Administrador) delineiem áreas específicas dentro de um talhão para:

- Separar variedades no plantio
- Identificar zonas de experimento com produtos ou técnicas distintas
- Fazer marcações geográficas com finalidades agronômicas
- Usar dados para **consulta e rastreabilidade visual**

## 🚀 Como Usar

### 1. Acessando o Submódulo

1. Vá para o **Módulo de Plantio**
2. Acesse **Cadastro de Plantio**
3. Selecione um talhão
4. Clique no botão **"Registrar Subáreas"** (laranja)

### 2. Gestão de Subáreas

A tela de gestão oferece:

#### 🔍 Filtros
- **Talhão**: Selecionar talhão específico
- **Safra**: Filtrar por safra
- **Cultura**: Filtrar por cultura
- **Variedade**: Filtrar por variedade
- **Mostrar nomes**: Exibir/ocultar nomes no mapa
- **Ocultar inativas**: Filtrar subáreas inativas

#### 🗺️ Visualização no Mapa
- Contorno do talhão (linha cinza)
- Subáreas desenhadas (cores diferentes)
- Legenda com informações detalhadas

### 3. Registrando uma Nova Subárea

#### 📍 Passo 1: Acessar Registro
- Na tela de gestão, clique no ícone **"+"** (Adicionar Subárea)

#### 🎨 Passo 2: Desenhar a Subárea
**Opção A - Desenho Manual:**
1. Clique em **"Desenhar Manual"**
2. Toque no mapa para criar pontos
3. Clique em **"✓"** para finalizar o polígono

**Opção B - GPS (Caminhada):**
1. Clique em **"Caminhar GPS"**
2. Caminhe pelo perímetro da área
3. Clique em **"✓"** para finalizar

#### 📝 Passo 3: Preencher Dados
- **Nome da Subárea**: Identificação única
- **Cultura**: Produto cultivado
- **Variedade**: Variedade específica (opcional)
- **Data de Implantação**: Data do plantio
- **Observações**: Notas adicionais (opcional)

#### 💾 Passo 4: Salvar
- Clique em **"Salvar Subárea"**
- A subárea será criada com cor única automática

### 4. Consultando Subáreas

#### 📊 Visualização
- Acesse a tela de gestão
- Use os filtros para encontrar subáreas específicas
- Visualize no mapa com cores distintas

#### 📈 Estatísticas
- Total de subáreas
- Área total ocupada
- Número de culturas
- Número de variedades

#### 📤 Exportação
- Clique no ícone de download para exportar como GeoJSON
- Compatível com Google Earth e QGIS

## 🔐 Permissões

### 👥 Usuários Autorizados
- **Agrônomo**: Pode criar e consultar subáreas
- **Administrador**: Pode criar e consultar subáreas
- **Técnico**: Apenas consulta
- **Operador**: Apenas consulta

### 🚫 Restrições
- Técnicos e Operadores **não podem** criar subáreas
- Subáreas são **somente leitura** após salvas
- Apenas para **consulta e rastreabilidade**

## 🎨 Cores Automáticas

O sistema atribui automaticamente cores únicas:
- 10 cores padrão cíclicas
- Alto contraste para visualização
- Cores consistentes por subárea

## 📱 Funcionalidades do Mapa

### 🧭 Controles
- **Centralizar GPS**: Posicionar no local atual
- **Zoom**: Pinça para aproximar/afastar
- **Pan**: Arraste para navegar
- **Rotação**: Giro com dois dedos

### 🖼️ Base do Mapa
- **MapTiler Satélite** com cache offline
- Imagens de alta resolução
- Funcionamento offline

## 🔧 Configuração Técnica

### 📊 Banco de Dados
- Tabela: `subareas_plantio`
- Campos: id, talhao_id, safra_id, cultura_id, nome, variedade_id, data_implantacao, area_ha, cor_rgba, geojson, observacoes, criado_em, usuario_id, sincronizado

### 🗺️ Formato GeoJSON
- Polígonos em formato GeoJSON
- Compatível com sistemas GIS
- Exportação para Google Earth/QGIS

### 📍 Validações
- Polígonos devem estar dentro do talhão
- Área total não pode exceder o talhão
- Mínimo 3 pontos por polígono
- Validação de permissões de usuário

## 🚨 Solução de Problemas

### ❌ Erro: "Usuário não tem permissão"
- Verifique se o usuário é Agrônomo ou Administrador
- Entre em contato com o administrador do sistema

### ❌ Erro: "Polígono fora dos limites"
- Redesenhe a subárea dentro do talhão
- Use o contorno do talhão como referência

### ❌ Erro: "Área excede o talhão"
- Verifique a área total das subáreas existentes
- Reduza o tamanho da nova subárea

### ❌ Mapa não carrega
- Verifique a conexão com internet
- Aguarde o carregamento do cache offline
- Reinicie o aplicativo

## 📞 Suporte

Para dúvidas ou problemas:
1. Consulte esta documentação
2. Entre em contato com o suporte técnico
3. Verifique os logs do sistema

---

**Versão**: 1.0  
**Data**: Dezembro 2024  
**Desenvolvido por**: Equipe FortSmart
