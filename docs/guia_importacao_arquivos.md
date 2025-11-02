# Guia de Importação de Arquivos - FortSmart Agro

## 📋 Visão Geral

Este guia ajuda você a resolver problemas comuns na importação de arquivos de polígonos no FortSmart Agro.

## 🎯 Formatos Suportados

### 1. KML (Keyhole Markup Language)
- **Origem**: Google Earth, Google Maps
- **Extensão**: `.kml`
- **Uso**: Exportar polígonos do Google Earth

### 2. GeoJSON
- **Origem**: Sistemas GIS, QGIS, ArcGIS
- **Extensão**: `.geojson` ou `.json`
- **Uso**: Formato padrão para dados geográficos

## ❌ Erro: "Nenhum polígono válido encontrado"

### Possíveis Causas:

#### 1. Arquivo não contém polígonos
- **Sintoma**: Arquivo válido mas sem geometrias Polygon/MultiPolygon
- **Solução**: Verifique se o arquivo contém:
  - **KML**: Tags `<Polygon>` ou `<MultiGeometry>`
  - **GeoJSON**: Features com `"geometry.type": "Polygon"`

#### 2. Coordenadas em formato incorreto
- **Sintoma**: Arquivo com estrutura correta mas coordenadas inválidas
- **Solução**: Verifique o formato das coordenadas:
  - **KML**: `longitude,latitude,altitude` (ex: `-47.9292,-15.7801,0`)
  - **GeoJSON**: `[longitude, latitude]` (ex: `[-47.9292, -15.7801]`)

#### 3. Arquivo corrompido
- **Sintoma**: Erro ao ler o arquivo
- **Solução**: 
  - Tente abrir o arquivo em outro programa
  - Re-exporte do software original
  - Verifique se o arquivo não está vazio

## 🔧 Como Resolver

### Passo 1: Verificar o Arquivo
1. Abra o arquivo em um editor de texto
2. Verifique se contém as tags/elementos necessários
3. Confirme se as coordenadas estão no formato correto

### Passo 2: Testar com Arquivo de Exemplo
1. Use os arquivos de exemplo fornecidos pelo app
2. Compare com seu arquivo
3. Identifique as diferenças

### Passo 3: Corrigir o Arquivo
1. **KML**: Certifique-se de que há:
   ```xml
   <Placemark>
     <Polygon>
       <outerBoundaryIs>
         <LinearRing>
           <coordinates>
             -47.9292,-15.7801,0
             -47.9200,-15.7801,0
             -47.9200,-15.7700,0
             -47.9292,-15.7700,0
             -47.9292,-15.7801,0
           </coordinates>
         </LinearRing>
       </outerBoundaryIs>
     </Polygon>
   </Placemark>
   ```

2. **GeoJSON**: Certifique-se de que há:
   ```json
   {
     "type": "FeatureCollection",
     "features": [
       {
         "type": "Feature",
         "properties": {
           "name": "Nome do Talhão"
         },
         "geometry": {
           "type": "Polygon",
           "coordinates": [
             [
               [-47.9292, -15.7801],
               [-47.9200, -15.7801],
               [-47.9200, -15.7700],
               [-47.9292, -15.7700],
               [-47.9292, -15.7801]
             ]
           ]
         }
       }
     ]
   }
   ```

## 📱 Dicas do App

### Usando a Ajuda Integrada
1. Clique no botão "Ajuda" na tela de erro
2. Leia as instruções específicas
3. Baixe os arquivos de exemplo
4. Teste a importação com os exemplos

### Logs de Debug
- O app registra logs detalhados durante a importação
- Verifique os logs para identificar problemas específicos
- Use as informações de diagnóstico fornecidas

## 🛠️ Ferramentas Úteis

### Validadores Online
- **GeoJSON**: [geojson.io](https://geojson.io)
- **KML**: [Google Earth](https://earth.google.com)

### Editores Recomendados
- **QGIS**: Software GIS gratuito
- **Google Earth Pro**: Para criar/editar KML
- **Notepad++**: Editor de texto com suporte a XML/JSON

## 📞 Suporte

Se os problemas persistirem:
1. Verifique se o arquivo está nos formatos suportados
2. Teste com arquivos de exemplo
3. Consulte os logs de erro do app
4. Entre em contato com o suporte técnico

## 📝 Checklist de Verificação

- [ ] Arquivo tem extensão correta (.kml, .geojson, .json)
- [ ] Arquivo não está vazio
- [ ] Estrutura do arquivo está correta
- [ ] Coordenadas estão no formato adequado
- [ ] Polígonos têm pelo menos 3 pontos
- [ ] Arquivo não está corrompido
- [ ] Testado com arquivo de exemplo

---

**Última atualização**: Dezembro 2024
**Versão do App**: FortSmart Agro v1.0
