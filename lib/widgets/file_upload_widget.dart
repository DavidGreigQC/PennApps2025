import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File picker
            InkWell(
              onTap: _pickFiles,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_upload, size: 48),
                    SizedBox(height: 8),
                    Text('Tap to upload menu files'),
                    SizedBox(height: 4),
                    Text('PDF, PNG, JPG supported'),
                  ],
                ),
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
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add),
                    label: const Text('Add More Files'),
                  ),
                  const SizedBox(width: 8),
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
}
