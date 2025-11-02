import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/media_helper.dart';
import '../utils/snackbar_helper.dart';

/// Widget para exibir e gerenciar imagens e áudios associados a um ponto de monitoramento
class MonitoringMediaGrid extends StatefulWidget {
  final List<String> imagePaths;
  final List<String> audioPaths;
  final Function(String) onImageAdded;
  final Function(String) onImageRemoved;
  final Function(String) onAudioAdded;
  final Function(String) onAudioRemoved;
  final bool isEditable;

  const MonitoringMediaGrid({
    Key? key,
    required this.imagePaths,
    required this.audioPaths,
    required this.onImageAdded,
    required this.onImageRemoved,
    required this.onAudioAdded,
    required this.onAudioRemoved,
    this.isEditable = true,
  }) : super(key: key);

  @override
  State<MonitoringMediaGrid> createState() => _MonitoringMediaGridState();
}

class _MonitoringMediaGridState extends State<MonitoringMediaGrid> {
  bool _isRecording = false;
  String? _currentRecordingPath;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção de imagens
        _buildSectionHeader('Imagens', Icons.image),
        const SizedBox(height: 8),
        _buildImageGrid(),
        const SizedBox(height: 16),
        
        // Seção de áudios
        _buildSectionHeader('Áudios', Icons.mic),
        const SizedBox(height: 8),
        _buildAudioList(),
      ],
    );
  }

  // Constrói o cabeçalho da seção
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (widget.isEditable)
          IconButton(
            icon: Icon(
              title == 'Imagens' ? Icons.add_a_photo : Icons.mic,
              size: 20,
              color: title == 'Áudios' && _isRecording ? Colors.red : Colors.grey.shade700,
            ),
            onPressed: () {
              if (title == 'Imagens') {
                _addImage();
              } else {
                _toggleAudioRecording();
              }
            },
            tooltip: title == 'Imagens' 
                ? 'Adicionar imagem' 
                : (_isRecording ? 'Parar gravação' : 'Iniciar gravação'),
          ),
      ],
    );
  }

  // Constrói a grade de imagens
  Widget _buildImageGrid() {
    if (widget.imagePaths.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Nenhuma imagem adicionada',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.imagePaths.length,
      itemBuilder: (context, index) {
        final imagePath = widget.imagePaths[index];
        return _buildImageItem(imagePath, index);
      },
    );
  }

  // Constrói um item de imagem
  Widget _buildImageItem(String imagePath, int index) {
    return GestureDetector(
      onTap: () => _openImageGallery(index),
      child: Stack(
        children: [
          // Imagem
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame != null) {
                  print('✅ Imagem carregada com sucesso: $imagePath');
                  return child;
                }
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('❌ Erro ao carregar imagem: $imagePath - $error');
                return Container(
                  color: Colors.red.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Erro',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Botão de exclusão
          if (widget.isEditable)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _removeImage(imagePath),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Constrói a lista de áudios
  Widget _buildAudioList() {
    if (widget.audioPaths.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Nenhum áudio adicionado',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.audioPaths.length,
      itemBuilder: (context, index) {
        final audioPath = widget.audioPaths[index];
        return _buildAudioItem(audioPath);
      },
    );
  }

  // Constrói um item de áudio
  Widget _buildAudioItem(String audioPath) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.audiotrack),
        title: Text('Áudio ${_getAudioFileName(audioPath)}'),
        subtitle: FutureBuilder<String>(
          future: MediaHelper.getFileSize(audioPath),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!);
            }
            return const Text('Calculando tamanho...');
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playAudio(audioPath),
              tooltip: 'Reproduzir',
            ),
            if (widget.isEditable)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeAudio(audioPath),
                tooltip: 'Excluir',
              ),
          ],
        ),
      ),
    );
  }

  // Adiciona uma nova imagem
  Future<void> _addImage() async {
    final imagePath = await MediaHelper.showImageSourceDialog(context);
    if (imagePath != null) {
      widget.onImageAdded(imagePath);
      if (context.mounted) {
        SnackbarHelper.showSuccess(
          context, 
          'Imagem adicionada com sucesso',
        );
      }
    }
  }

  // Remove uma imagem
  void _removeImage(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir esta imagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onImageRemoved(imagePath);
              MediaHelper.deleteMediaFile(imagePath);
              SnackbarHelper.showInfo(
                context, 
                'Imagem removida',
              );
            },
            child: const Text('Excluir'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Inicia ou para a gravação de áudio
  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      // Parar gravação
      final audioPath = await MediaHelper.stopAudioRecording();
      setState(() {
        _isRecording = false;
        _currentRecordingPath = null;
      });
      
      if (audioPath != null) {
        widget.onAudioAdded(audioPath);
        if (context.mounted) {
          SnackbarHelper.showSuccess(
            context, 
            'Áudio gravado com sucesso',
          );
        }
      }
    } else {
      // Iniciar gravação
      final success = await MediaHelper.startAudioRecording(context);
      setState(() {
        _isRecording = success;
      });
      
      if (success && context.mounted) {
        SnackbarHelper.showInfo(
          context, 
          'Gravação iniciada. Toque novamente para finalizar.',
        );
      }
    }
  }

  // Remove um áudio
  void _removeAudio(String audioPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir este áudio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onAudioRemoved(audioPath);
              MediaHelper.deleteMediaFile(audioPath);
              SnackbarHelper.showInfo(
                context, 
                'Áudio removido',
              );
            },
            child: const Text('Excluir'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Reproduz um áudio
  void _playAudio(String audioPath) {
    // Implementar a reprodução de áudio
    // Pode ser feito com pacotes como audioplayers ou just_audio
    SnackbarHelper.showInfo(
      context, 
      'Reprodução de áudio será implementada em breve',
    );
  }

  // Abre a galeria de imagens
  void _openImageGallery(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageGalleryView(
          imagePaths: widget.imagePaths,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // Obtém o nome do arquivo de áudio
  String _getAudioFileName(String audioPath) {
    final fileName = audioPath.split('/').last;
    return fileName.split('.').first.substring(0, 8);
  }
}

/// Widget para visualização de galeria de imagens
class _ImageGalleryView extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const _ImageGalleryView({
    Key? key,
    required this.imagePaths,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<_ImageGalleryView> createState() => _ImageGalleryViewState();
}

class _ImageGalleryViewState extends State<_ImageGalleryView> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black, // backgroundColor não é suportado em flutter_map 5.0.0
      appBar: AppBar(
        // backgroundColor: Colors.black, // backgroundColor não é suportado em flutter_map 5.0.0
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Imagem ${_currentIndex + 1} de ${widget.imagePaths.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Visualizador de imagens com PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              try {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.file(
                      File(widget.imagePaths[index]),
                      fit: BoxFit.contain,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (frame != null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 48, color: Colors.red),
                              SizedBox(height: 8),
                              Text('Erro ao carregar imagem'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              } catch (e) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 8),
                      Text('Erro ao carregar visualizador'),
                    ],
                  ),
                );
              }
            },
          ),
          
          // Indicador de página
          if (widget.imagePaths.length > 1)
            Positioned(
              bottom: 20.0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  widget.imagePaths.length,
                  (index) => GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
          // Botões de navegação
          if (widget.imagePaths.length > 1)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: _currentIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ),
          if (widget.imagePaths.length > 1)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onPressed: _currentIndex < widget.imagePaths.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
