import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FileUploadWidget extends StatefulWidget {
  final Function(List<String>) onFilesSelected;

  const FileUploadWidget({
    super.key,
    required this.onFilesSelected,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  List<String> _selectedFilesAndUrls = [];
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Options Header
            Text(
              'Choose Upload Method:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Four upload option buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: _buildUploadOption(
                      icon: Icons.camera_alt,
                      title: 'Camera',
                      subtitle: 'Take Photo',
                      onTap: _takePhoto,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 110,
                    child: _buildUploadOption(
                      icon: Icons.photo_library,
                      title: 'Photos',
                      subtitle: 'Gallery',
                      onTap: _pickFromGallery,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 110,
                    child: _buildUploadOption(
                      icon: Icons.upload_file,
                      title: 'Files',
                      subtitle: 'PDF/Image',
                      onTap: _pickFiles,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // URL input
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Or enter menu URL',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addUrl,
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // List of selected files/URLs
            if (_selectedFilesAndUrls.isNotEmpty) ...[
              Text(
                'Selected Files / URLs:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._selectedFilesAndUrls.map((item) => _buildFileOrUrlItem(item)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Photos'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Files'),
                  ),
                  TextButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear All'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileOrUrlItem(String item) {
    bool isUrl = item.startsWith('http');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(isUrl ? Icons.link : Icons.insert_drive_file),
        title: Text(isUrl ? item : item.split('/').last),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _selectedFilesAndUrls.remove(item);
            });
            widget.onFilesSelected(_selectedFilesAndUrls);
          },
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        allowMultiple: true,
      );

      if (result != null) {
        List<String> newFiles = result.paths
            .where((path) => path != null)
            .map((path) => path!)
            .toList();

        setState(() {
          _selectedFilesAndUrls.addAll(newFiles);
          _selectedFilesAndUrls = _selectedFilesAndUrls.toSet().toList();
        });

        widget.onFilesSelected(_selectedFilesAndUrls);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty && !_selectedFilesAndUrls.contains(url)) {
      setState(() {
        _selectedFilesAndUrls.add(url);
        _urlController.clear();
      });
      widget.onFilesSelected(_selectedFilesAndUrls);
    }
  }

  void _clearAll() {
    setState(() {
      _selectedFilesAndUrls.clear();
    });
    widget.onFilesSelected(_selectedFilesAndUrls);
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        List<String> newFiles = images.map((image) => image.path).toList();

        setState(() {
          _selectedFilesAndUrls.addAll(newFiles);
          _selectedFilesAndUrls = _selectedFilesAndUrls.toSet().toList();
        });

        widget.onFilesSelected(_selectedFilesAndUrls);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedFilesAndUrls.add(photo.path);
          _selectedFilesAndUrls = _selectedFilesAndUrls.toSet().toList();
        });

        widget.onFilesSelected(_selectedFilesAndUrls);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
