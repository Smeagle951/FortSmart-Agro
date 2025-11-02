import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget para upload e exibição de imagens, com suporte para múltiplas imagens
class ImageUploadSection extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<String>) onImagesChanged;
  final int maxImages;
  final bool enabled;
  final String title;

  const ImageUploadSection({
    Key? key,
    this.initialImages = const [],
    required this.onImagesChanged,
    this.maxImages = 5,
    this.enabled = true,
    this.title = 'Fotos',
  }) : super(key: key);

  @override
  State<ImageUploadSection> createState() => _ImageUploadSectionState();
}

class _ImageUploadSectionState extends State<ImageUploadSection> {
  final ImagePicker _picker = ImagePicker();
  List<ImageItem> _images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialImages();
  }

  @override
  void didUpdateWidget(ImageUploadSection oldWidget) {
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
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Converter imagem para base64
        final bytes = await pickedFile.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        setState(() {
          _images.add(ImageItem(
            source: ImageItemSource.file,
            path: pickedFile.path,
            data: base64Image,
            file: File(pickedFile.path),
          ));
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
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
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
              
              // Botão de adicionar (se habilitado e não atingiu o máximo)
              if (widget.enabled && _images.length < widget.maxImages)
                _buildAddButton(),
            ],
          ),
      ],
    );
  }

  Widget _buildImageItem(ImageItem image, int index) {
    return Stack(
      children: [
        // Imagem
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(image),
          ),
        ),
        
        // Botão de remover (apenas se habilitado)
        if (widget.enabled)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              // onTap: () => _removeImage(index), // onTap não é suportado em Polygon no flutter_map 5.0.0
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
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
        return Image.file(
          image.file!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      case ImageItemSource.network:
        return Image.network(
          image.path,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey,
          ),
        );
      case ImageItemSource.base64:
        return Image.memory(
          base64Decode(image.data.split(',').last),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey,
          ),
        );
      case ImageItemSource.local:
        return Image.file(
          File(image.path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey,
          ),
        );
      default:
        return const Icon(
          Icons.broken_image,
          size: 40,
          color: Colors.grey,
        );
    }
  }

  Widget _buildAddButton() {
    return GestureDetector(
      // onTap: () => _showImageSourceDialog(), // onTap não é suportado em Polygon no flutter_map 5.0.0
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.add_a_photo,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar imagem de'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Tipos de fontes de imagem personalizados
enum ImageItemSource {
  camera,
  gallery,
  file,
  network,
  base64,
  local
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
