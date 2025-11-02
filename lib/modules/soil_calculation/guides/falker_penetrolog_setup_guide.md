# Guia de Configuração - Falker PenetroLOG

## 📱 Configuração do Penetrômetro Falker PenetroLOG

### 🔍 **Passo 1: Descobrir UUIDs do Dispositivo**

Para integrar o PenetroLOG ao app, precisamos descobrir os UUIDs específicos do dispositivo:

#### **Método 1: Usando nRF Connect (Recomendado)**
1. **Instale o app nRF Connect** no seu smartphone
2. **Ligue o PenetroLOG** e ative o Bluetooth
3. **No nRF Connect:**
   - Toque em "Scan"
   - Procure por "PenetroLOG" ou "Falker"
   - Toque no dispositivo quando aparecer
   - Anote os **Service UUIDs** e **Characteristic UUIDs**

#### **Método 2: Usando o App FortSmart**
1. **Abra o app FortSmart**
2. **Vá para:** Cálculo de Solos → Bluetooth Profissional
3. **Toque em "Escanear"**
4. **Procure por "PenetroLOG"** na lista
5. **Toque em "Conectar"** para ver os detalhes

### 📋 **Passo 2: Configurar UUIDs no App**

Após descobrir os UUIDs, atualize o arquivo `penetrometro_device_model.dart`:

```dart
// Substitua os UUIDs genéricos pelos reais do PenetroLOG
PenetrometroDeviceModel(
  id: 'falker_penetrolog',
  nome: 'PenetroLOG',
  fabricante: 'Falker',
  modelo: 'PenetroLOG',
  serviceUuid: 'UUID_REAL_DO_SERVICO', // ← Substitua aqui
  characteristicUuid: 'UUID_REAL_DA_CARACTERISTICA', // ← Substitua aqui
  protocolo: PenetrometroProtocolo.falkerPenetrolog,
  // ... resto da configuração
),
```

### 🔧 **Passo 3: Configurar Protocolo de Dados**

O PenetroLOG provavelmente envia dados no formato:
- **Resistência à Penetração** (MPa)
- **Profundidade** (cm)
- **Coordenadas GPS** (se disponível)

#### **Formato de Dados Esperado:**
```dart
// Exemplo de estrutura de dados do PenetroLOG
{
  'resistencia': 2.5,      // MPa
  'profundidade': 20.0,    // cm
  'latitude': -23.123456,  // GPS (se disponível)
  'longitude': -51.123456, // GPS (se disponível)
  'timestamp': '2024-01-15T10:30:00Z'
}
```

### 📱 **Passo 4: Testar a Conexão**

1. **Ligue o PenetroLOG**
2. **Abra o app FortSmart**
3. **Vá para:** Cálculo de Solos → Bluetooth Profissional
4. **Toque em "Escanear"**
5. **Procure por "PenetroLOG"**
6. **Toque em "Conectar"**
7. **Inicie uma medição** no PenetroLOG
8. **Verifique se os dados aparecem** no app

### 🛠️ **Passo 5: Ajustar Parsing de Dados**

Se os dados não estiverem sendo interpretados corretamente, ajuste o parsing no arquivo `penetrometro_bluetooth_advanced_service.dart`:

```dart
// Adicione um case específico para o Falker
case PenetrometroProtocolo.falkerPenetrolog:
  // Implementar parsing específico do PenetroLOG
  // baseado no formato real dos dados recebidos
  break;
```

### 📞 **Suporte Falker**

Se precisar de ajuda técnica:
- **Site:** https://www.falker.com.br
- **Email:** suporte@falker.com.br
- **Telefone:** (51) 3334-2000

### 🔍 **Informações Técnicas do PenetroLOG**

- **Profundidade máxima:** 60 cm
- **Precisão:** 0.01 MPa
- **Conectividade:** Bluetooth + GPS
- **Bateria:** Recarregável
- **Peso:** ~1.5 kg
- **Temperatura de operação:** -10°C a +50°C

### 📋 **Checklist de Configuração**

- [ ] PenetroLOG ligado e Bluetooth ativado
- [ ] UUIDs descobertos e configurados
- [ ] App escaneando e encontrando o dispositivo
- [ ] Conexão estabelecida com sucesso
- [ ] Dados sendo recebidos e interpretados
- [ ] GPS funcionando (se disponível)
- [ ] Leituras sendo salvas no banco de dados

### 🚨 **Problemas Comuns**

1. **Dispositivo não aparece no scan:**
   - Verifique se o Bluetooth está ativado
   - Reinicie o PenetroLOG
   - Verifique se está no modo de pareamento

2. **Conexão falha:**
   - Verifique se os UUIDs estão corretos
   - Tente parear manualmente primeiro
   - Verifique permissões do app

3. **Dados não são interpretados:**
   - Verifique o formato dos dados recebidos
   - Ajuste o parsing no código
   - Teste com dados de exemplo

### 🎯 **Próximos Passos**

Após configurar o PenetroLOG:
1. **Teste em campo** com medições reais
2. **Ajuste a precisão** conforme necessário
3. **Configure alertas** para valores críticos
4. **Integre com relatórios** automáticos
5. **Teste o GPS** se disponível

---

**💡 Dica:** Mantenha o PenetroLOG carregado e próximo ao smartphone durante os testes para garantir uma conexão estável.
