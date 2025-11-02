import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../models/penetrometro_reading_model.dart';
import '../services/penetrometro_bluetooth_service.dart';
import '../repositories/penetrometro_reading_repository.dart';

/// Exemplo de uso do sistema de penetrômetro Bluetooth
class PenetrometroBluetoothExample {
  
  /// Exemplo básico de conexão e coleta
  static Future<void> exemploBasico() async {
    print('=== EXEMPLO BÁSICO DE PENETRÔMETRO BLUETOOTH ===');
    
    // UUIDs do seu penetrômetro (substitua pelos reais)
    const serviceUuid = '0000180A-0000-1000-8000-00805F9B34FB';
    const charUuid = '00002A37-0000-1000-8000-00805F9B34FB';
    
    // Cria serviço Bluetooth
    final bluetoothService = PenetrometroBluetoothService(
      serviceUuid: Uuid.parse(serviceUuid),
      charUuid: Uuid.parse(charUuid),
    );
    
    // Cria repositório
    final repository = PenetrometroReadingRepository();
    await repository.init();
    
    try {
      // 1. Verifica permissões
      print('1. Verificando permissões...');
      final hasPermissions = await bluetoothService.checkPermissions();
      if (!hasPermissions) {
        print('❌ Permissões não concedidas');
        return;
      }
      print('✅ Permissões OK');
      
      // 2. Escaneia dispositivos
      print('2. Escaneando dispositivos...');
      final devices = <DiscoveredDevice>[];
      await for (final device in bluetoothService.scanForDevices(
        nameFilter: 'Penetrômetro',
        timeout: const Duration(seconds: 10),
      )) {
        devices.add(device);
        print('   📱 Encontrado: ${device.name} (${device.id})');
      }
      
      if (devices.isEmpty) {
        print('❌ Nenhum dispositivo encontrado');
        return;
      }
      
      // 3. Conecta ao primeiro dispositivo
      print('3. Conectando ao dispositivo...');
      final device = devices.first;
      final connected = await bluetoothService.connectToDevice(device.id);
      
      if (!connected) {
        print('❌ Falha na conexão');
        return;
      }
      print('✅ Conectado com sucesso');
      
      // 4. Escuta leituras
      print('4. Coletando leituras...');
      final readings = <PenetrometroReading>[];
      
      final subscription = bluetoothService.readings.listen((reading) {
        readings.add(reading);
        print('   📊 Leitura: ${reading.resumoFormatado}');
        
        // Salva automaticamente
        repository.insertReading(reading);
      });
      
      // Coleta por 30 segundos
      await Future.delayed(const Duration(seconds: 30));
      
      // 5. Para coleta
      subscription.cancel();
      await bluetoothService.disconnect();
      
      print('✅ Coleta finalizada: ${readings.length} leituras');
      
    } catch (e) {
      print('❌ Erro: $e');
    } finally {
      bluetoothService.dispose();
    }
  }

  /// Exemplo de configuração de UUIDs específicos
  static void exemploConfiguracaoUUIDs() {
    print('\n=== CONFIGURAÇÃO DE UUIDs ===');
    
    // Exemplos de UUIDs comuns para penetrômetros
    final exemplosUUIDs = {
      'Penetrômetro Genérico': {
        'service': '0000180A-0000-1000-8000-00805F9B34FB', // Device Information
        'characteristic': '00002A37-0000-1000-8000-00805F9B34FB', // Heart Rate
      },
      'Penetrômetro Customizado': {
        'service': '12345678-1234-1234-1234-123456789ABC',
        'characteristic': '87654321-4321-4321-4321-CBA987654321',
      },
      'Penetrômetro Agrícola': {
        'service': 'FEDCBA98-7654-3210-FEDC-BA9876543210',
        'characteristic': '01234567-89AB-CDEF-0123-456789ABCDEF',
      },
    };
    
    for (final entry in exemplosUUIDs.entries) {
      print('${entry.key}:');
      print('  Service UUID: ${entry.value['service']}');
      print('  Characteristic UUID: ${entry.value['characteristic']}');
      print('');
    }
    
    print('💡 Para descobrir os UUIDs do seu penetrômetro:');
    print('   1. Use o app nRF Connect');
    print('   2. Conecte ao dispositivo');
    print('   3. Navegue pelos serviços');
    print('   4. Encontre o serviço que envia dados');
    print('   5. Anote o UUID do serviço e característica');
  }

  /// Exemplo de parsing de dados
  static void exemploParsingDados() {
    print('\n=== PARSING DE DADOS ===');
    
    // Exemplo 1: Dados em formato ASCII
    print('1. Formato ASCII (ex: "DEP:12.3;MPA:2.45"):');
    final dadosAscii = 'DEP:12.3;MPA:2.45';
    final parts = dadosAscii.split(';');
    double profundidade = 0;
    double resistencia = 0;
    
    for (final part in parts) {
      if (part.startsWith('DEP:')) {
        profundidade = double.tryParse(part.substring(4)) ?? 0;
      } else if (part.startsWith('MPA:')) {
        resistencia = double.tryParse(part.substring(4)) ?? 0;
      }
    }
    
    print('   Profundidade: ${profundidade}cm');
    print('   Resistência: ${resistencia}MPa');
    
    // Exemplo 2: Dados em formato binário
    print('\n2. Formato binário (8 bytes: 4 para profundidade + 4 para resistência):');
    final dadosBinarios = [0x41, 0x44, 0x80, 0x00, 0x40, 0x1C, 0x00, 0x00]; // Exemplo
    final byteData = ByteData.sublistView(Uint8List.fromList(dadosBinarios));
    
    final profundidadeBin = byteData.getFloat32(0, Endian.little);
    final resistenciaBin = byteData.getFloat32(4, Endian.little);
    
    print('   Profundidade: ${profundidadeBin}cm');
    print('   Resistência: ${resistenciaBin}MPa');
    
    // Exemplo 3: Dados em formato JSON
    print('\n3. Formato JSON (ex: \'{"depth":12.3,"pressure":2.45}\'):');
    final dadosJson = '{"depth":12.3,"pressure":2.45}';
    try {
      final json = jsonDecode(dadosJson);
      final profundidadeJson = json['depth']?.toDouble() ?? 0.0;
      final resistenciaJson = json['pressure']?.toDouble() ?? 0.0;
      
      print('   Profundidade: ${profundidadeJson}cm');
      print('   Resistência: ${resistenciaJson}MPa');
    } catch (e) {
      print('   Erro no parse JSON: $e');
    }
  }

  /// Exemplo de tratamento de erros
  static Future<void> exemploTratamentoErros() async {
    print('\n=== TRATAMENTO DE ERROS ===');
    
    final bluetoothService = PenetrometroBluetoothService(
      serviceUuid: Uuid.parse('0000180A-0000-1000-8000-00805F9B34FB'),
      charUuid: Uuid.parse('00002A37-0000-1000-8000-00805F9B34FB'),
    );
    
    try {
      // 1. Verifica status do Bluetooth
      print('1. Verificando status do Bluetooth...');
      final status = bluetoothService.status;
      print('   Status: $status');
      
      if (status != BleStatus.ready) {
        print('❌ Bluetooth não está pronto');
        return;
      }
      
      // 2. Verifica permissões
      print('2. Verificando permissões...');
      final hasPermissions = await bluetoothService.checkPermissions();
      if (!hasPermissions) {
        print('❌ Permissões necessárias não concedidas');
        return;
      }
      
      // 3. Tenta conectar com timeout
      print('3. Tentando conectar com timeout...');
      final connected = await bluetoothService.connectToDevice('device_id')
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏰ Timeout na conexão');
              return false;
            },
          );
      
      if (!connected) {
        print('❌ Falha na conexão');
        return;
      }
      
      print('✅ Conectado com sucesso');
      
    } catch (e) {
      print('❌ Erro capturado: $e');
      
      // Tratamento específico por tipo de erro
      if (e.toString().contains('permission')) {
        print('💡 Solução: Verificar permissões no app');
      } else if (e.toString().contains('bluetooth')) {
        print('💡 Solução: Verificar se Bluetooth está ligado');
      } else if (e.toString().contains('timeout')) {
        print('💡 Solução: Verificar se dispositivo está próximo');
      } else {
        print('💡 Solução: Verificar logs para mais detalhes');
      }
    } finally {
      bluetoothService.dispose();
    }
  }

  /// Exemplo de persistência de dados
  static Future<void> exemploPersistencia() async {
    print('\n=== PERSISTÊNCIA DE DADOS ===');
    
    final repository = PenetrometroReadingRepository();
    await repository.init();
    
    try {
      // 1. Cria leituras de exemplo
      print('1. Criando leituras de exemplo...');
      final leituras = List.generate(10, (index) {
        return PenetrometroReading.fromBluetooth(
          profundidadeCm: 10.0 + (index * 2.0),
          resistenciaMpa: 1.0 + (index * 0.2),
          deviceId: 'PENETROMETRO_001',
          latitude: -23.5505 + (index * 0.001),
          longitude: -46.6333 + (index * 0.001),
          pointCode: 'C-${(index + 1).toString().padLeft(3, '0')}',
          talhaoId: 1,
          observacoes: 'Leitura ${index + 1}',
        );
      });
      
      // 2. Salva no banco
      print('2. Salvando no banco de dados...');
      await repository.insertReadingsBatch(leituras);
      print('✅ ${leituras.length} leituras salvas');
      
      // 3. Busca leituras
      print('3. Buscando leituras...');
      final todasLeituras = await repository.getAllReadings();
      print('   Total: ${todasLeituras.length} leituras');
      
      // 4. Busca por talhão
      final leiturasTalhao = await repository.getReadingsByTalhao(1);
      print('   Talhão 1: ${leiturasTalhao.length} leituras');
      
      // 5. Busca não sincronizadas
      final naoSincronizadas = await repository.getUnsyncedReadings();
      print('   Não sincronizadas: ${naoSincronizadas.length} leituras');
      
      // 6. Estatísticas
      final stats = await repository.getStatistics();
      print('4. Estatísticas:');
      print('   Total: ${stats['total_readings']} leituras');
      print('   Média resistência: ${stats['avg_resistencia']?.toStringAsFixed(2)} MPa');
      print('   Média profundidade: ${stats['avg_profundidade']?.toStringAsFixed(2)} cm');
      print('   Primeira leitura: ${stats['first_reading']}');
      print('   Última leitura: ${stats['last_reading']}');
      
    } catch (e) {
      print('❌ Erro na persistência: $e');
    } finally {
      await repository.close();
    }
  }

  /// Exemplo de sincronização
  static Future<void> exemploSincronizacao() async {
    print('\n=== SINCRONIZAÇÃO ===');
    
    final repository = PenetrometroReadingRepository();
    await repository.init();
    
    try {
      // 1. Busca leituras não sincronizadas
      print('1. Buscando leituras não sincronizadas...');
      final naoSincronizadas = await repository.getUnsyncedReadings();
      print('   Encontradas: ${naoSincronizadas.length} leituras');
      
      if (naoSincronizadas.isEmpty) {
        print('✅ Nenhuma leitura para sincronizar');
        return;
      }
      
      // 2. Simula envio para servidor
      print('2. Enviando para servidor...');
      for (final leitura in naoSincronizadas) {
        // Aqui você faria a chamada HTTP para o servidor
        print('   📤 Enviando: ${leitura.resumoFormatado}');
        
        // Simula delay de rede
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Marca como sincronizada
        await repository.markAsSynced(leitura.id!);
        print('   ✅ Sincronizada');
      }
      
      print('✅ Sincronização concluída');
      
    } catch (e) {
      print('❌ Erro na sincronização: $e');
    } finally {
      await repository.close();
    }
  }

  /// Executa todos os exemplos
  static Future<void> executarTodosExemplos() async {
    print('📡 EXEMPLOS DE PENETRÔMETRO BLUETOOTH - FORTSMART AGRO\n');
    
    exemploConfiguracaoUUIDs();
    exemploParsingDados();
    
    await exemploTratamentoErros();
    await exemploPersistencia();
    await exemploSincronizacao();
    
    print('\n' + '='*50 + '\n');
    
    // Exemplo básico por último (pode demorar)
    print('⚠️  Executando exemplo básico (pode demorar)...');
    await exemploBasico();
    
    print('\n✅ Todos os exemplos executados com sucesso!');
  }
}
