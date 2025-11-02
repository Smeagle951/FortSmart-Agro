#!/usr/bin/env python3
"""
Script para expandir organism_catalog.json com thresholds fenológicos
Gera JSONs v2.0 para cada cultura com TODAS as pragas/doenças/daninhas
"""

import json
import os
from datetime import datetime

# Mapeamento de estágios fenológicos por cultura
PHENOLOGICAL_STAGES = {
    'soja': {
        'vegetative': ['V1', 'V2', 'V3', 'V4', 'V5', 'V6'],
        'reproductive': ['R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7', 'R8'],
        'critical': ['R5', 'R6']
    },
    'milho': {
        'vegetative': ['VE', 'V1', 'V3', 'V6', 'V8', 'V10', 'VT'],
        'reproductive': ['R1', 'R2', 'R3', 'R4', 'R5', 'R6'],
        'critical': ['V8', 'VT', 'R1', 'R2']
    },
    'algodao': {
        'vegetative': ['V3', 'V4', 'V5'],
        'reproductive': ['B1', 'B2', 'B3', 'B4', 'F1', 'F2', 'F3', 'A1'],
        'critical': ['B1', 'F1', 'F2']
    },
    # Adicionar outras culturas conforme necessário
}

# Thresholds padrão por tipo de organismo e estágio
def generate_phenological_thresholds(organism_type, base_thresholds, critical_stages):
    """Gera thresholds fenológicos baseados no tipo de organismo"""
    
    thresholds = {}
    
    # Para pragas de grão (percevejos, torrãozinho, etc)
    if 'percevejo' in organism_type.lower() or 'torr' in organism_type.lower():
        thresholds = {
            'V1-V3': {'low': base_thresholds['low'] * 2, 'medium': base_thresholds['medium'] * 2, 'high': base_thresholds['high'] * 2},
            'V4-V6': {'low': base_thresholds['low'] * 1.5, 'medium': base_thresholds['medium'] * 1.5, 'high': base_thresholds['high'] * 1.5},
            'R1-R2': {'low': base_thresholds['low'], 'medium': base_thresholds['medium'], 'high': base_thresholds['high']},
            'R3-R4': {'low': base_thresholds['low'] * 0.7, 'medium': base_thresholds['medium'] * 0.7, 'high': base_thresholds['high'] * 0.7},
            'R5-R6': {'low': 0, 'medium': base_thresholds['low'], 'high': base_thresholds['medium'], 'critical': base_thresholds['high']},
            'R7-R8': {'low': base_thresholds['low'], 'medium': base_thresholds['medium'], 'high': base_thresholds['high']},
        }
    
    # Para lagartas desfolhadoras
    elif 'lagarta' in organism_type.lower():
        thresholds = {
            'V1-V3': {'low': base_thresholds['low'] * 0.5, 'medium': base_thresholds['medium'] * 0.5, 'high': base_thresholds['high'] * 0.5, 'critical': base_thresholds['high']},
            'V4-V6': {'low': base_thresholds['low'], 'medium': base_thresholds['medium'], 'high': base_thresholds['high']},
            'R1-R4': {'low': base_thresholds['low'] * 1.2, 'medium': base_thresholds['medium'] * 1.2, 'high': base_thresholds['high'] * 1.2},
            'R5-R8': {'low': base_thresholds['low'] * 2, 'medium': base_thresholds['medium'] * 2, 'high': base_thresholds['high'] * 2},
        }
    
    # Para doenças
    elif organism_type == 'disease':
        thresholds = {
            'V1-V3': {'low': base_thresholds['low'], 'medium': base_thresholds['medium'], 'high': base_thresholds['high']},
            'V4-V6': {'low': base_thresholds['low'] * 0.8, 'medium': base_thresholds['medium'] * 0.8, 'high': base_thresholds['high'] * 0.8},
            'R1-R4': {'low': base_thresholds['low'] * 0.7, 'medium': base_thresholds['medium'] * 0.7, 'high': base_thresholds['high'] * 0.7},
            'R5-R8': {'low': base_thresholds['low'], 'medium': base_thresholds['medium'], 'high': base_thresholds['high']},
        }
    
    return thresholds

def expand_organism_catalog():
    """Expande organism_catalog.json com thresholds fenológicos"""
    
    # Carregar JSON original
    with open('../assets/data/organism_catalog.json', 'r', encoding='utf-8') as f:
        original_catalog = json.load(f)
    
    cultures = original_catalog['cultures']
    
    for culture_key, culture_data in cultures.items():
        print(f"\n🔄 Processando {culture_key}...")
        
        expanded_culture = {
            'version': '2.0',
            'last_updated': datetime.now().isoformat(),
            'culture': culture_key,
            'culture_id': f'custom_{culture_key}',
            'organisms': {
                'pests': [],
                'diseases': [],
                'weeds': []
            }
        }
        
        organisms = culture_data.get('organisms', {})
        
        # Processar pragas
        pests = organisms.get('pests', [])
        for pest in pests:
            expanded_pest = pest.copy()
            base_thresholds = {
                'low': pest.get('low_limit', 2),
                'medium': pest.get('medium_limit', 4),
                'high': pest.get('high_limit', 6),
            }
            expanded_pest['phenological_thresholds'] = generate_phenological_thresholds(
                pest['name'], base_thresholds, []
            )
            expanded_culture['organisms']['pests'].append(expanded_pest)
        
        # Processar doenças
        diseases = organisms.get('diseases', [])
        for disease in diseases:
            expanded_disease = disease.copy()
            base_thresholds = {
                'low': disease.get('low_limit', 3),
                'medium': disease.get('medium_limit', 10),
                'high': disease.get('high_limit', 15),
            }
            expanded_disease['phenological_thresholds'] = generate_phenological_thresholds(
                'disease', base_thresholds, []
            )
            expanded_culture['organisms']['diseases'].append(expanded_disease)
        
        # Processar plantas daninhas
        weeds = organisms.get('weeds', [])
        for weed in weeds:
            expanded_weed = weed.copy()
            expanded_culture['organisms']['weeds'].append(expanded_weed)
        
        # Salvar arquivo expandido
        output_file = f'../assets/data/organism_catalog_{culture_key}_completo_v2.json'
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(expanded_culture, f, indent=2, ensure_ascii=False)
        
        total = len(pests) + len(diseases) + len(weeds)
        print(f"✅ {culture_key}: {len(pests)} pragas + {len(diseases)} doenças + {len(weeds)} daninhas = {total} organismos")

if __name__ == '__main__':
    print("🚀 Expandindo organism_catalog.json com thresholds fenológicos...")
    expand_organism_catalog()
    print("\n✅ Expansão concluída!")

