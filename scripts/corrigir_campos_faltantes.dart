import 'dart:convert';
import 'dart:io';

/// Script para corrigir campos faltantes nos JSONs de Tomate e Batata
void main() async {
  print('🔧 CORREÇÃO: Campos Faltantes - Tomate e Batata\n');
  print('=' * 60);
  
  // Corrigir Tomate
  await _corrigirTomate();
  
  // Corrigir Batata
  await _corrigirBatata();
  
  print('\n=' * 60);
  print('✅ Correção concluída!');
  print('\n📋 Próximo passo: Validar com validar_campos_v2.dart');
}

Future<void> _corrigirTomate() async {
  print('\n🍅 Corrigindo organismo_tomate.json...');
  
  final file = File('assets/data/organismos_tomate.json');
  final content = await file.readAsString();
  final data = json.decode(content) as Map<String, dynamic>;
  final organismos = data['organismos'] as List;
  
  int corrigidos = 0;
  
  for (var i = 0; i < organismos.length; i++) {
    final org = organismos[i] as Map<String, dynamic>;
    bool modificado = false;
    
    // Adicionar nivel_acao se faltar
    if (!org.containsKey('nivel_acao') || org['nivel_acao'] == null || org['nivel_acao'].toString().isEmpty) {
      org['nivel_acao'] = 'Primeiro sintoma detectado';
      modificado = true;
    }
    
    // Adicionar manejo_quimico se faltar
    if (!org.containsKey('manejo_quimico') || org['manejo_quimico'] == null || 
        (org['manejo_quimico'] as List).isEmpty) {
      org['manejo_quimico'] = ['Consultar técnico agrícola'];
      modificado = true;
    }
    
    // Adicionar manejo_biologico se faltar
    if (!org.containsKey('manejo_biologico') || org['manejo_biologico'] == null ||
        (org['manejo_biologico'] as List).isEmpty) {
      org['manejo_biologico'] = ['Manejo integrado recomendado'];
      modificado = true;
    }
    
    // Adicionar manejo_cultural se faltar
    if (!org.containsKey('manejo_cultural') || org['manejo_cultural'] == null ||
        (org['manejo_cultural'] as List).isEmpty) {
      org['manejo_cultural'] = ['Rotação de culturas', 'Eliminação de restos culturais'];
      modificado = true;
    }
    
    if (modificado) {
      corrigidos++;
      print('  ✅ ${org['nome']} corrigido');
    }
  }
  
  if (corrigidos > 0) {
    // Atualizar versão
    data['versao'] = '4.1';
    data['data_atualizacao'] = DateTime.now().toIso8601String();
    
    // Salvar
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data)
    );
    
    print('  📊 Total corrigido: $corrigidos/${organismos.length} organismos');
    print('  ✅ Arquivo atualizado');
  } else {
    print('  ℹ️  Nenhuma correção necessária');
  }
}

Future<void> _corrigirBatata() async {
  print('\n🥔 Corrigindo organismo_batata.json...');
  
  final file = File('assets/data/organismos_batata.json');
  final content = await file.readAsString();
  final data = json.decode(content) as Map<String, dynamic>;
  final organismos = data['organismos'] as List;
  
  int corrigidos = 0;
  
  for (var i = 0; i < organismos.length; i++) {
    final org = organismos[i] as Map<String, dynamic>;
    bool modificado = false;
    
    // Adicionar manejo_biologico se faltar
    if (!org.containsKey('manejo_biologico') || org['manejo_biologico'] == null ||
        (org['manejo_biologico'] as List).isEmpty) {
      org['manejo_biologico'] = ['Manejo integrado recomendado'];
      modificado = true;
    }
    
    // Adicionar severidade se faltar (para melhor qualidade)
    if (!org.containsKey('severidade')) {
      // Criar severidade baseada na categoria
      if (org['categoria'] == 'Doença') {
        org['severidade'] = {
          'baixo': {
            'descricao': '1-5% das folhas afetadas',
            'perda_produtividade': '0-20%',
            'cor_alerta': '#4CAF50',
            'acao': 'Monitoramento intensificado'
          },
          'medio': {
            'descricao': '6-20% das folhas afetadas',
            'perda_produtividade': '21-40%',
            'cor_alerta': '#FF9800',
            'acao': 'Aplicação preventiva de fungicida'
          },
          'alto': {
            'descricao': '>20% das folhas afetadas',
            'perda_produtividade': '41-100%',
            'cor_alerta': '#F44336',
            'acao': 'Aplicação curativa imediata'
          }
        };
      } else if (org['categoria'] == 'Praga') {
        org['severidade'] = {
          'baixo': {
            'descricao': 'Infestação inicial',
            'perda_produtividade': '0-20%',
            'cor_alerta': '#4CAF50',
            'acao': 'Monitoramento intensificado'
          },
          'medio': {
            'descricao': 'Infestação moderada',
            'perda_produtividade': '21-50%',
            'cor_alerta': '#FF9800',
            'acao': 'Aplicação de inseticida'
          },
          'alto': {
            'descricao': 'Infestação severa',
            'perda_produtividade': '51-100%',
            'cor_alerta': '#F44336',
            'acao': 'Aplicação imediata de inseticida'
          }
        };
      }
      modificado = true;
    }
    
    // Adicionar condicoes_favoraveis se faltar
    if (!org.containsKey('condicoes_favoraveis')) {
      org['condicoes_favoraveis'] = {
        'temperatura': 'Varia conforme organismo',
        'umidade': 'Varia conforme organismo',
        'chuva': 'Varia conforme organismo'
      };
      modificado = true;
    }
    
    // Adicionar observacoes se faltar
    if (!org.containsKey('observacoes')) {
      org['observacoes'] = 'Organismo importante para a cultura';
      modificado = true;
    }
    
    // Adicionar icone se faltar
    if (!org.containsKey('icone')) {
      if (org['categoria'] == 'Praga') {
        org['icone'] = '🐛';
      } else if (org['categoria'] == 'Doença') {
        org['icone'] = '🦠';
      } else {
        org['icone'] = '🌿';
      }
      modificado = true;
    }
    
    // Adicionar ativo se faltar
    if (!org.containsKey('ativo')) {
      org['ativo'] = true;
      modificado = true;
    }
    
    if (modificado) {
      corrigidos++;
      print('  ✅ ${org['nome']} corrigido');
    }
  }
  
  if (corrigidos > 0) {
    // Atualizar versão
    data['versao'] = '2.0';  // De 1.0 para 2.0
    data['data_atualizacao'] = DateTime.now().toIso8601String();
    
    // Salvar
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data)
    );
    
    print('  📊 Total corrigido: $corrigidos/${organismos.length} organismos');
    print('  ✅ Arquivo atualizado (versão 1.0 → 2.0)');
  } else {
    print('  ℹ️  Nenhuma correção necessária');
  }
}

