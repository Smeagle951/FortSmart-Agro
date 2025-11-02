import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Widget otimizado para upload de imagens com indicador de progresso
/// e compressão para evitar problemas de memória e tela branca
class OptimizedImageUpload extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<String>) onImagesChanged;
  final int maxImages;
  final bool enabled;
  final String title;
  final int imageQuality;
  final int maxWidth;
  final int maxHeight;

  const OptimizedImageUpload({
    Key? key,
    this.initialImages = const [],
    required this.onImagesChanged,
    this.maxImages = 5,
    this.enabled = true,
    this.title = 'Fotos',
    this.imageQuality = 80,
    this.maxWidth = 1200,
    this.maxHeight = 1200,
  }) : super(key: key);

  @override
  State<OptimizedImageUpload> createState() => _OptimizedImageUploadState();
}

class _OptimizedImageUploadState extends State<OptimizedImageUpload> {
  final ImagePicker _picker = ImagePicker();
  List<ImageItem> _images = [];
  bool _isLoading = false;
  Map<int, double> _uploadProgress = {};

  @override
  void initState() {
    super.initState();
    _loadInitialImages();
  }

  @override
  void didUpdateWidget(OptimizedImageUpload oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImages != widget.initialImages) {
      _loadInitialImages();
    }
  }

  Future<void> _loadInitialImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _images = [];
      for (final imageStr in widget.initialImages) {
        // Verificar se é uma URL, um caminho local ou uma string base64
        if (imageStr.startsWith('http')) {
          // URL remota
          _images.add(ImageItem(
            source: ImageItemSource.network,
            path: imageStr,
            data: imageStr,
          ));
        } else if (imageStr.startsWith('data:image')) {
          // String base64
          _images.add(ImageItem(
            source: ImageItemSource.base64,
            path: 'Imagem Base64',
            data: imageStr,
          ));
        } else {
          // Caminho local
          _images.add(ImageItem(
            source: ImageItemSource.local,
            path: imageStr,
            data: imageStr,
          ));
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar imagens iniciais: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (_images.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo de ${widget.maxImages} imagens permitidas')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar imagem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo de ${widget.maxImages} imagens permitidas')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: widget.maxWidth.toDouble(),
        maxHeight: widget.maxHeight.toDouble(),
        imageQuality: widget.imageQuality,
      );

      if (pickedFile != null) {
        // Adicionar um índice temporário para acompanhar o progresso
        final tempIndex = _images.length;
        setState(() {
          _uploadProgress[tempIndex] = 0.0;
        });

        // Comprimir a imagem em segundo plano
        final compressedFile = await _compressImage(File(pickedFile.path));
        
        // Converter imagem para base64 (opcional, dependendo de como você armazena)
        final bytes = await compressedFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        setState(() {
          _images.add(ImageItem(
            source: ImageItemSource.file,
            path: compressedFile.path,
            data: base64Image,
            file: compressedFile,
          ));
          
          // Remover o progresso após concluir
          _uploadProgress.remove(tempIndex);
        });
        
        _notifyImagesChanged();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<File> _compressImage(File file) async {
    // Criar um diretório temporário para armazenar a imagem comprimida
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    // Atualizar o progresso para simular o início da compressão
    final tempIndex = _images.length;
    setState(() {
      _uploadProgress[tempIndex] = 0.2;
    });

    // Comprimir a imagem
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: widget.imageQuality,
      minWidth: 1024,
      minHeight: 1024,
    );
    
    // Atualizar o progresso para indicar que a compressão está quase concluída
    setState(() {
      _uploadProgress[tempIndex] = 0.8;
    });
    
    if (result == null) {
      throw Exception('Falha ao comprimir a imagem');
    }
    
    // Atualizar o progresso para indicar conclusão
    setState(() {
      _uploadProgress[tempIndex] = 1.0;
    });
    
    return File(result.path);
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    _notifyImagesChanged();
  }

  void _notifyImagesChanged() {
    // Extrair apenas os dados das imagens para o callback
    final List<String> imageData = _images.map((img) => img.data).toList();
    widget.onImagesChanged(imageData);
  }

  Future<void> _viewFullImage(ImageItem image) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Visualizar Imagem'),
            // backgroundColor: Colors.black, // backgroundColor não é suportado em flutter_map 5.0.0
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: _buildFullImageWidget(image),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullImageWidget(ImageItem image) {
    switch (image.source) {
      case ImageItemSource.file:
      case ImageItemSource.local:
        return Image.file(
          File(image.path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.error, color: Colors.red, size: 50));
          },
        );
      case ImageItemSource.network:
        return Image.network(
          image.path,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.error, color: Colors.red, size: 50));
          },
        );
      case ImageItemSource.base64:
        final dataUri = Uri.parse(image.data);
        final bytes = base64.decode(dataUri.data!.contentAsString().split(',').last);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.error, color: Colors.red, size: 50));
          },
        );
      default:
        return const Center(child: Icon(Icons.error, color: Colors.red, size: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        
        // Grid de imagens + botão de adicionar
        if (_isLoading && _images.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              // Itens de imagem
              ..._images.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return _buildImageItem(image, index);
              }),
              
              // Itens em progresso de upload
              ..._uploadProgress.entries.map((entry) {
                return _buildProgressItem(entry.value);
              }),
              
              // Botão de adicionar (se habilitado e não atingiu o máximo)
              if (widget.enabled && _images.length < widget.maxImages)
                _buildAddButton(),
            ],
          ),
      ],
    );
  }

  Widget _buildProgressItem(double progress) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            Text('${(progress * 100).toInt()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(ImageItem image, int index) {
    return Stack(
      children: [
        // Imagem
        GestureDetector(
          onTap: () => _viewFullImage(image),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(image),
            ),
          ),
        ),
        
        // Botão de remover
        if (widget.enabled)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageWidget(ImageItem image) {
    switch (image.source) {
      case ImageItemSource.file:
      case ImageItemSource.local:
        return Image.file(
          File(image.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.error, color: Colors.red));
          },
        );
      case ImageItemSource.network:
        return Image.network(
          image.path,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.error, color: Colors.red));
          },
        );
      case ImageItemSource.base64:
        try {
          final dataUri = Uri.parse(image.data);
          final bytes = base64.decode(dataUri.data!.contentAsString().split(',').last);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error, color: Colors.red));
            },
          );
        } catch (e) {
          return const Center(child: Icon(Icons.error, color: Colors.red));
        }
      default:
        return const Center(child: Icon(Icons.error, color: Colors.red));
    }
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: widget.enabled ? _showImageSourceDialog : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.add_photo_alternate,
            size: 40,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// Tipos de fontes de imagem
enum ImageItemSource {
  camera,
  gallery,
  file,
  network,
  base64,
  local,
}

/// Classe auxiliar para representar uma imagem
class ImageItem {
  final ImageItemSource source;
  final String path;
  final String data;
  final File? file;

  ImageItem({
    required this.source,
    required this.path,
    required this.data,
    this.file,
  });
}
