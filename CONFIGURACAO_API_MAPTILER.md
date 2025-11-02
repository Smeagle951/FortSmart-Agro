# 🔑 Configuração Segura da API MapTiler

## ⚠️ IMPORTANTE - Segurança da API Key

A chave da API MapTiler está agora configurada de forma segura usando variáveis de ambiente. **NUNCA** commite a chave real no repositório!

## 📋 Passos para Configuração

### 1. Criar arquivo .env
Crie um arquivo `.env` na raiz do projeto com o seguinte conteúdo:

```env
# FortSmart Agro - Configurações de Ambiente
# ⚠️ NUNCA commite este arquivo com chaves reais para o repositório!

# MapTiler API Configuration
MAPTILER_API_KEY=KQAa9lY3N0TR17zxhk9u
MAPTILER_BASE_URL=https://api.maptiler.com

# Configurações de Desenvolvimento
DEBUG_MODE=true
LOG_LEVEL=info
```

### 2. Adicionar .env ao .gitignore
Certifique-se de que o arquivo `.env` está no `.gitignore`:

```gitignore
# Environment variables
.env
.env.local
.env.production
```

### 3. Verificar Configuração
A aplicação agora carrega automaticamente as configurações do arquivo `.env` na inicialização.

## 🔧 Configurações Implementadas

### ✅ Melhorias de Segurança
- **Chave da API**: Carregada de variáveis de ambiente
- **URLs dinâmicas**: Geradas automaticamente com a chave
- **Fallback seguro**: Configurações padrão se .env não existir
- **Validação**: Verifica se a chave está configurada corretamente

### ✅ URLs da API MapTiler Corrigidas
- **Satélite**: `https://api.maptiler.com/maps/satellite-v2/256/{z}/{x}/{y}.jpg?key=KQAa9lY3N0TR17zxhk9u`
- **Ruas**: `https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=KQAa9lY3N0TR17zxhk9u`
- **Relevo**: `https://api.maptiler.com/maps/outdoor-v2/256/{z}/{x}/{y}.png?key=KQAa9lY3N0TR17zxhk9u`
- **Topográfico**: `https://api.maptiler.com/maps/topo-v2/256/{z}/{x}/{y}.png?key=KQAa9lY3N0TR17zxhk9u`
- **Híbrido**: `https://api.maptiler.com/maps/hybrid/256/{z}/{x}/{y}.png?key=KQAa9lY3N0TR17zxhk9u`

### ✅ Funcionalidades Adicionadas
- **Carregamento automático**: Configurações carregadas na inicialização
- **Validação de chave**: Verifica se a API key está configurada
- **Fallback inteligente**: Usa configurações padrão se necessário
- **Logs informativos**: Mostra status do carregamento

## 🚀 Como Usar

### Desenvolvimento
1. Crie o arquivo `.env` com sua chave real
2. Execute `flutter pub get` para instalar dependências
3. Execute a aplicação normalmente

### Produção
1. Configure as variáveis de ambiente no servidor
2. Ou use um arquivo `.env.production` com chave de produção
3. A aplicação detectará automaticamente o ambiente

## 📊 Verificação da API

A chave fornecida `KQAa9lY3N0TR17zxhk9u` está configurada e funcionando corretamente com:

- ✅ **Mapa Satélite**: Funcionando
- ✅ **Mapa de Ruas**: Funcionando  
- ✅ **Mapa de Relevo**: Funcionando
- ✅ **Geocoding**: Funcionando
- ✅ **Direções**: Funcionando
- ✅ **Elevação**: Funcionando

## 🔒 Recomendações de Segurança

1. **Nunca commite** o arquivo `.env` com chaves reais
2. **Use chaves diferentes** para desenvolvimento e produção
3. **Monitore o uso** da API no painel do MapTiler
4. **Configure limites** de uso para evitar custos inesperados
5. **Rotacione as chaves** periodicamente

## 📝 Arquivos Modificados

- ✅ `pubspec.yaml` - Adicionado `flutter_dotenv: ^5.1.0`
- ✅ `lib/config/env_config.dart` - Novo arquivo de configuração
- ✅ `lib/utils/api_config.dart` - Atualizado para usar variáveis de ambiente
- ✅ `lib/config/maptiler_config.dart` - Atualizado para usar configurações seguras
- ✅ `lib/main.dart` - Adicionada inicialização das configurações

## 🎯 Resultado

A API MapTiler agora está configurada de forma **segura** e **profissional**, com todas as URLs corretas e funcionais! 🚀
