// Imports necessários para a funcionalidade de gravação de áudio
import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fortsmart_agro/utils/wrappers/wrappers.dart';

/// Classe auxiliar para gerenciar a gravação e reprodução de áudio
/// Esta classe foi adaptada para usar o pacote audioplayers em vez de record
class AudioRecorderHelper {
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  StreamSubscription? _playerStateSubscription;
  bool _isPlaying = false;
  
  /// Inicializa o gravador
  Future<void> initialize() async {
    // Configura o listener para o estado do player
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }
  
  /// Verifica se tem permissão para gravar
  Future<bool> hasPermission() async {
    // Usando nosso wrapper de permissões personalizado
    return await PermissionHandlerWrapper.requestCameraPermission();
  }
  
  /// Gera um caminho para o arquivo de áudio
  Future<String> _generateAudioPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/audio_$timestamp.aac';
  }
  
  /// Inicia a gravação (simulação, pois não estamos usando o pacote record)
  Future<void> startRecording([String? filePath]) async {
    if (_isRecording) return;
    
    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      throw Exception('Permissão para gravar áudio negada');
    }
    
    try {
      _currentRecordingPath = filePath ?? await _generateAudioPath();
      _isRecording = true;
      
      // Simula o início da gravação
      // Em uma implementação real, usaria o pacote record
      print('Iniciando gravação em: $_currentRecordingPath');
      
      // Cria um arquivo vazio para simular a gravação
      final file = File(_currentRecordingPath!);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
    } catch (e) {
      _isRecording = false;
      throw Exception('Erro ao iniciar gravação: $e');
    }
  }
  
  /// Para a gravação
  Future<String> stopRecording() async {
    if (!_isRecording || _currentRecordingPath == null) {
      return '';
    }
    
    try {
      _isRecording = false;
      print('Gravação finalizada: $_currentRecordingPath');
      return _currentRecordingPath!;
    } catch (e) {
      throw Exception('Erro ao parar gravação: $e');
    }
  }
  
  /// Reproduz um áudio
  Future<void> playAudio(String filePath) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    }
    
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      throw Exception('Erro ao reproduzir áudio: $e');
    }
  }
  
  /// Para a reprodução
  Future<void> stopPlaying() async {
    await _audioPlayer.stop();
  }
  
  /// Verifica se está gravando
  bool get isRecording => _isRecording;
  
  /// Verifica se está reproduzindo
  bool get isPlaying => _isPlaying;
  
  /// Libera os recursos
  void dispose() {
    _recordingTimer?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
  }
}

