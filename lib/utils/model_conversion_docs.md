# Documentação de Conversão de Modelos no FortSmart Agro

## Visão Geral

O FortSmart Agro utiliza diferentes modelos para representar os mesmos conceitos em diferentes contextos da aplicação. Esta documentação explica as principais conversões de modelos e como utilizá-las corretamente.

## Principais Modelos e suas Conversões

### Crop vs AgriculturalProduct

#### Descrição
- **app_crop.Crop**: Modelo utilizado na interface do aplicativo, contendo campos formatados para exibição e interação com o usuário.
- **AgriculturalProduct**: Modelo mais abrangente usado para representar produtos agrícolas no banco de dados, incluindo culturas, insumos, defensivos, etc.

#### Diferenças Principais

| Característica | app_crop.Crop | AgriculturalProduct |
|----------------|---------------|---------------------|
| ID | `int` | `String` |
| Descrição | `description` | `description` ou `notes` |
| Cor | `colorValue` (int) | `colorValue` (String) |
| Tipo | Sempre cultura | Pode ser vários tipos (cultura, insumo, etc.) |

#### Conversão

Para converter de `AgriculturalProduct` para `app_crop.Crop`, use:

```dart
// Usando o ModelConverterUtils
app_crop.Crop convertedCrop = ModelConverterUtils.agriculturalProductToAppCrop(agriculturalProduct);

// Ou usando o método de extensão
app_crop.Crop convertedCrop = agriculturalProduct.toAppCrop();
```

Para converter de `app_crop.Crop` para `AgriculturalProduct`, use:

```dart
// Usando o ModelConverterUtils
AgriculturalProduct convertedProduct = ModelConverterUtils.appCropToAgriculturalProduct(appCrop);

// Ou usando o método de extensão
AgriculturalProduct convertedProduct = appCrop.toAgriculturalProduct();
```

## Boas Práticas

1. **Consistência**: Use `app_crop.Crop` para interfaces de usuário e `AgriculturalProduct` para operações de banco de dados.

2. **Conversão Explícita**: Sempre faça conversões explícitas entre modelos para evitar erros de tipo.

3. **Validação**: Verifique valores nulos ou inválidos durante a conversão para evitar erros em tempo de execução.

4. **Documentação**: Ao criar novos métodos de conversão, documente-os adequadamente.

5. **Testes**: Teste as conversões para garantir que todos os campos estão sendo mapeados corretamente.

## Exemplos de Uso

### Em Seletores de Culturas

```dart
// Carregando culturas do banco de dados
final List<AgriculturalProduct> productsFromDb = await dataCacheService.getCulturas();

// Convertendo para uso na interface
final List<app_crop.Crop> cropsForUI = productsFromDb.map(
  (product) => ModelConverterUtils.agriculturalProductToAppCrop(product)
).toList();
```

### Em Salvamento de Dados

```dart
// Obtendo cultura da interface
app_crop.Crop selectedCrop = ...

// Convertendo para salvar no banco de dados
AgriculturalProduct productToSave = ModelConverterUtils.appCropToAgriculturalProduct(selectedCrop);

// Salvando no banco de dados
await repository.save(productToSave);
```
