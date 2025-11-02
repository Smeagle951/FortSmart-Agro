# Correção: Alinhamento de IDs das Culturas com Pragas e Doenças

## 🐛 Problema Identificado

As pragas, doenças e plantas daninhas **NÃO estavam aparecendo** para nenhuma cultura no módulo de Culturas da Fazenda.

### Causa Raiz

Os IDs das culturas no `CropDao` estavam **DESALINHADOS** com os IDs esperados pelo `PestDao` e `DiseaseDao`.

#### IDs ANTES (INCORRETO)

**CropDao:**
- ID 1: Soja
- ID 2: Milho
- ID 3: Algodão
- ID 4: Feijão
- ID 5: Girassol
- ID 6: Arroz
- ID 7: Sorgo
- ID 8: Gergelim
- ID 9: Cana-de-açúcar ✓
- ID 10: Tomate ✓

**PestDao/DiseaseDao:**
- ID 1: **Gergelim**
- ID 2: **Soja**
- ID 3: **Milho**
- ID 4: **Algodão**
- ID 5: **Feijão**
- ID 6: **Girassol**
- ID 7: **Arroz**
- ID 8: **Sorgo**
- ID 9: Cana-de-açúcar ✓
- ID 10: Tomate ✓

### Exemplo do Problema

- **Soja** era criada com ID 1 no CropDao
- Mas as **pragas de Soja** esperavam crop_id = 2 no PestDao
- Resultado: **Nenhuma praga aparecia para a Soja**

## ✅ Solução Implementada

### 1. Correção do CropDao

Arquivo: `lib/database/daos/crop_dao.dart`

```dart
// ANTES (ERRADO):
Crop(id: 1, name: 'Soja', ...),
Crop(id: 2, name: 'Milho', ...),
...

// DEPOIS (CORRETO):
Crop(id: 1, name: 'Gergelim', ...),
Crop(id: 2, name: 'Soja', ...),
Crop(id: 3, name: 'Milho', ...),
...
```

### 2. Atualização do CultureImportService

Arquivo: `lib/services/culture_import_service.dart`

Adicionado parâmetro `id` opcional ao método `addCrop`:

```dart
Future<int> addCrop(String name, {String? description, int? id}) async {
  final crop = db_crop.Crop(
    id: id ?? 0, // Usa ID fornecido ou 0 para auto-increment
    name: name,
    description: description ?? 'Cultura adicionada pelo usuário',
  );
  ...
}
```

### 3. Correção do FarmCropsScreen

Arquivo: `lib/screens/farm/farm_crops_screen.dart`

Agora as culturas são criadas com **IDs FIXOS** corretos:

```dart
// IDs CORRETOS alinhados com PestDao e DiseaseDao:
// 1-Gergelim, 2-Soja, 3-Milho, 4-Algodão, 5-Feijão, 6-Girassol, 7-Arroz, 8-Sorgo, 9-Cana, 10-Tomate

final gergelimId = await _importService.addCrop('Gergelim', id: 1);
final sojaId = await _importService.addCrop('Soja', id: 2);
final milhoId = await _importService.addCrop('Milho', id: 3);
final algodaoId = await _importService.addCrop('Algodão', id: 4);
final feijaoId = await _importService.addCrop('Feijão', id: 5);
final girassolId = await _importService.addCrop('Girassol', id: 6);
final arrozId = await _importService.addCrop('Arroz', id: 7);
final sorgoId = await _importService.addCrop('Sorgo', id: 8);
final canaAcucarId = await _importService.addCrop('Cana-de-açúcar', id: 9);
final tomateId = await _importService.addCrop('Tomate', id: 10);
```

### 4. Script de Migração

Arquivo: `lib/scripts/fix_crop_ids_alignment.dart`

Script criado para **limpar e recriar** todas as culturas, pragas e doenças com IDs corretos.

## 📋 IDs CORRETOS (Definitivos)

| ID | Cultura | Pragas | Doenças | Plantas Daninhas |
|----|---------|--------|---------|------------------|
| 1 | Gergelim | 8 | 3 | Várias |
| 2 | Soja | 16 | 9 | Várias |
| 3 | Milho | 12 | 7 | Várias |
| 4 | Algodão | 11 | 7 | Várias |
| 5 | Feijão | 7 | 5 | Várias |
| 6 | Girassol | 8 | 4 | Várias |
| 7 | Arroz | 8 | 4 | Várias |
| 8 | Sorgo | 8 | 4 | Várias |
| 9 | **Cana-de-açúcar** | **10** | **10** | Várias |
| 10 | **Tomate** | **10** | **10** | Várias |

## 🚀 Como Aplicar a Correção

### Para Novos Usuários

As correções já estão aplicadas. Ao criar o banco de dados pela primeira vez, os IDs estarão corretos.

### Para Usuários Existentes

Execute o script de migração:

```bash
flutter run lib/scripts/fix_crop_ids_alignment.dart
```

**⚠️ ATENÇÃO:** Este script irá:
1. Fazer backup dos dados atuais (apenas log)
2. Limpar todas as culturas, pragas, doenças e plantas daninhas
3. Recriar tudo com IDs corretos
4. Verificar a integridade dos dados

## 🔍 Como Verificar se Está Funcionando

1. Abra o módulo **Culturas da Fazenda**
2. Selecione qualquer cultura
3. Verifique se aparecem **pragas, doenças e plantas daninhas**
4. Para **Cana-de-açúcar** e **Tomate**, deve aparecer **10 pragas** e **10 doenças** cada

## 📊 Dados Implementados

### Cana-de-açúcar (ID: 9)

**Pragas (10):**
1. Broca-da-cana (Diatraea saccharalis)
2. Broca-gigante (Telchin licus)
3. Cigarrinha-da-raiz (Mahanarva fimbriolata)
4. Cigarrinha-verde (Mahanarva posticata)
5. Percevejo-castanho (Spartocera dentiventris)
6. Lagarta-do-cartucho (Spodoptera frugiperda)
7. Helicoverpa (Helicoverpa armigera)
8. Formiga-cortadeira (Atta spp.)
9. Cupim (Nasutitermes spp.)
10. Coró-das-raízes (Phyllophaga spp.)

**Doenças (10):**
1. Ferrugem-alaranjada (Puccinia kuehnii)
2. Ferrugem-marrom (Puccinia melanocephala)
3. Carvão (Sporisorium scitamineum)
4. Mosaico (Sugarcane mosaic virus)
5. Raquitismo-da-soqueira (Leifsonia xyli subsp. xyli)
6. Podridão vermelha (Colletotrichum falcatum)
7. Podridão de Fusarium (Fusarium spp.)
8. Mancha de Helminthosporium (Helminthosporium sacchari)
9. Antracnose (Colletotrichum falcatum)
10. Podridão de Glomerella (Glomerella tucumanensis)

### Tomate (ID: 10)

**Pragas (10):**
1. Traça-do-tomate (Tuta absoluta)
2. Helicoverpa (Helicoverpa armigera)
3. Lagarta-do-cartucho (Spodoptera frugiperda)
4. Pulgão-do-tomate (Macrosiphum euphorbiae)
5. Mosca-branca (Bemisia tabaci)
6. Ácaro-rajado (Tetranychus urticae)
7. Percevejo-verde (Nezara viridula)
8. Vaquinha (Diabrotica speciosa)
9. Tripes (Frankliniella schultzei)
10. Broca-pequena (Neoleucinodes elegantalis)

**Doenças (10):**
1. Murcha de Fusarium (Fusarium oxysporum f. sp. lycopersici)
2. Murcha de Verticílio (Verticillium dahliae)
3. Pinta-bacteriana (Xanthomonas spp.)
4. Mancha-bacteriana (Pseudomonas syringae pv. tomato)
5. Míldio (Phytophthora infestans)
6. Oídio (Leveillula taurica)
7. Septoriose (Septoria lycopersici)
8. Mancha de Alternaria (Alternaria solani)
9. Antracnose (Colletotrichum spp.)
10. Podridão apical (Deficiência de cálcio)

## 📝 Notas Importantes

1. **NÃO altere os IDs manualmente** - use sempre os IDs definidos nos DAOs
2. **Ao adicionar novas culturas**, certifique-se de usar IDs sequenciais começando em 11
3. **Pragas e doenças** devem sempre referenciar o `crop_id` correto
4. **Testes** devem verificar o alinhamento de IDs antes de criar dados

## 🎯 Resultado Esperado

Após a correção, **TODAS as culturas** devem exibir suas pragas, doenças e plantas daninhas corretamente no módulo de Culturas da Fazenda.

Especialmente **Cana-de-açúcar** e **Tomate**, que agora têm dados completos implementados.

---

**Data da Correção:** 01/10/2025  
**Desenvolvedor:** Assistente AI  
**Status:** ✅ Implementado e Testado

