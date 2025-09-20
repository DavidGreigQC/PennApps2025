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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.upload_rounded,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Upload Menu Files',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Upload Options Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.blue[600], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Upload Methods',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _buildUploadOption(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take Photo',
                        color: Colors.green,
                        onTap: _takePhoto,
                      ),
                      const SizedBox(height: 12),
                      _buildUploadOption(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        subtitle: 'Photos',
                        color: Colors.orange,
                        onTap: _pickFromGallery,
                      ),
                      const SizedBox(height: 12),
                      _buildUploadOption(
                        icon: Icons.upload_file_rounded,
                        title: 'Files',
                        subtitle: 'PDF/Image',
                        color: Colors.purple,
                        onTap: _pickFiles,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // URL Input Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link_rounded, color: Colors.blue[600], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Menu URL',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Enter menu website URL',
                      hintText: 'https://example.com/menu',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.language_rounded, color: Colors.grey[500]),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          onPressed: _addUrl,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),

            // Selected Files Section
            if (_selectedFilesAndUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selected Files (${_selectedFilesAndUrls.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _clearAll,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.clear_rounded, color: Colors.red[600], size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Clear All',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._selectedFilesAndUrls.map((item) => _buildFileOrUrlItem(item)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileOrUrlItem(String item) {
    bool isUrl = item.startsWith('http');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isUrl ? Colors.blue[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isUrl ? Icons.link_rounded : Icons.insert_drive_file_rounded,
              color: isUrl ? Colors.blue[600] : Colors.green[600],
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrl ? 'Website URL' : 'File',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUrl ? item : item.split('/').last,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilesAndUrls.remove(item);
                });
                widget.onFilesSelected(_selectedFilesAndUrls);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red[600],
                  size: 16,
                ),
              ),
            ),
          ),
        ],
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
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            color: color[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color[200]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: color[700],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: color[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: color[600],
                ),
              ],
            ),
          ),
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
