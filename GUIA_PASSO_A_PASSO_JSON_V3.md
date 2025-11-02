# 🚀 GUIA PASSO A PASSO - Evolução para FortSmart IA JSON v3.0

## 📋 ÍNDICE

1. [Preparação e Diagnóstico](#1-preparação-e-diagnóstico)
2. [Criação do Schema v3.0](#2-criação-do-schema-v30)
3. [Migração dos Dados Existentes](#3-migração-dos-dados-existentes)
4. [Enriquecimento com Novos Dados](#4-enriquecimento-com-novos-dados)
5. [Atualização do Código Dart](#5-atualização-do-código-dart)
6. [Integração com IA FortSmart](#6-integração-com-ia-fortsmart)
7. [Testes e Validação](#7-testes-e-validação)
8. [Deploy e Publicação](#8-deploy-e-publicação)

---

## 1. PREPARAÇÃO E DIAGNÓSTICO

### 📊 Semana 1: Mapear JSONs Atuais

#### Passo 1.1: Inventário Completo

```bash
# Criar script de diagnóstico
# Criar arquivo: scripts/diagnostico_json_v2.dart
```

**Criar arquivo:** `scripts/diagnostico_json_v2.dart`

```dart
import 'dart:convert';
import 'dart:io';

void main() async {
  print('📊 DIAGNÓSTICO: JSONs Organismos v2.0\n');
  
  final assetsDir = Directory('assets/data');
  final jsonFiles = assetsDir.listSync()
    .where((f) => f.path.endsWith('.json') && 
                  f.path.contains('organismos_'))
    .toList();
  
  final relatorio = <String, dynamic>{};
  
  for (var file in jsonFiles) {
    final content = await File(file.path).readAsString();
    final data = json.decode(content);
    
    final cultura = data['cultura'] ?? 'Desconhecida';
    final organismos = data['organismos'] as List;
    
    relatorio[cultura] = {
      'total_organismos': organismos.length,
      'pragas': organismos.where((o) => o['categoria'] == 'Praga').length,
      'doencas': organismos.where((o) => o['categoria'] == 'Doença').length,
      'daninhas': organismos.where((o) => o['categoria'] == 'Planta Daninha').length,
      'versao': data['versao'] ?? 'N/A',
      'data_atualizacao': data['data_atualizacao'] ?? 'N/A',
    };
    
    print('✅ $cultura: ${organismos.length} organismos');
  }
  
  // Salvar relatório
  await File('relatorio_diagnostico_v2.json')
    .writeAsString(json.encode(relatorio, indent: 2));
  
  print('\n✅ Relatório salvo em: relatorio_diagnostico_v2.json');
}
```

**Executar:**
```bash
dart scripts/diagnostico_json_v2.dart
```

#### Passo 1.2: Identificar Campos Faltantes

**Criar arquivo:** `scripts/validar_campos_v2.dart`

```dart
import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 VALIDAÇÃO: Campos nos JSONs v2.0\n');
  
  final camposRequeridos = [
    'id', 'nome', 'nome_cientifico', 'categoria',
    'sintomas', 'dano_economico', 'partes_afetadas',
    'fenologia', 'nivel_acao', 'manejo_quimico',
    'manejo_biologico', 'manejo_cultural'
  ];
  
  final camposNovos = [
    'caracteristicas_visuais',
    'condicoes_climaticas',
    'ciclo_vida',
    'rotacao_resistencia',
    'distribuicao_geografica',
    'economia_agronomica',
    'controle_biologico_detalhado',
    'diagnostico_diferencial',
    'tendencias_sazonais',
    'features_ia'
  ];
  
  final assetsDir = Directory('assets/data');
  final jsonFiles = assetsDir.listSync()
    .where((f) => f.path.endsWith('.json') && 
                  f.path.contains('organismos_'))
    .toList();
  
  final relatorio = <String, dynamic>{};
  
  for (var file in jsonFiles) {
    final content = await File(file.path).readAsString();
    final data = json.decode(content);
    final cultura = data['cultura'] ?? 'Desconhecida';
    final organismos = data['organismos'] as List;
    
    final stats = {
      'campos_presentes': <String, int>{},
      'campos_faltantes': <String, int>{},
    };
    
    for (var org in organismos) {
      for (var campo in camposRequeridos) {
        if (org.containsKey(campo)) {
          stats['campos_presentes']![campo] = 
            (stats['campos_presentes']![campo] ?? 0) + 1;
        } else {
          stats['campos_faltantes']![campo] = 
            (stats['campos_faltantes']![campo] ?? 0) + 1;
        }
      }
      
      // Verificar novos campos
      for (var campo in camposNovos) {
        if (!org.containsKey(campo)) {
          stats['campos_faltantes']![campo] = 
            (stats['campos_faltantes']![campo] ?? 0) + 1;
        }
      }
    }
    
    relatorio[cultura] = stats;
  }
  
  await File('relatorio_validacao_campos.json')
    .writeAsString(json.encode(relatorio, indent: 2));
  
  print('✅ Relatório de validação salvo');
}
```

#### Passo 1.3: Criar Backup

```bash
# Criar backup completo
mkdir -p backup/v2.0
cp -r assets/data/*.json backup/v2.0/

# Criar tag git
git tag v2.0-backup
git add backup/
git commit -m "Backup JSONs v2.0 antes da migração"
```

---

## 2. CRIAÇÃO DO SCHEMA V3.0

### 📐 Semana 2-3: Estrutura Nova Padronizada

#### Passo 2.1: Criar Schema JSON

**Criar arquivo:** `assets/schemas/organismo_schema_v3.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Organismo Agronômico FortSmart v3.0",
  "type": "object",
  "required": [
    "id",
    "nome",
    "nome_cientifico",
    "categoria",
    "culturas_afetadas"
  ],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^[a-z]+_[a-z_]+$",
      "description": "ID único no formato cultura_organismo"
    },
    "nome": {
      "type": "string",
      "minLength": 3,
      "description": "Nome comum do organismo"
    },
    "nome_cientifico": {
      "type": "string",
      "description": "Nome científico (binomial)"
    },
    "categoria": {
      "type": "string",
      "enum": ["Praga", "Doença", "Planta Daninha"],
      "description": "Categoria do organismo"
    },
    "culturas_afetadas": {
      "type": "array",
      "items": {"type": "string"},
      "minItems": 1,
      "description": "Lista de culturas afetadas"
    },
    "caracteristicas_visuais": {
      "type": "object",
      "properties": {
        "cores_predominantes": {"type": "array", "items": {"type": "string"}},
        "padroes": {"type": "array", "items": {"type": "string"}},
        "tamanho_medio_mm": {
          "type": "object",
          "properties": {
            "larva": {"type": "number"},
            "adulto": {"type": "number"}
          }
        }
      }
    },
    "condicoes_climaticas": {
      "type": "object",
      "properties": {
        "temperatura_min": {"type": "number"},
        "temperatura_max": {"type": "number"},
        "umidade_min": {"type": "number"},
        "umidade_max": {"type": "number"}
      }
    },
    "ciclo_vida": {
      "type": "object",
      "properties": {
        "ovos_dias": {"type": "number"},
        "larva_dias": {"type": "number"},
        "pupa_dias": {"type": "number"},
        "adulto_dias": {"type": "number"},
        "geracoes_por_ano": {"type": "number"}
      }
    },
    "rotacao_resistencia": {
      "type": "object",
      "properties": {
        "grupos_irac": {"type": "array", "items": {"type": "string"}},
        "estrategias": {"type": "array", "items": {"type": "string"}},
        "intervalo_minimo_dias": {"type": "number"}
      }
    },
    "economia_agronomica": {
      "type": "object",
      "properties": {
        "custo_nao_controle_por_ha": {"type": "number"},
        "custo_controle_por_ha": {"type": "number"},
        "roi_medio": {"type": "number"}
      }
    },
    "features_ia": {
      "type": "object",
      "properties": {
        "keywords_comportamentais": {"type": "array", "items": {"type": "string"}},
        "marcadores_visuais": {"type": "array", "items": {"type": "string"}}
      }
    }
  }
}
```

#### Passo 2.2: Criar Estrutura de Diretórios

```bash
mkdir -p assets/data/organismos/exemplos
mkdir -p assets/schemas
mkdir -p lib/models/v3
mkdir -p lib/services/organismos_v3
```

#### Passo 2.3: Criar JSON de Exemplo

**Criar arquivo:** `assets/data/organismos/exemplos/soja_lagarta_falsamedideira_v3.json`

```json
{
  "id": "soja_lagarta_falsamedideira",
  "nome": "Lagarta falsa-medideira",
  "nome_cientifico": "Chrysodeixis includens",
  "categoria": "Praga",
  "culturas_afetadas": ["Soja"],
  "versao": "3.0",
  "data_criacao": "2025-10-28",
  "data_atualizacao": "2025-10-28",
  
  "caracteristicas_visuais": {
    "cores_predominantes": ["verde", "marrom"],
    "padroes": ["listra lateral clara", "movimento tipo medidor"],
    "tamanho_medio_mm": {
      "larva": 25,
      "adulto": 15
    },
    "formato_corpo": "cilindrico",
    "textura": "lisa",
    "marcadores_visualizacao": {
      "ovos": "brancos_arredondados_0.5mm_folhas",
      "lagartas_pequenas": "verde_claro_1_3mm_raspagem",
      "lagartas_medias": "verde_escuro_listra_branca_10_15mm",
      "lagartas_grandes": "verde_marrom_25mm_desfolha_intensa"
    }
  },
  
  "sintomas": [
    "Raspagem de folhas sem perfuração total",
    "Desfolha intensa em infestações severas",
    "Redução da área fotossintética"
  ],
  
  "dano_economico": "Pode causar perdas de até 40% na produtividade devido à desfolha severa, especialmente nos estágios V4-V6 e R3-R5",
  
  "partes_afetadas": ["Folhas"],
  
  "fenologia": ["V1", "V2", "V3", "V4", "V5", "V6", "R1", "R2", "R3", "R4", "R5"],
  
  "nivel_acao": "2 lagartas/m² ou desfolha ≥ 30% no estágio vegetativo",
  
  "condicoes_climaticas": {
    "temperatura_min": 20,
    "temperatura_max": 32,
    "umidade_min": 60,
    "umidade_max": 90,
    "previsao_risco": {
      "alta_probabilidade": {
        "temperatura": "22-28°C durante 5 dias consecutivos",
        "umidade": ">70% por 3 dias",
        "precipitacao": "chuva leve a moderada"
      }
    }
  },
  
  "ciclo_vida": {
    "ovos_dias": 3,
    "larva_dias": 14,
    "pupa_dias": 7,
    "adulto_dias": 10,
    "geracoes_por_ano": 6,
    "duracao_total_dias": 34
  },
  
  "rotacao_resistencia": {
    "grupos_irac": ["18", "28"],
    "estrategias": [
      "Alternar modos de ação IRAC",
      "Uso máximo 2x por safra do mesmo grupo",
      "Intervalo mínimo de 14 dias"
    ],
    "intervalo_minimo_dias": 14,
    "grupos_quimicos": [
      {
        "grupo": "IRAC 18",
        "mecanismo": "modulador_canal_ryanodina",
        "n_max_aplicacoes_ano": 3
      },
      {
        "grupo": "IRAC 28",
        "mecanismo": "ativador_canal_cloreto",
        "n_max_aplicacoes_ano": 2
      }
    ]
  },
  
  "distribuicao_geografica": {
    "regioes_brasileiras": {
      "centro_oeste": {
        "presenca": "muito_alta",
        "epoca_pico": "novembro-marco",
        "observacoes": "Maior dano econômico do país"
      },
      "sudeste": {
        "presenca": "alta",
        "epoca_pico": "dezembro-abril"
      }
    },
    "municipios_alto_risco": [
      "Sorriso-MT",
      "Lucas do Rio Verde-MT",
      "Querência-MT"
    ]
  },
  
  "economia_agronomica": {
    "custo_nao_controle_por_ha": 180,
    "custo_controle_por_ha": 60,
    "roi_medio": 3.0,
    "preco_referencia_soja_kg": 0.15,
    "perda_kg_ha_nivel_medio": 1200
  },
  
  "controle_biologico_detalhado": {
    "predadores": [
      {
        "nome": "Chrysoperla sp.",
        "tipo": "predador",
        "eficacia": "60-70%",
        "epoca": "inicio_infestacao"
      }
    ],
    "parasitoides": [
      {
        "nome": "Trichogramma pretiosum",
        "tipo": "parasitoide",
        "alvo": "ovos",
        "eficacia": "70-90%",
        "liberacao": "50.000-100.000 vespinhas/ha",
        "custo": "R$ 25-40/ha"
      }
    ],
    "entomopatogenos": [
      {
        "nome": "Bacillus thuringiensis",
        "formulacao": "WP",
        "dose": "0,5-1,0 kg/ha",
        "eficacia": "60-80%"
      }
    ]
  },
  
  "diagnostico_diferencial": {
    "confundidores": [
      {
        "organismo": "Anticarsia gemmatalis",
        "diferenciacao": "Lagarta-falsamedideira tem movimento tipo medidor e listra lateral branca característica"
      }
    ],
    "sintomas_chave": [
      "Raspagem de folhas sem perfuração total",
      "Listra lateral branca característica",
      "Movimento tipo medidor"
    ],
    "monitoramento_facil": [
      {
        "metodo": "pano_batida",
        "frequencia": "2x_semana",
        "horario": "inicio_manha"
      }
    ]
  },
  
  "tendencias_sazonais": {
    "pico_meses": ["Janeiro", "Fevereiro"],
    "correlacao_elnino": "aumento_20_30_percent",
    "graus_dia_media": 450,
    "previsao_45_dias": {
      "metodo": "graus_dia_acumulados",
      "base": "temperatura_media_22c"
    }
  },
  
  "features_ia": {
    "keywords_comportamentais": [
      "desfolha_intensa",
      "raspagem_folhas",
      "noctuideo",
      "movimento_medidor"
    ],
    "marcadores_visuais": [
      "listra_branca_lateral",
      "movimento_medidor_caracteristico",
      "verde_escuro_marrom"
    ],
    "contexto_sintomas": {
      "sempre_presente": ["desfolha", "raspagem"],
      "frequentemente_presente": ["reducao_area_foliar"]
    }
  },
  
  "manejo_quimico": [
    "Clorantraniliprole (IRAC 28) - 0,15-0,25 L/ha",
    "Espinetoram (IRAC 5) - 0,08-0,12 L/ha"
  ],
  
  "manejo_biologico": [
    "Trichogramma pretiosum",
    "Bacillus thuringiensis",
    "Chrysoperla sp."
  ],
  
  "manejo_cultural": [
    "Rotação de culturas",
    "Plantio na época recomendada",
    "Destruição de restos culturais"
  ]
}
```

---

## 3. MIGRAÇÃO DOS DADOS EXISTENTES

### 🔄 Semana 2-3: Script de Conversão

#### Passo 3.1: Criar Script Python de Migração

**Criar arquivo:** `scripts/migrar_json_v2_para_v3.py`

```python
#!/usr/bin/env python3
"""
Script de migração: JSON v2.0 → v3.0
Migra dados existentes mantendo compatibilidade
"""

import json
import os
from pathlib import Path
from typing import Dict, Any, List

def migrar_organismo(org_v2: Dict[str, Any], cultura: str) -> Dict[str, Any]:
    """
    Migra um organismo de v2.0 para v3.0
    Mantém dados existentes e adiciona campos novos com valores padrão
    """
    
    org_v3 = {
        # Campos obrigatórios (já existentes)
        "id": org_v2.get("id", ""),
        "nome": org_v2.get("nome", ""),
        "nome_cientifico": org_v2.get("nome_cientifico", ""),
        "categoria": org_v2.get("categoria", ""),
        "culturas_afetadas": [cultura],
        "versao": "3.0",
        
        # Dados existentes (mantém)
        "sintomas": org_v2.get("sintomas", []),
        "dano_economico": org_v2.get("dano_economico", ""),
        "partes_afetadas": org_v2.get("partes_afetadas", []),
        "fenologia": org_v2.get("fenologia", []),
        "nivel_acao": org_v2.get("nivel_acao", ""),
        "manejo_quimico": org_v2.get("manejo_quimico", []),
        "manejo_biologico": org_v2.get("manejo_biologico", []),
        "manejo_cultural": org_v2.get("manejo_cultural", []),
    }
    
    # NOVOS CAMPOS v3.0 (extrair do existente ou padrão)
    
    # 1. Características visuais (extrair de "fases" se existir)
    if "fases" in org_v2 and len(org_v2["fases"]) > 0:
        fase_larva = next((f for f in org_v2["fases"] if "larva" in f.get("fase", "").lower()), None)
        fase_adulto = next((f for f in org_v2["fases"] if "adulto" in f.get("fase", "").lower())), None)
        
        org_v3["caracteristicas_visuais"] = {
            "cores_predominantes": _extrair_cores(org_v2),
            "padroes": _extrair_padroes(org_v2),
            "tamanho_medio_mm": {
                "larva": _parse_tamanho(fase_larva.get("tamanho_mm") if fase_larva else None),
                "adulto": _parse_tamanho(fase_adulto.get("tamanho_mm") if fase_adulto else None)
            }
        }
    else:
        org_v3["caracteristicas_visuais"] = {
            "cores_predominantes": [],
            "padroes": [],
            "tamanho_medio_mm": {}
        }
    
    # 2. Condições climáticas (extrair se existir)
    if "condicoes_favoraveis" in org_v2:
        cond = org_v2["condicoes_favoraveis"]
        org_v3["condicoes_climaticas"] = {
            "temperatura_min": _parse_temperatura(cond.get("temperatura", ""), "min"),
            "temperatura_max": _parse_temperatura(cond.get("temperatura", ""), "max"),
            "umidade_min": _parse_umidade(cond.get("umidade", ""), "min"),
            "umidade_max": _parse_umidade(cond.get("umidade", ""), "max")
        }
    else:
        org_v3["condicoes_climaticas"] = {
            "temperatura_min": 20,
            "temperatura_max": 32,
            "umidade_min": 60,
            "umidade_max": 90
        }
    
    # 3. Ciclo de vida (extrair de "fases" se existir)
    if "fases" in org_v2:
        cic = org_v2["fases"]
        org_v3["ciclo_vida"] = {
            "ovos_dias": _soma_duracao(cic, "ovo"),
            "larva_dias": _soma_duracao(cic, "larva"),
            "pupa_dias": _soma_duracao(cic, "pupa"),
            "adulto_dias": _soma_duracao(cic, "adulto"),
            "geracoes_por_ano": 6  # Valor padrão
        }
    else:
        org_v3["ciclo_vida"] = {
            "geracoes_por_ano": 6
        }
    
    # 4. Rotação resistência (extrair de doses_defensivos)
    if "doses_defensivos" in org_v2:
        grupos = _extrair_grupos_irac(org_v2["doses_defensivos"])
        org_v3["rotacao_resistencia"] = {
            "grupos_irac": grupos,
            "estrategias": ["Alternar modos de ação IRAC", "Uso máximo 2x por safra"],
            "intervalo_minimo_dias": 14
        }
    else:
        org_v3["rotacao_resistencia"] = {
            "grupos_irac": [],
            "estrategias": [],
            "intervalo_minimo_dias": 14
        }
    
    # 5. Economia agronômica (calcular se tiver dados de severidade)
    if "severidade" in org_v2:
        econ = _calcular_economia(org_v2["severidade"])
        org_v3["economia_agronomica"] = econ
    else:
        org_v3["economia_agronomica"] = {
            "custo_nao_controle_por_ha": 150,
            "custo_controle_por_ha": 50,
            "roi_medio": 3.0
        }
    
    # 6. Features IA (gerar de sintomas e comportamentos)
    org_v3["features_ia"] = {
        "keywords_comportamentais": _gerar_keywords(org_v2),
        "marcadores_visuais": _gerar_marcadores(org_v2)
    }
    
    return org_v3


def _extrair_cores(org: Dict) -> List[str]:
    """Extrai cores predominantes dos dados existentes"""
    cores = []
    if "caracteristicas" in org:
        for fase in org.get("fases", []):
            chars = fase.get("caracteristicas", "")
            if "verde" in chars.lower():
                cores.append("verde")
            if "marrom" in chars.lower():
                cores.append("marrom")
    return list(set(cores)) or ["verde", "marrom"]


def _parse_tamanho(tamanho_str: str) -> float:
    """Converte string de tamanho para número"""
    if not tamanho_str:
        return 0.0
    # Ex: "1-3" -> 2.0
    try:
        parts = str(tamanho_str).split("-")
        if len(parts) == 2:
            return (float(parts[0]) + float(parts[1])) / 2
        return float(parts[0])
    except:
        return 0.0


def main():
    """Função principal de migração"""
    input_dir = Path("assets/data")
    output_dir = Path("assets/data/organismos")
    output_dir.mkdir(exist_ok=True)
    
    json_files = list(input_dir.glob("organismos_*.json"))
    
    print(f"📦 Encontrados {len(json_files)} arquivos para migrar\n")
    
    for file_path in json_files:
        print(f"🔄 Migrando: {file_path.name}")
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data_v2 = json.load(f)
        
        cultura = data_v2.get("cultura", "Desconhecida")
        organismos_v2 = data_v2.get("organismos", [])
        
        organismos_v3 = [
            migrar_organismo(org, cultura) 
            for org in organismos_v2
        ]
        
        # Salvar por categoria
        for categoria in ["Praga", "Doença", "Planta Daninha"]:
            orgs_cat = [o for o in organismos_v3 if o["categoria"] == categoria]
            if orgs_cat:
                output_file = output_dir / f"{cultura.lower()}_{categoria.lower().replace(' ', '_')}_v3.json"
                
                data_output = {
                    "cultura": cultura,
                    "categoria": categoria,
                    "versao": "3.0",
                    "organismos": orgs_cat
                }
                
                with open(output_file, 'w', encoding='utf-8') as f:
                    json.dump(data_output, f, indent=2, ensure_ascii=False)
                
                print(f"  ✅ {len(orgs_cat)} {categoria.lower()}s migrados")
    
    print("\n✅ Migração concluída!")


if __name__ == "__main__":
    main()
```

#### Passo 3.2: Executar Migração

```bash
# Instalar dependências
pip install -r requirements.txt

# Executar migração
python scripts/migrar_json_v2_para_v3.py

# Verificar resultado
ls -la assets/data/organismos/
```

---

## 4. ENRIQUECIMENTO COM NOVOS DADOS

### 📊 Semana 4: Inserir Dados Técnicos

#### Passo 4.1: Script de Enriquecimento

**Criar arquivo:** `scripts/enriquecer_json_v3.py`

```python
#!/usr/bin/env python3
"""
Script de enriquecimento: Adiciona dados técnicos aos JSONs v3.0
Usa dados públicos de Embrapa, IRAC, etc.
"""

import json
from pathlib import Path

# Base de dados IRAC (público)
IRAC_DATA = {
    "IRAC 5": {"mecanismo": "modulador_receptor_nicotinico", "nome": "Spinosynas"},
    "IRAC 18": {"mecanismo": "modulador_canal_ryanodina", "nome": "Diamidas"},
    "IRAC 28": {"mecanismo": "ativador_canal_cloreto", "nome": "Diamidas"}
}

# Distribuição geográfica (zoneamento público)
DISTRIBUICAO_BR = {
    "Soja": {
        "centro_oeste": "muito_alta",
        "sudeste": "alta",
        "sul": "media"
    },
    # ... outras culturas
}

def enriquecer_rotacao_resistencia(org: dict, doses: dict) -> dict:
    """Enriquece dados de rotação de resistência"""
    grupos = []
    estrategias = []
    
    for produto, dados in doses.items():
        # Detectar grupo IRAC
        grupo = detectar_grupo_irac(produto)
        if grupo:
            grupos.append(grupo)
    
    if grupos:
        estrategias.append(f"Alternar entre grupos: {', '.join(grupos)}")
        estrategias.append("Máximo 2 aplicações do mesmo grupo por safra")
    
    return {
        "grupos_irac": list(set(grupos)),
        "estrategias": estrategias,
        "intervalo_minimo_dias": 14
    }


def enriquecer_distribuicao(org: dict, cultura: str) -> dict:
    """Enriquece dados de distribuição geográfica"""
    distribuicao = DISTRIBUICAO_BR.get(cultura, {})
    
    return {
        "regioes_brasileiras": {
            regiao: {
                "presenca": nivel,
                "epoca_pico": "novembro-marco"  # Padrão
            }
            for regiao, nivel in distribuicao.items()
        }
    }


def main():
    """Enriquece todos os JSONs v3.0"""
    organismos_dir = Path("assets/data/organismos")
    
    for file_path in organismos_dir.glob("*_v3.json"):
        print(f"🔧 Enriquecendo: {file_path.name}")
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        cultura = data.get("cultura", "")
        
        for org in data.get("organismos", []):
            # Enriquecer rotação se tiver doses
            if "doses_defensivos" in org:
                org["rotacao_resistencia"] = enriquecer_rotacao_resistencia(
                    org, org["doses_defensivos"]
                )
            
            # Enriquecer distribuição
            org["distribuicao_geografica"] = enriquecer_distribuicao(org, cultura)
        
        # Salvar
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"  ✅ Enriquecido")
    
    print("\n✅ Enriquecimento concluído!")


if __name__ == "__main__":
    main()
```

---

## 5. ATUALIZAÇÃO DO CÓDIGO DART

### 💻 Semana 5: Modelo e Serviços Dart

#### Passo 5.1: Criar Modelo v3.0

**Criar arquivo:** `lib/models/v3/organismo_v3_model.dart`

```dart
class OrganismoV3 {
  final String id;
  final String nome;
  final String nomeCientifico;
  final String categoria;
  final List<String> culturasAfetadas;
  
  // Campos novos v3.0
  final CaracteristicasVisuais? caracteristicasVisuais;
  final CondicoesClimaticas? condicoesClimaticas;
  final CicloVida? cicloVida;
  final RotacaoResistencia? rotacaoResistencia;
  final DistribuicaoGeografica? distribuicaoGeografica;
  final EconomiaAgronomica? economiaAgronomica;
  final FeaturesIA? featuresIA;
  
  OrganismoV3({
    required this.id,
    required this.nome,
    required this.nomeCientifico,
    required this.categoria,
    required this.culturasAfetadas,
    this.caracteristicasVisuais,
    this.condicoesClimaticas,
    this.cicloVida,
    this.rotacaoResistencia,
    this.distribuicaoGeografica,
    this.economiaAgronomica,
    this.featuresIA,
  });
  
  factory OrganismoV3.fromJson(Map<String, dynamic> json) {
    return OrganismoV3(
      id: json['id'] as String,
      nome: json['nome'] as String,
      nomeCientifico: json['nome_cientifico'] as String,
      categoria: json['categoria'] as String,
      culturasAfetadas: List<String>.from(json['culturas_afetadas'] ?? []),
      caracteristicasVisuais: json['caracteristicas_visuais'] != null
          ? CaracteristicasVisuais.fromJson(json['caracteristicas_visuais'])
          : null,
      condicoesClimaticas: json['condicoes_climaticas'] != null
          ? CondicoesClimaticas.fromJson(json['condicoes_climaticas'])
          : null,
      cicloVida: json['ciclo_vida'] != null
          ? CicloVida.fromJson(json['ciclo_vida'])
          : null,
      rotacaoResistencia: json['rotacao_resistencia'] != null
          ? RotacaoResistencia.fromJson(json['rotacao_resistencia'])
          : null,
      distribuicaoGeografica: json['distribuicao_geografica'] != null
          ? DistribuicaoGeografica.fromJson(json['distribuicao_geografica'])
          : null,
      economiaAgronomica: json['economia_agronomica'] != null
          ? EconomiaAgronomica.fromJson(json['economia_agronomica'])
          : null,
      featuresIA: json['features_ia'] != null
          ? FeaturesIA.fromJson(json['features_ia'])
          : null,
    );
  }
}

class CaracteristicasVisuais {
  final List<String> coresPredominantes;
  final List<String> padroes;
  final Map<String, double>? tamanhoMedioMm;
  
  CaracteristicasVisuais({
    required this.coresPredominantes,
    required this.padroes,
    this.tamanhoMedioMm,
  });
  
  factory CaracteristicasVisuais.fromJson(Map<String, dynamic> json) {
    return CaracteristicasVisuais(
      coresPredominantes: List<String>.from(json['cores_predominantes'] ?? []),
      padroes: List<String>.from(json['padroes'] ?? []),
      tamanhoMedioMm: json['tamanho_medio_mm'] != null
          ? Map<String, double>.from(
              (json['tamanho_medio_mm'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble())
              )
            )
          : null,
    );
  }
}

class CondicoesClimaticas {
  final double? temperaturaMin;
  final double? temperaturaMax;
  final double? umidadeMin;
  final double? umidadeMax;
  
  CondicoesClimaticas({
    this.temperaturaMin,
    this.temperaturaMax,
    this.umidadeMin,
    this.umidadeMax,
  });
  
  factory CondicoesClimaticas.fromJson(Map<String, dynamic> json) {
    return CondicoesClimaticas(
      temperaturaMin: (json['temperatura_min'] as num?)?.toDouble(),
      temperaturaMax: (json['temperatura_max'] as num?)?.toDouble(),
      umidadeMin: (json['umidade_min'] as num?)?.toDouble(),
      umidadeMax: (json['umidade_max'] as num?)?.toDouble(),
    );
  }
  
  /// Calcula risco climático (0.0 a 1.0)
  double calcularRisco(double temperatura, double umidade) {
    double risco = 0.0;
    
    if (temperaturaMin != null && temperaturaMax != null) {
      if (temperatura >= temperaturaMin! && temperatura <= temperaturaMax!) {
        risco += 0.4;
      }
    }
    
    if (umidadeMin != null && umidadeMax != null) {
      if (umidade >= umidadeMin! && umidade <= umidadeMax!) {
        risco += 0.4;
      }
    }
    
    return risco.clamp(0.0, 1.0);
  }
}

class CicloVida {
  final int? ovosDias;
  final int? larvaDias;
  final int? pupaDias;
  final int? adultoDias;
  final int? geracoesPorAno;
  
  CicloVida({
    this.ovosDias,
    this.larvaDias,
    this.pupaDias,
    this.adultoDias,
    this.geracoesPorAno,
  });
  
  factory CicloVida.fromJson(Map<String, dynamic> json) {
    return CicloVida(
      ovosDias: json['ovos_dias'] as int?,
      larvaDias: json['larva_dias'] as int?,
      pupaDias: json['pupa_dias'] as int?,
      adultoDias: json['adulto_dias'] as int?,
      geracoesPorAno: json['geracoes_por_ano'] as int?,
    );
  }
  
  int? get duracaoTotalDias {
    if (ovosDias != null && larvaDias != null && pupaDias != null && adultoDias != null) {
      return ovosDias! + larvaDias! + pupaDias! + adultoDias!;
    }
    return null;
  }
}

class RotacaoResistencia {
  final List<String> gruposIrac;
  final List<String> estrategias;
  final int? intervaloMinimoDias;
  
  RotacaoResistencia({
    required this.gruposIrac,
    required this.estrategias,
    this.intervaloMinimoDias,
  });
  
  factory RotacaoResistencia.fromJson(Map<String, dynamic> json) {
    return RotacaoResistencia(
      gruposIrac: List<String>.from(json['grupos_irac'] ?? []),
      estrategias: List<String>.from(json['estrategias'] ?? []),
      intervaloMinimoDias: json['intervalo_minimo_dias'] as int?,
    );
  }
}

class DistribuicaoGeografica {
  final Map<String, dynamic>? regioesBrasileiras;
  final List<String>? municipiosAltoRisco;
  
  DistribuicaoGeografica({
    this.regioesBrasileiras,
    this.municipiosAltoRisco,
  });
  
  factory DistribuicaoGeografica.fromJson(Map<String, dynamic> json) {
    return DistribuicaoGeografica(
      regioesBrasileiras: json['regioes_brasileiras'] as Map<String, dynamic>?,
      municipiosAltoRisco: json['municipios_alto_risco'] != null
          ? List<String>.from(json['municipios_alto_risco'])
          : null,
    );
  }
}

class EconomiaAgronomica {
  final double? custoNaoControlePorHa;
  final double? custoControlePorHa;
  final double? roiMedio;
  
  EconomiaAgronomica({
    this.custoNaoControlePorHa,
    this.custoControlePorHa,
    this.roiMedio,
  });
  
  factory EconomiaAgronomica.fromJson(Map<String, dynamic> json) {
    return EconomiaAgronomica(
      custoNaoControlePorHa: (json['custo_nao_controle_por_ha'] as num?)?.toDouble(),
      custoControlePorHa: (json['custo_controle_por_ha'] as num?)?.toDouble(),
      roiMedio: (json['roi_medio'] as num?)?.toDouble(),
    );
  }
  
  double? get economiaPotencial {
    if (custoNaoControlePorHa != null && custoControlePorHa != null) {
      return custoNaoControlePorHa! - custoControlePorHa!;
    }
    return null;
  }
}

class FeaturesIA {
  final List<String> keywordsComportamentais;
  final List<String> marcadoresVisuais;
  
  FeaturesIA({
    required this.keywordsComportamentais,
    required this.marcadoresVisuais,
  });
  
  factory FeaturesIA.fromJson(Map<String, dynamic> json) {
    return FeaturesIA(
      keywordsComportamentais: List<String>.from(
          json['keywords_comportamentais'] ?? []),
      marcadoresVisuais: List<String>.from(
          json['marcadores_visuais'] ?? []),
    );
  }
}
```

---

## 6. INTEGRAÇÃO COM IA FORTSMART

### 🤖 Semana 5-6: Serviços de IA

#### Passo 6.1: Criar Serviço de Risco

**Criar arquivo:** `lib/services/organismos_v3/risco_agronomico_service.dart`

```dart
import '../models/v3/organismo_v3_model.dart';
import 'package:intl/intl.dart';

/// Serviço para cálculo de risco agronômico usando dados v3.0
class RiscoAgronomicoService {
  
  /// Calcula risco total de infestação
  double calcularRiscoTotal({
    required OrganismoV3 organismo,
    required double temperatura,
    required double umidade,
    String? regiao,
    DateTime? data,
  }) {
    double risco = 0.0;
    
    // 1. Risco climático (40%)
    if (organismo.condicoesClimaticas != null) {
      final riscoClima = organismo.condicoesClimaticas!
          .calcularRisco(temperatura, umidade);
      risco += riscoClima * 0.4;
    }
    
    // 2. Risco sazonal (20%)
    if (organismo.tendenciasSazonais?.picoMeses != null && data != null) {
      final mesAtual = DateFormat('MMMM', 'pt_BR').format(data);
      if (organismo.tendenciasSazonais!.picoMeses!
          .contains(mesAtual)) {
        risco += 0.2;
      }
    }
    
    // 3. Risco regional (20%)
    if (regiao != null && organismo.distribuicaoGeografica != null) {
      final regioes = organismo.distribuicaoGeografica!.regioesBrasileiras;
      if (regioes != null && regioes.containsKey(regiao)) {
        final nivel = regioes[regiao]['presenca'] as String?;
        if (nivel == 'muito_alta') risco += 0.2;
        else if (nivel == 'alta') risco += 0.15;
        else if (nivel == 'media') risco += 0.1;
      }
    }
    
    // 4. Risco comportamental (20%)
    if (organismo.featuresIA?.keywordsComportamentais != null) {
      // Se tem keywords de alta voracidade, aumenta risco
      final keywords = organismo.featuresIA!.keywordsComportamentais;
      if (keywords.contains('desfolha_intensa')) {
        risco += 0.1;
      }
      if (keywords.contains('noctuideo')) {
        risco += 0.1;
      }
    }
    
    return risco.clamp(0.0, 1.0);
  }
  
  /// Gera alerta de risco
  String gerarAlerta(double risco) {
    if (risco >= 0.7) {
      return '🔴 ALTO RISCO - Monitoramento diário recomendado';
    } else if (risco >= 0.4) {
      return '🟠 RISCO MÉDIO - Monitoramento 2x por semana';
    } else if (risco >= 0.2) {
      return '🟡 RISCO BAIXO - Monitoramento semanal';
    } else {
      return '🟢 RISCO MUITO BAIXO - Monitoramento a cada 15 dias';
    }
  }
  
  /// Calcula ROI do controle
  double calcularROI({
    required OrganismoV3 organismo,
    required double nivelInfestacao, // 0 a 1
  }) {
    if (organismo.economiaAgronomica == null) {
      return 0.0;
    }
    
    final econ = organismo.economiaAgronomica!;
    final custoNaoControle = econ.custoNaoControlePorHa ?? 0.0;
    final custoControle = econ.custoControlePorHa ?? 0.0;
    
    // Ajustar por nível de infestação
    final perdaReal = custoNaoControle * nivelInfestacao;
    
    if (custoControle > 0) {
      return perdaReal / custoControle;
    }
    
    return 0.0;
  }
}
```

---

## 7. TESTES E VALIDAÇÃO

### ✅ Semana 7: Testes Completos

#### Passo 7.1: Testes Unitários

**Criar arquivo:** `test/services/risco_agronomico_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fortsmart_agro/services/organismos_v3/risco_agronomico_service.dart';
import 'package:fortsmart_agro/models/v3/organismo_v3_model.dart';

void main() {
  group('RiscoAgronomicoService', () {
    late RiscoAgronomicoService service;
    late OrganismoV3 organismo;
    
    setUp(() {
      service = RiscoAgronomicoService();
      organismo = OrganismoV3(
        id: 'test_1',
        nome: 'Lagarta-da-soja',
        nomeCientifico: 'Anticarsia gemmatalis',
        categoria: 'Praga',
        culturasAfetadas: ['Soja'],
        condicoesClimaticas: CondicoesClimaticas(
          temperaturaMin: 20,
          temperaturaMax: 28,
          umidadeMin: 60,
          umidadeMax: 80,
        ),
      );
    });
    
    test('Calcula risco climático corretamente', () {
      final risco = service.calcularRiscoTotal(
        organismo: organismo,
        temperatura: 24, // Ótima
        umidade: 70, // Ótima
      );
      
      expect(risco, greaterThan(0.3));
      expect(risco, lessThan(0.5));
    });
    
    test('Gera alerta apropriado', () {
      final alertaAlto = service.gerarAlerta(0.8);
      expect(alertaAlto, contains('ALTO RISCO'));
      
      final alertaBaixo = service.gerarAlerta(0.1);
      expect(alertaBaixo, contains('BAIXO'));
    });
  });
}
```

---

## 8. DEPLOY E PUBLICAÇÃO

### 🚀 Semana 8: Publicação Final

#### Passo 8.1: Checklist Final

```bash
# 1. Validar todos os JSONs
python scripts/validar_json_v3.py

# 2. Executar testes
flutter test

# 3. Gerar documentação
dart doc

# 4. Criar release notes
cat > CHANGELOG_v3.0.md << EOF
# FortSmart IA JSON v3.0

## Novidades
- 10 novos campos de dados para IA
- Sistema de alertas climáticos
- Economia agronômica integrada
- Rotação de resistência IRAC
- Distribuição geográfica

## Compatibilidade
- Compatível com v2.0 (campos antigos mantidos)
- Migração automática de dados existentes
EOF

# 5. Tag de versão
git tag -a v3.0.0 -m "FortSmart IA JSON v3.0 - Sistema inteligente de organismos"
git push origin v3.0.0
```

---

## 📊 RESUMO DO CRONOGRAMA

| Semana | Tarefa | Status |
|--------|--------|--------|
| 1 | Diagnóstico v2.0 | ⬜ |
| 2-3 | Schema v3.0 + Migração | ⬜ |
| 4 | Enriquecimento dados | ⬜ |
| 5 | Código Dart v3.0 | ⬜ |
| 6 | Integração IA | ⬜ |
| 7 | Testes | ⬜ |
| 8 | Deploy | ⬜ |

---

**Pronto para começar a implementação!** 🎯

